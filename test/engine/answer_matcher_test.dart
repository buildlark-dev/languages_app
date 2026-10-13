/// Verifica que calificar un hueco no penaliza por motivos ajenos al idioma.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/engine/answer_matcher.dart';

void main() {
  group('normalizeAnswer', () {
    test('iguala mayúsculas y quita espacios al borde', () {
      expect(normalizeAnswer('  Is  '), 'is');
    });

    test('colapsa espacios interiores repetidos', () {
      expect(normalizeAnswer('are    am'), 'are am');
    });

    test('convierte apóstrofos tipográficos al recto', () {
      // Lo que inserta un teclado de móvil al escribir aren’t.
      expect(normalizeAnswer('aren’t'), "aren't");
      expect(normalizeAnswer('aren‘t'), "aren't");
      expect(normalizeAnswer('aren´t'), "aren't");
    });

    test('NO elimina la puntuación significativa', () {
      // En inglés el apóstrofo distingue formas: its / it's no son lo mismo.
      expect(normalizeAnswer("it's") == normalizeAnswer('its'), isFalse);
    });
  });

  group('matchesAnswer', () {
    const List<String> accepted = <String>['is', "'s"];

    test('acepta cualquiera de las variantes declaradas', () {
      expect(matchesAnswer('is', accepted), isTrue);
      expect(matchesAnswer("'s", accepted), isTrue);
    });

    test('acepta con mayúsculas y espacios sobrantes', () {
      expect(matchesAnswer('  IS ', accepted), isTrue);
    });

    test('acepta el apóstrofo tipográfico contra el recto declarado', () {
      expect(matchesAnswer('’s', accepted), isTrue);
    });

    test('rechaza una respuesta distinta', () {
      expect(matchesAnswer('are', accepted), isFalse);
    });

    test('una respuesta vacía nunca acierta', () {
      expect(matchesAnswer('', accepted), isFalse);
      expect(matchesAnswer('   ', accepted), isFalse);
    });

    test('la respuesta con dos palabras del enunciado doble', () {
      // Del contenido de referencia: "___ you from Peru? — No, I ___ from Chile."
      expect(matchesAnswer('are am', <String>['are am', 'are, am']), isTrue);
      expect(matchesAnswer('Are  Am', <String>['are am']), isTrue);
    });
  });

  group('matchesSentence', () {
    test('acepta la frase montada con espaciado irregular', () {
      expect(
        matchesSentence('My sister  is a teacher.', 'My sister is a teacher.'),
        isTrue,
      );
    });

    test('rechaza un orden distinto', () {
      expect(
        matchesSentence('Is my sister a teacher.', 'My sister is a teacher.'),
        isFalse,
      );
    });
  });
}
