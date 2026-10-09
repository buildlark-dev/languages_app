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
library;

import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'stt_service.dart';

/// Cuánto se espera a que alguien hable antes de darlo por silencio.
const Duration _listenWindow = Duration(seconds: 6);

/// Cuánto silencio basta para dar la frase por terminada.
const Duration _pauseWindow = Duration(seconds: 2);

class SpeechToTextService implements SttService {
  SpeechToTextService(this._speech);

  final stt.SpeechToText _speech;

  bool _initialized = false;

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
      // ofrece el botón, y al tocarlo se intenta de verdad. Si entonces no hay
      // reconocedor, la degradación de tres pasos lleva a la alternativa
      // escrita, que es exactamente para lo que está.
      return SttAvailability.permissionDenied;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      _initialized = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
      return _initialized && await _speech.hasPermission;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SttOutcome> listenOnce(String languageTag) async {
    if (!_initialized && !(await requestPermission())) {
      return const SttUseAlternative(SttAvailability.permissionDenied);
    }

    // Paso 1: en el dispositivo. La sesión falla si no está disponible, así que el
    // fallo es la señal para pasar al siguiente paso, no un problema.
    final SttOutcome onDevice = await _attempt(languageTag, onDevice: true);
    if (onDevice is! SttUseAlternative) return onDevice;

    // Paso 2: el reconocedor del sistema, que normalmente necesita red.
    final SttOutcome network = await _attempt(languageTag, onDevice: false);
    if (network is! SttUseAlternative) return network;

    // Paso 3: la alternativa accesible.
    return const SttUseAlternative(SttAvailability.networkOnly);
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
    final Completer<String?> completer = Completer<String?>();

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
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(result.recognizedWords);
          }
        },
      );
    } catch (_) {
      return const SttUseAlternative(SttAvailability.unsupportedPlatform);
    }

    // Si no llega resultado final, la ventana de escucha cierra el intento.
    final String? words = await completer.future.timeout(
      _listenWindow + _pauseWindow,
      onTimeout: () => null,
    );

    await cancel();

    if (words == null) {
      return onDevice
          // En el paso 1 el silencio puede ser «no hay reconocimiento local»,
          // así que se deja pasar al paso 2 antes de concluir nada.
          ? const SttUseAlternative(SttAvailability.networkOnly)
          : const SttNoSpeech();
    }
    if (words.trim().isEmpty) return const SttNoSpeech();
    return SttRecognized(words);
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
