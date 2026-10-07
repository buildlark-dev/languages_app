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

  @override
  Future<TtsAvailability> initialize(String languageTag) async {
    try {
      final Object? languages = await _tts.getLanguages;
      if (languages is! List || languages.isEmpty) {
        return _availability = TtsAvailability.engineMissing;
      }

      // Se busca por prefijo y no por coincidencia exacta: el contenido pide
      // `en-US`, y un dispositivo con `en-GB` o `en_AU` sirve igual para A1. Ser
      // estricto aquí dejaría sin audio a mucha gente que sí tiene voz en inglés.
      final String prefix = languageTag.split(RegExp('[-_]')).first.toLowerCase();
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
  Future<void> speak(String text) async {
    if (!_availability.canSpeak) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Silencioso a propósito: quien llama es un botón, no un flujo que pueda
      // decidir qué hacer con el error.
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
