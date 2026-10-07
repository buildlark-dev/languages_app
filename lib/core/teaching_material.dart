/// Material de estudio que **no se puntúa**.
///
/// Los tres tipos de aquí se consultan, no se responden: el estudiante los lee
/// y luego practica con los ejercicios de la lección. FR-013 lo fija
/// explícitamente, porque antes la frontera era ambigua y las preguntas de la
/// lectura habrían quedado fuera de toda calificación.
///
/// Las preguntas de comprensión del pasaje **sí** se puntúan, pero viven como
/// `Exercise` dentro de la lección, no aquí.
library;

/// Explicación gramatical en español.
class GrammarExplanation {
  const GrammarExplanation({
    required this.title,
    required this.bodyHtml,
  });

  /// Qué se explica. Ej.: "El verbo *to be* y los pronombres".
  final String title;

  /// El cuerpo de la explicación, en HTML reducido.
  ///
  /// Se admite marcado porque una explicación gramatical necesita tablas de
  /// conjugación, negritas y código en línea para contrastar formas correctas e
  /// incorrectas. La interfaz renderiza un subconjunto acotado; no es HTML
  /// arbitrario ni proviene de fuera de la app.
  final String bodyHtml;
}

/// Un ejemplo con su traducción, para ver la regla en uso.
class BilingualExample {
  const BilingualExample({
    required this.target,
    required this.spanish,
  });

  /// La frase en el idioma estudiado.
  final String target;

  /// Su traducción al español.
  final String spanish;
}

/// Texto de lectura de un módulo.
///
/// Solo el texto. Sus preguntas de comprensión son ejercicios de la lección que
/// lo referencia mediante `Lesson.readingRef`.
class ReadingPassage {
  const ReadingPassage({
    required this.id,
    required this.title,
    required this.paragraphs,
  });

  /// Identificador al que apunta `Lesson.readingRef`.
  final String id;

  final String title;

  /// El texto partido en párrafos, para poder renderizarlo con espaciado
  /// legible a 360 dp sin heurísticas de división.
  final List<String> paragraphs;
}
