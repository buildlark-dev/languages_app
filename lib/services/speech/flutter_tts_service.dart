/// Síntesis de voz con el motor del sistema operativo.
///
/// Que la haga el sistema es lo que permite cumplir FR-014 sin empaquetar audio:
/// una vez el dispositivo tiene la voz en inglés instalada, la reproducción es
/// local y funciona sin conexión. Y añadir francés o portugués no exige producir
/// un solo archivo de audio nuevo.
///
/// ## La regla que gobierna este archivo
///
/// **Se intenta hablar primero y se pregunta después.** Nada de lo que diga la
/// lista de voces decide si se intenta: la lista decide, como mucho, *qué* voz
/// se usa.
///
/// Esto es la corrección de un fallo reportado en un iPhone, y la secuencia lo
/// explica entero: se abría la app y no había voz; se tocaba una palabra y
/// salía el aviso de instalar una voz; se iba a Ajustes, se tocaba «Probar la
/// voz» y **entonces sí funcionaba**; al volver a los módulos las palabras ya
/// sonaban; y al cerrar y abrir la PWA, otra vez lo mismo.
///
/// La causa: en Safari —y en iOS en general— `speechSynthesis.getVoices()`
/// devuelve una lista **vacía** hasta que el motor se despierta, y el motor se
/// despierta con la primera orden de hablar hecha dentro de un gesto de la
/// persona. Preguntar «¿hay voces?» antes de hablar nunca puede responder que
/// sí, porque lo que publica las voces es precisamente hablar.
///
/// Mi código preguntaba, recibía la lista vacía, y devolvía «no hay voz» **sin
/// haber intentado hablar ni una vez**. El aparato podía hablar perfectamente.
library;

import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../settings/settings_store.dart';
import 'tts_service.dart';
import 'voice_pick.dart';

/// Cuánto se espera a que el motor confirme que empezó a sonar.
///
/// Si en este tiempo no ha empezado, es que no va a empezar. Generoso a
/// propósito: vale más tardar en avisar que avisar de un fallo que no existe.
const Duration _startWindow = Duration(milliseconds: 1800);

class FlutterTtsService implements TtsService {
  FlutterTtsService(this._tts);

  final FlutterTts _tts;

  TtsAvailability _availability = TtsAvailability.unsupportedPlatform;

  @override
  TtsAvailability get availability => _availability;

  /// El idioma con el que se preparó, para poder reintentar al hablar.
  String? _languageTag;

  /// La voz elegida, para poder decir cuál suena.
  ///
  /// Se guarda porque «el inglés se oye con acento español» es un fallo que no
  /// se puede diagnosticar a ciegas: sin saber qué voz se fijó, lo único que se
  /// puede hacer es volver a adivinar.
  String? get selectedVoice => _selectedVoice;
  String? _selectedVoice;

  bool _handlersWired = false;
  bool _speaking = false;

  /// La velocidad vigente, para que preparar la voz no la reinicie.
  double _rate = defaultSpeechRate;

  /// Se completa cuando el motor confirma que empezó a sonar.
  Completer<void>? _started;

  @override
  Future<TtsAvailability> initialize(String languageTag) async {
    _languageTag = languageTag;
    try {
      // Se reintenta si la lista llega vacía: en el navegador
      // `speechSynthesis.getVoices()` devuelve **cero voces** en la primera
      // llamada y las publica después. En iOS puede no publicarlas nunca hasta
      // que algo haya hablado, y por eso esto ya **no** decide si se habla:
      // solo decide qué voz se elige y qué se le cuenta a la persona.
      List<Object?>? languages;
      for (int attempt = 0; attempt < 5; attempt++) {
        final Object? found = await _tts.getLanguages;
        if (found is List && found.isNotEmpty) {
          languages = found;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }

      if (languages == null) {
        return _availability = TtsAvailability.engineMissing;
      }

      // Se busca por prefijo y no por coincidencia exacta: el contenido pide
      // `en-US`, y un dispositivo con `en-GB` o `en_AU` sirve igual para A1. Ser
      // estricto aquí dejaría sin audio a mucha gente que sí tiene voz en inglés.
      final String prefix = languageTag
          .split(RegExp('[-_]'))
          .first
          .toLowerCase();
      final bool hasLanguage = languages.any(
        (Object? tag) => '$tag'.toLowerCase().startsWith(prefix),
      );

      if (!hasLanguage) return _availability = TtsAvailability.languageMissing;

      await _tts.setLanguage(languageTag);
      await _selectVoice(languageTag);
      // La última velocidad pedida, no una constante. Aquí había un 0,9 fijo
      // que **pisaba la preferencia guardada en cada arranque**: se elegía una
      // velocidad en Ajustes, se cerraba la app y volvía a la de fábrica.
      await _tts.setSpeechRate(_rate);
      return _availability = TtsAvailability.available;
    } catch (_) {
      // Un fallo al inicializar no debe impedir estudiar: se degrada a texto.
      return _availability = TtsAvailability.engineMissing;
    }
  }

  @override
  Future<SpeakOutcome> speak(String text) async {
    _wireHandlers();

    try {
      // Antes de la orden de hablar no se espera **nada** que se pueda evitar.
      //
      // En iOS el permiso para hablar viene del gesto de la persona y se agota;
      // cada `await` previo —consultar voces, parar lo anterior, fijar el
      // idioma— gasta ese margen. Parar solo se pide si de verdad había algo
      // sonando.
      if (_speaking) {
        await _tts.stop();
        _speaking = false;
      }

      final Completer<void> started = Completer<void>();
      _started = started;

      await _tts.speak(text);

      // ¿Sonó? Lo dice el motor, no la lista de voces.
      bool begun = true;
      await started.future.timeout(
        _startWindow,
        onTimeout: () => begun = false,
      );

      if (begun) {
        // Si se habló sin haber podido preparar la voz —el caso de iOS—, ahora
        // sí hay lista: se prepara para que la **siguiente** palabra suene con
        // voz inglesa y no con la que el sistema tenga por defecto.
        if (!_availability.canSpeak && _languageTag != null) {
          unawaited(initialize(_languageTag!));
        }
        return SpeakOutcome.spoken;
      }

      // No empezó. Solo entonces se consulta, y la consulta decide qué se
      // dice: sin voces es «no hay voz»; con voces, el motor falló por otra
      // cosa y no hay que mandar a nadie a instalar nada.
      return await _hasAnyVoice() ? SpeakOutcome.failed : SpeakOutcome.noVoice;
    } catch (_) {
      // Sigue sin lanzar: quien llama es un botón. Pero ahora se entera.
      return SpeakOutcome.failed;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
      _speaking = false;
    } catch (_) {
      // Nada que hacer si ni parar funciona.
    }
  }

  @override
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(minSpeechRate, maxSpeechRate);
    try {
      await _tts.setSpeechRate(_rate);
    } catch (_) {
      // La velocidad es una preferencia: perderla no rompe nada.
    }
  }

  /// Engancha los avisos del motor. Una sola vez, y sin ida y vuelta.
  ///
  /// Son asignaciones locales: no cruzan al lado nativo, así que no gastan el
  /// margen del gesto aunque se llamen justo antes de hablar.
  void _wireHandlers() {
    if (_handlersWired) return;
    _handlersWired = true;

    _tts.setStartHandler(() {
      _speaking = true;
      if (_started?.isCompleted == false) _started!.complete();
    });
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _tts.setErrorHandler((Object? message) => _speaking = false);
  }

  /// Si el aparato tiene alguna voz, la que sea.
  ///
  /// Se pregunta **después** de intentar hablar, que es cuando la respuesta
  /// vale algo: en iOS la lista se publica al despertar el motor.
  Future<bool> _hasAnyVoice() async {
    try {
      final Object? found = await _tts.getLanguages;
      return found is List && found.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Fija una voz **concreta** del idioma, no solo el idioma.
  ///
  /// `setLanguage` debería bastar y en el navegador no basta: la voz por
  /// defecto es la del idioma del documento —español, aquí— y nada garantiza
  /// que fijar el idioma la cambie. Elegir la voz por nombre quita la
  /// ambigüedad.
  Future<void> _selectVoice(String languageTag) async {
    try {
      final Object? voices = await _tts.getVoices;
      if (voices is! List) return;

      final VoiceChoice? choice = pickVoice(voices, languageTag);
      if (choice == null) return;

      await _tts.setVoice(choice);
      _selectedVoice = choice['name'];
    } catch (_) {
      // Sin voz elegida queda lo que hiciera `setLanguage`. Es peor, no es
      // fatal, y rendirse aquí no debe impedir que la app hable.
    }
  }
}
