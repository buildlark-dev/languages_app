/// Reconocimiento de habla con degradación en tres pasos.
///
/// Implementa D6 de research.md, que es la única manera de cumplir FR-016 y FR-039
/// a la vez:
///
/// 1. **En el dispositivo** (`onDevice: true`). Sin conexión, preferido.
/// 2. **Con el servicio del sistema**, si el paso 1 falla y hay red.
/// 3. **Alternativa accesible**, si no hay ninguno de los dos.
///
/// El paso 3 **no es un error**: es una ruta válida con la que la lección se
/// aprueba igual. De eso vive SC-008.
///
/// ## Dos correcciones que cambian cómo se siente usarlo
///
/// **Se escucha el canal de errores.** Antes el servicio pasaba
/// `onError: (_) {}` y esperaba a que venciera su propio reloj. Medido en el
/// navegador: `start()` informa `not-allowed` en milisegundos, y la app tardaba
/// seis segundos más dos de pausa, repetía para el paso 2, y a los dieciséis
/// segundos caía a la alternativa escrita sin mencionar el micrófono. Ahora el
/// intento termina en cuanto la plataforma dice qué pasó, y lo que dijo llega
/// hasta la pantalla.
///
/// **El paso 1 solo se intenta donde existe.** El plugin de web no lee
/// `onDevice`: allí el paso 1 y el paso 2 son la misma llamada, así que
/// intentar los dos solo duplicaba la espera antes de rendirse.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'stt_error_codes.dart';
import 'stt_service.dart';

/// Cuánto se espera a que alguien hable antes de darlo por silencio.
const Duration _listenWindow = Duration(seconds: 6);

/// Cuánto silencio basta para dar la frase por terminada.
const Duration _pauseWindow = Duration(seconds: 2);

class SpeechToTextService implements SttService {
  /// [supportsOnDevice] dice si el paso 1 tiene sentido en esta plataforma.
  ///
  /// Es un parámetro y no una constante para poder probar las dos rutas sin
  /// compilar para web: la degradación es la parte del servicio con más
  /// caminos y la que no se puede verificar a mano en cada plataforma.
  SpeechToTextService(this._speech, {bool? supportsOnDevice})
    : _supportsOnDevice = supportsOnDevice ?? !kIsWeb;

  final stt.SpeechToText _speech;
  final bool _supportsOnDevice;

  bool _initialized = false;

  /// El intento en curso. Lo completa el primero que llegue: un resultado, un
  /// error del reconocedor, el fin de la sesión o el reloj.
  Completer<SttOutcome>? _pending;

  @override
  Future<SttAvailability> checkAvailability() async {
    try {
      // `initialize` del paquete pide el permiso, así que **no** se llama aquí:
      // FR-018 exige pedirlo solo cuando la persona va a usar el micrófono. Lo
      // que sí se puede consultar sin pedir nada es si ya estaba concedido.
      if (!_initialized) {
        // `hasPermission` es un Future: consultar el permiso ya concedido no
        // dispara el diálogo del sistema, así que es seguro aquí.
        return await _speech.hasPermission
            ? _resolveAvailability()
            : SttAvailability.permissionDenied;
      }
      return _resolveAvailability();
    } catch (_) {
      // Se devuelve «falta permiso» y no «plataforma no soportada», y la
      // diferencia es la que decide si el micrófono existe en la interfaz.
      //
      // En el navegador, consultar el permiso antes de inicializar puede
      // lanzar, y declarar por eso que la plataforma no sirve apagaba el
      // micrófono en toda la PWA. Lo honesto aquí es «todavía no se sabe»: se
      // ofrece el botón, y al tocarlo se intenta de verdad.
      return SttAvailability.permissionDenied;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      _initialized = await _speech.initialize(
        // Aquí se cablean los dos canales. Es lo único que hacía falta para
        // que la app dejara de esperar a ciegas.
        onError: _onError,
        onStatus: _onStatus,
      );
      return _initialized && await _speech.hasPermission;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SttOutcome> listenOnce(String languageTag) async {
    if (!_initialized && !(await requestPermission())) {
      return const SttUseAlternative(SttFailure.permissionDenied);
    }

    // Paso 1: en el dispositivo, solo donde el reconocimiento local existe.
    if (_supportsOnDevice) {
      final SttOutcome onDevice = await _attempt(languageTag, onDevice: true);
      // Cualquier respuesta que no sea «no se pudo» es la respuesta final,
      // silencio incluido: si el micrófono funcionó y no se oyó nada, repetir
      // la escucha solo hace esperar ocho segundos más por el mismo silencio.
      if (onDevice is! SttUseAlternative) return onDevice;
      if (!onDevice.failure.worthRetryingOverNetwork) return onDevice;
    }

    // Paso 2: el reconocedor del sistema, que normalmente necesita red.
    // Paso 3 —la alternativa accesible— es lo que la interfaz hace con un
    // `SttUseAlternative`, y ahora llega con el motivo puesto.
    return _attempt(languageTag, onDevice: false);
  }

  @override
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } catch (_) {
      // Nada que hacer.
    }
  }

  /// Un intento de escuchar, con o sin reconocimiento local.
  Future<SttOutcome> _attempt(
    String languageTag, {
    required bool onDevice,
  }) async {
    final Completer<SttOutcome> completer = Completer<SttOutcome>();
    _pending = completer;

    try {
      await _speech.listen(
        // Todo va dentro de SpeechListenOptions: los parámetros sueltos del
        // método están obsoletos en la 7.x.
        listenOptions: stt.SpeechListenOptions(
          localeId: languageTag,
          onDevice: onDevice,
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: false,
          listenFor: _listenWindow,
          pauseFor: _pauseWindow,
        ),
        onResult: _onResult,
      );
    } catch (_) {
      _pending = null;
      return const SttUseAlternative(SttFailure.noRecognizer);
    }

    // El reloj sigue estando, de último recurso: una plataforma que no informa
    // ni resultado ni error no puede dejar el botón en «Escuchando…» para
    // siempre.
    final SttOutcome outcome = await completer.future.timeout(
      _listenWindow + _pauseWindow,
      onTimeout: () => const SttNoSpeech(),
    );

    _pending = null;
    await cancel();
    return outcome;
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!result.finalResult) return;
    final String words = result.recognizedWords.trim();
    _finish(words.isEmpty ? const SttNoSpeech() : SttRecognized(words));
  }

  void _onError(SpeechRecognitionError error) {
    // Silencio no es fallo: FR-020 prohíbe contarlo como error de contenido, y
    // la respuesta correcta es «no se escuchó nada, prueba otra vez», no la
    // alternativa escrita.
    if (isSilence(error.errorMsg)) {
      _finish(const SttNoSpeech());
      return;
    }
    _finish(SttUseAlternative(failureForCode(error.errorMsg)));
  }

  void _onStatus(String status) {
    // `done` y `doneNoResult` significan que la sesión terminó. Si a estas
    // alturas no hay resultado ni error, no se oyó nada.
    if (status == 'done' || status == 'doneNoResult') {
      _finish(const SttNoSpeech());
    }
  }

  /// Cierra el intento en curso con el primer veredicto que llegue.
  void _finish(SttOutcome outcome) {
    final Completer<SttOutcome>? pending = _pending;
    if (pending == null || pending.isCompleted) return;
    pending.complete(outcome);
  }

  SttAvailability _resolveAvailability() {
    if (_speech.isAvailable) return SttAvailability.onDeviceReady;

    // «No hay micrófono» solo se afirma después de haber inicializado de
    // verdad. Antes de eso `isAvailable` es falso siempre, y tomarlo por una
    // respuesta apagaba el micrófono sin haberlo intentado nunca.
    return _initialized
        ? SttAvailability.noMicrophone
        : SttAvailability.permissionDenied;
  }
}
