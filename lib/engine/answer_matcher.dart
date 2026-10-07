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

/// Si la respuesta coincide con alguna de las aceptadas.
bool matchesAnswer(String given, List<String> accepted) {
  final String normalized = normalizeAnswer(given);
  if (normalized.isEmpty) return false;
  for (final String candidate in accepted) {
    if (normalizeAnswer(candidate) == normalized) return true;
  }
  return false;
}

/// Si una frase construida coincide con la objetivo.
///
/// Usa la misma normalización, de modo que montar las fichas con un espacio de
/// más no cuenta como error.
bool matchesSentence(String given, String target) =>
    normalizeAnswer(given) == normalizeAnswer(target);
