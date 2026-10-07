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

  @override
  Future<TtsAvailability> initialize(String languageTag) async =>
      _availability = initialAvailability;

  @override
  Future<void> speak(String text) async {
    // Mismo comportamiento que la implementación real: no-op silencioso si no
    // está disponible. Si el doble hablara igualmente, una prueba podría pasar
    // con audio que en producción no suena.
    if (!_availability.canSpeak) return;
    spoken.add(text);
  }

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> setRate(double rate) async => lastRate = rate;
}
