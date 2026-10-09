/// Compara la respuesta del estudiante con las aceptadas.
///
/// FR-026: se aceptan **todas** las variantes declaradas, y las diferencias de
/// mayúsculas o de espacios sobrantes no penalizan. Castigar `Is` cuando se
/// esperaba `is` no enseña nada sobre inglés.
library;

/// Normaliza una respuesta para compararla.
///
/// Qué se normaliza y qué **no**:
///
/// * Mayúsculas y minúsculas: se igualan.
/// * Espacios al borde y repetidos: se colapsan a uno.
/// * Apóstrofos tipográficos (`’`, `‘`, `´`): se convierten al recto (`'`).
///   Esto importa de verdad: un teclado de móvil suele insertar `’` al escribir
///   `aren’t`, y comparar carácter a carácter contra `aren't` fallaría por un
///   motivo que no tiene nada que ver con el idioma.
/// * La puntuación **no** se elimina. En inglés el apóstrofo distingue formas
///   (`its` frente a `it's`), así que quitarlo convertiría respuestas distintas
///   en la misma.
String normalizeAnswer(String raw) => raw
    .trim()
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll('‘', "'")
    .replaceAll('´', "'")
    .replaceAll(RegExp(r'\s+'), ' ');

/// Cómo encajó la respuesta con lo esperado.
enum AnswerMatch {
  /// No coincide con ninguna variante aceptada.
  none,

  /// Coincide tal cual.
  exact,

  /// Coincide salvo por el apóstrofo, que falta o sobra.
  ///
  /// Cuenta como acierto. Escribir `dont` por `don't` es un fallo de teclado,
  /// no de inglés, y suspender por eso enseña a desconfiar del corrector antes
  /// que del idioma. Pero **sí se dice cómo se escribe**: si nadie lo corrige,
  /// la forma sin apóstrofo se fija.
  apostrophe;

  bool get isCorrect => this != AnswerMatch.none;
}

/// Quita los apóstrofos, para comparar ignorándolos.
String _withoutApostrophes(String normalized) => normalized.replaceAll("'", '');

/// Compara la respuesta con las aceptadas, distinguiendo el caso del apóstrofo.
///
/// Devuelve la variante esperada junto al tipo de coincidencia, para que la
/// interfaz pueda decir «se escribe `aren't`» sin volver a buscarla.
({AnswerMatch match, String? expected}) checkAnswer(
  String given,
  List<String> accepted,
) {
  final String normalized = normalizeAnswer(given);
  if (normalized.isEmpty) return (match: AnswerMatch.none, expected: null);

  // Primero las coincidencias exactas: si alguna encaja tal cual, no hay nada
  // que corregir aunque otra variante también encajaría sin apóstrofos.
  for (final String candidate in accepted) {
    if (normalizeAnswer(candidate) == normalized) {
      return (match: AnswerMatch.exact, expected: candidate);
    }
  }

  final String bare = _withoutApostrophes(normalized);
  for (final String candidate in accepted) {
    if (_withoutApostrophes(normalizeAnswer(candidate)) == bare) {
      return (match: AnswerMatch.apostrophe, expected: candidate);
    }
  }

  return (match: AnswerMatch.none, expected: null);
}

/// Si la respuesta coincide con alguna de las aceptadas.
bool matchesAnswer(String given, List<String> accepted) =>
    checkAnswer(given, accepted).match.isCorrect;

/// Si una frase construida coincide con la objetivo.
///
/// Usa la misma normalización, de modo que montar las fichas con un espacio de
/// más no cuenta como error.
bool matchesSentence(String given, String target) =>
    normalizeAnswer(given) == normalizeAnswer(target);
