/// Que el clip mande y la síntesis cubra el hueco.
///
/// Es la prueba de T196, y el motivo de la tarea cabe en una frase: escuchar
/// una palabra dejó de depender de que el aparato tenga voz inglesa. Las tres
/// formas en que eso falló —lista de voces vacía en el navegador, vacía en iOS
/// hasta que algo habla, y voz española leyendo inglés— desaparecen cuando el
/// sonido sale de un archivo que viene dentro de la app.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/services/speech/clip_backed_tts_service.dart';
import 'package:languages_app/services/speech/clip_player.dart';
import 'package:languages_app/services/speech/tts_service.dart';

import '../../fakes/fake_tts_service.dart';

class _FakeClipPlayer implements ClipPlayer {
  ClipOutcome outcome = ClipOutcome.played;
  final List<String> played = <String>[];
  int stopCount = 0;

  @override
  Future<ClipOutcome> play(String assetPath) async {
    played.add(assetPath);
    return outcome;
  }

  @override
  Future<void> stop() async => stopCount++;
}

void main() {
  late _FakeClipPlayer clips;
  late FakeTtsService voice;
  late ClipBackedTtsService service;

  setUp(() async {
    clips = _FakeClipPlayer();
    voice = FakeTtsService();
    service = ClipBackedTtsService(
      voice: voice,
      clips: clips,
      catalog: const <String, String>{
        'name': 'assets/audio/en/name-8d39bde6.mp3',
      },
    );
    // Como en la app: el curso prepara la voz al abrirse. Sin esto el doble
    // responde «no hay voz» y la prueba del respaldo no probaría nada.
    await service.initialize('en-US');
  });

  test('con clip, suena el clip y no la síntesis', () async {
    expect(await service.speak('name'), SpeakOutcome.spoken);

    expect(clips.played, <String>['assets/audio/en/name-8d39bde6.mp3']);
    expect(
      voice.spoken,
      isEmpty,
      reason: 'Teniendo grabación, sintetizar solo añade formas de fallar',
    );
  });

  test('la búsqueda no distingue mayúsculas ni espacios de sobra', () async {
    // Misma normalización que el generador: si las dos no coincidieran, el
    // clip existiría y nadie lo encontraría.
    expect(await service.speak('  Name  '), SpeakOutcome.spoken);
    expect(clips.played, hasLength(1));
  });

  test('sin clip, habla la síntesis', () async {
    // El caso del contenido nuevo: A2 no tendrá audio hasta que alguien
    // ejecute el generador, y mientras tanto el botón no puede quedarse mudo.
    expect(await service.speak('surname'), SpeakOutcome.spoken);

    expect(clips.played, isEmpty);
    expect(voice.spoken, <String>['surname']);
  });

  test('si el clip falla, todavía queda la síntesis', () async {
    // Un asset que no se empaquetó, un códec que el navegador rechaza.
    // Rendirse aquí sería cambiar un fallo por otro.
    clips.outcome = ClipOutcome.failed;

    expect(await service.speak('name'), SpeakOutcome.spoken);
    expect(voice.spoken, <String>['name']);
  });

  test('sin clip y sin voz, se dice que no hay voz', () async {
    voice = FakeTtsService(
      initialAvailability: TtsAvailability.engineMissing,
    );
    service = ClipBackedTtsService(
      voice: voice,
      clips: clips,
      catalog: const <String, String>{},
    );
    await service.initialize('en-US');

    expect(await service.speak('surname'), SpeakOutcome.noVoice);
  });

  test('parar calla las dos fuentes', () async {
    // No se sabe cuál estaba sonando, y dejar una viva es exactamente el
    // fallo que se reportó: el audio seguía al cambiar de ejercicio.
    await service.stop();

    expect(clips.stopCount, 1);
    expect(voice.stopCount, 1);
  });

  test('la velocidad solo afecta a la síntesis', () async {
    // Un clip grabado suena a la velocidad a la que se grabó. Queda dicho en
    // la prueba para que nadie lo descubra creyendo que el ajuste está roto.
    await service.setRate(0.6);

    expect(voice.lastRate, 0.6);
  });
}
