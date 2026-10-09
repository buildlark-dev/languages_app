/// Doble de [TtsService] capaz de simular **los cuatro** estados de
/// disponibilidad.
///
/// Un doble que solo cubriera `available` dejaría sin probar precisamente el caso
/// que más importa: que al faltar la voz del idioma se muestre el transcript en
/// lugar de un botón de audio que no suena.
library;

import 'package:languages_app/services/speech/tts_service.dart';

class FakeTtsService implements TtsService {
  FakeTtsService({this.initialAvailability = TtsAvailability.available});

  /// Lo que devolverá [initialize].
  TtsAvailability initialAvailability;

  TtsAvailability _availability = TtsAvailability.unsupportedPlatform;

  /// Qué textos se pidió leer, en orden.
  final List<String> spoken = <String>[];

  int stopCount = 0;
  double? lastRate;

  @override
  TtsAvailability get availability => _availability;

  /// Con qué idioma se preparó, o nulo si nadie la preparó.
  ///
  /// Lo guarda para que una prueba pueda afirmar que **se llamó**, que es lo
  /// que faltaba cuando la app se desplegó sin audio.
  String? initializedWith;

  @override
  Future<TtsAvailability> initialize(String languageTag) async {
    initializedWith = languageTag;
    return _availability = initialAvailability;
  }

  @override
  Future<SpeakOutcome> speak(String text) async {
    // Mismo comportamiento que la implementación real: si no hay voz, no habla
    // y lo dice. Si el doble hablara igualmente, una prueba podría pasar con
    // audio que en producción no suena.
    if (!_availability.canSpeak) return SpeakOutcome.noVoice;
    spoken.add(text);
    return SpeakOutcome.spoken;
  }

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> setRate(double rate) async => lastRate = rate;
}
