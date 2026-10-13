/// Compara lo que se reconoció con la frase objetivo.
///
/// **Qué se juzga y qué no**: se juzga si lo dicho se reconoce como la frase
/// objetivo. **No** se juzga acento ni entonación, por dos razones: ningún
/// reconocedor de voz los mide con fiabilidad, y puntuar el acento de un
/// principiante absoluto solo lo frustraría.
///
/// Por eso no es una comparación exacta. Los reconocedores se comen artículos,
/// escriben números como cifras y añaden puntuación, y fallar por eso castigaría
/// una pronunciación correcta por un motivo que no tiene nada que ver con el
/// idioma. Se acepta a partir de una similitud de palabras del 80 %.
library;

/// Proporción mínima de palabras acertadas para dar la frase por buena.
const double pronunciationAcceptThreshold = 0.8;

/// Lo que arroja comparar una frase dicha con la objetivo.
class PronunciationMatch {
  const PronunciationMatch({
    required this.accepted,
    required this.similarity,
    required this.heard,
    required this.expected,
  });

  final bool accepted;

  /// Proporción de palabras de la frase objetivo que aparecieron en orden.
  final double similarity;

  /// Lo que se entendió, normalizado, para poder mostrárselo (FR-017).
  final String heard;

  /// Lo que se esperaba, normalizado.
  final String expected;
}

/// Normaliza una frase para compararla.
///
/// Quita la puntuación, a diferencia de la comparación de huecos escritos: aquí no
/// hay forma de que alguien «pronuncie una coma», así que conservarla solo
/// introduciría fallos espurios.
List<String> normalizeSpoken(String raw) => raw
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
    .split(RegExp(r'\s+'))
    .where((String word) => word.isNotEmpty)
    .toList(growable: false);

/// Compara lo reconocido con la frase objetivo.
PronunciationMatch matchPronunciation({
  required String recognized,
  required String target,
}) {
  final List<String> heard = normalizeSpoken(recognized);
  final List<String> expected = normalizeSpoken(target);

  final String heardText = heard.join(' ');
  final String expectedText = expected.join(' ');

  if (expected.isEmpty) {
    return PronunciationMatch(
      accepted: false,
      similarity: 0,
      heard: heardText,
      expected: expectedText,
    );
  }

  // Camino rápido: idénticas tras normalizar.
  if (heardText == expectedText) {
    return PronunciationMatch(
      accepted: true,
      similarity: 1,
      heard: heardText,
      expected: expectedText,
    );
  }

  final int matched = _longestCommonSubsequence(heard, expected);
  final double similarity = matched / expected.length;

  return PronunciationMatch(
    accepted: similarity >= pronunciationAcceptThreshold,
    similarity: similarity,
    heard: heardText,
    expected: expectedText,
  );
}

/// Longitud de la subsecuencia común más larga entre dos listas de palabras.
///
/// Se usa subsecuencia y no intersección a propósito: el **orden** importa. Decir
/// «teacher a is sister my» contiene las mismas palabras que la frase correcta y
/// no es la frase correcta.
int _longestCommonSubsequence(List<String> a, List<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;

  // Solo se guardan dos filas: la tabla completa no hace falta y una frase de
  // examen puede tener bastantes palabras.
  List<int> previous = List<int>.filled(b.length + 1, 0);
  List<int> current = List<int>.filled(b.length + 1, 0);

  for (int i = 1; i <= a.length; i++) {
    for (int j = 1; j <= b.length; j++) {
      current[j] = a[i - 1] == b[j - 1]
          ? previous[j - 1] + 1
          : (previous[j] > current[j - 1] ? previous[j] : current[j - 1]);
    }
    final List<int> swap = previous;
    previous = current;
    current = swap;
    current.fillRange(0, current.length, 0);
  }

  return previous[b.length];
}
