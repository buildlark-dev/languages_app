/// Verifica que la pronunciación se juzgue por la frase, no por el acento.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/engine/pronunciation_matcher.dart';

PronunciationMatch match(String heard, String target) =>
    matchPronunciation(recognized: heard, target: target);

void main() {
  group('acepta variaciones ajenas al idioma', () {
    test('idéntica', () {
      expect(match('Nice to meet you.', 'Nice to meet you.').accepted, isTrue);
    });

    test('diferencias de mayúsculas', () {
      expect(match('NICE TO MEET YOU', 'Nice to meet you.').accepted, isTrue);
    });

    test('puntuación que el reconocedor añade o quita', () {
      // Nadie «pronuncia una coma»: conservarla solo daría fallos espurios.
      expect(
        match('nice, to meet you!', 'Nice to meet you.').accepted,
        isTrue,
      );
    });

    test('espacios de más', () {
      expect(match('nice   to  meet you', 'Nice to meet you.').accepted, isTrue);
    });

    test('apóstrofo tipográfico', () {
      expect(match('she isn’t a nurse', "She isn't a nurse.").accepted, isTrue);
    });

    test('una palabra perdida en una frase larga', () {
      // El reconocedor se come artículos con frecuencia. Con 8 de 9 palabras
      // (89 %) se acepta: la pronunciación fue correcta.
      expect(
        match(
          'there is market next to the library today',
          'There is a market next to the library today.',
        ).accepted,
        isTrue,
      );
    });
  });

  group('rechaza lo que de verdad está mal', () {
    test('una frase distinta', () {
      final PronunciationMatch m = match(
        'good morning everyone',
        'Nice to meet you.',
      );
      expect(m.accepted, isFalse);
      expect(m.similarity, lessThan(0.5));
    });

    test('el orden importa: las mismas palabras desordenadas no valen', () {
      // Se usa subsecuencia común y no intersección justamente por esto.
      final PronunciationMatch m = match(
        'teacher a is sister my',
        'My sister is a teacher.',
      );
      expect(m.accepted, isFalse);
    });

    test('media frase no basta', () {
      expect(match('my sister', 'My sister is a teacher.').accepted, isFalse);
    });

    test('silencio no acierta', () {
      expect(match('', 'Nice to meet you.').accepted, isFalse);
    });

    test('una frase objetivo vacía nunca acierta', () {
      expect(match('algo', '').accepted, isFalse);
    });
  });

  group('informa de lo entendido y lo esperado (FR-017)', () {
    test('devuelve ambas frases normalizadas', () {
      final PronunciationMatch m = match('Nice to MEET you!', 'Nice to meet you.');
      expect(m.heard, 'nice to meet you');
      expect(m.expected, 'nice to meet you');
    });

    test('al fallar, lo entendido permite ver el motivo', () {
      final PronunciationMatch m = match('my sister is teacher', 'My sister is a teacher.');
      expect(m.heard, 'my sister is teacher');
      expect(m.expected, 'my sister is a teacher');
      // 4 de 5 palabras: por encima del umbral, así que se acepta.
      expect(m.accepted, isTrue);
    });
  });

  test('el umbral es del 80 %', () {
    expect(pronunciationAcceptThreshold, 0.8);

    // Exactamente 4 de 5 palabras en orden: justo en el umbral.
    final PronunciationMatch atThreshold = match(
      'one two three four',
      'one two three four five',
    );
    expect(atThreshold.similarity, closeTo(0.8, 1e-9));
    expect(atThreshold.accepted, isTrue);

    // 3 de 5: por debajo.
    final PronunciationMatch below = match(
      'one two three',
      'one two three four five',
    );
    expect(below.similarity, closeTo(0.6, 1e-9));
    expect(below.accepted, isFalse);
  });
}
