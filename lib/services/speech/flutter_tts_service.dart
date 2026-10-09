/// Síntesis de voz con el motor del sistema operativo.
///
/// Que la haga el sistema es lo que permite cumplir FR-014 sin empaquetar audio:
/// una vez el dispositivo tiene la voz en inglés instalada, la reproducción es
/// local y funciona sin conexión. Y añadir francés o portugués no exige producir
/// un solo archivo de audio nuevo.
library;

import 'package:flutter_tts/flutter_tts.dart';

import 'tts_service.dart';

class FlutterTtsService implements TtsService {
  FlutterTtsService(this._tts);

  final FlutterTts _tts;

  TtsAvailability _availability = TtsAvailability.unsupportedPlatform;

  @override
  TtsAvailability get availability => _availability;

  /// El idioma con el que se preparó, para poder reintentar al hablar.
  String? _languageTag;

  @override
  Future<TtsAvailability> initialize(String languageTag) async {
    _languageTag = languageTag;
    try {
      // Se reintenta si la lista llega vacía, y eso no es paranoia: en el
      // navegador `speechSynthesis.getVoices()` devuelve **cero voces** en la
      // primera llamada y las publica después, al disparar `voiceschanged`.
      // Preguntar una sola vez al abrir el curso cae justo en esa ventana, y
      // la app concluía que el dispositivo no tenía motor de voz.
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
      await _tts.setSpeechRate(0.9);
      return _availability = TtsAvailability.available;
    } catch (_) {
      // Un fallo al inicializar no debe impedir estudiar: se degrada a texto.
      return _availability = TtsAvailability.engineMissing;
    }
  }

  @override
  Future<SpeakOutcome> speak(String text) async {
    // Si la preparación había dicho que no, se vuelve a intentar antes de
    // rendirse. La primera consulta pudo caer antes de que el navegador
    // publicara sus voces, y rendirse para siempre por eso deja la app muda
    // durante toda la sesión.
    if (!_availability.canSpeak && _languageTag != null) {
      await initialize(_languageTag!);
    }
    if (!_availability.canSpeak) return SpeakOutcome.noVoice;

    try {
      await _tts.stop();
      await _tts.speak(text);
      return SpeakOutcome.spoken;
    } catch (_) {
      // Sigue sin lanzar: quien llama es un botón. Pero ahora se entera.
      return SpeakOutcome.failed;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Nada que hacer si ni parar funciona.
    }
  }

  @override
  Future<void> setRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate.clamp(0.3, 1.0));
    } catch (_) {
      // La velocidad es una preferencia: perderla no rompe nada.
    }
  }
}
