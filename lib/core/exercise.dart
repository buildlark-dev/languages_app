/// Los cinco tipos de ejercicio evaluable.
///
/// Es una jerarquía `sealed`, lo que da dos cosas: el compilador obliga a
/// cubrir las cinco variantes en cada `switch` —si mañana se añade un tipo, el
/// código que lo olvide no compila— y nadie fuera de este archivo puede
/// introducir un tipo nuevo sin pasar por aquí.
///
/// La decisión de diseño que importa está en [OralExercise]: su alternativa
/// accesible es un parámetro **obligatorio**. Un ejercicio de escucha o de
/// pronunciación sin alternativa no compila, así que el Principio VII ("el
/// audio es apoyo, no requisito") no depende de que nadie se acuerde.
library;

/// Base de todo ítem evaluable.
sealed class Exercise {
  const Exercise({required this.explanation});

  /// Por qué la respuesta correcta lo es.
  ///
  /// Obligatorio en las cinco variantes (FR-025). No es "cuál era la
  /// respuesta": es el motivo, que es lo que enseña.
  final String explanation;
}

/// Ejercicio que requiere oír o hablar.
///
/// Existe como capa intermedia para que [accessibleAlternative] sea un
/// contrato único: la interfaz y las pruebas la obtienen igual de ambas
/// variantes, sin distinguir cuál es.
sealed class OralExercise extends Exercise {
  const OralExercise({
    required super.explanation,
    required this.accessibleAlternative,
  });

  /// Con qué se completa el ejercicio sin micrófono ni altavoz.
  ///
  /// Cumple dos funciones a la vez: la accesibilidad que exige FR-019, y la
  /// ruta sin conexión cuando el reconocimiento de habla no está disponible
  /// (D6 de research.md). Por eso es obligatoria y no opcional.
  final String accessibleAlternative;
}

/// Opción múltiple.
final class MultipleChoiceExercise extends Exercise {
  const MultipleChoiceExercise({
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required super.explanation,
  });

  final String prompt;

  /// Al menos tres opciones, según la invariante 19 del contrato de contenido.
  final List<String> options;

  /// Índice de la opción correcta dentro de [options].
  final int answerIndex;

  String get correctOption => options[answerIndex];
}

/// Construir una frase a partir de fichas desordenadas.
final class SentenceBuilderExercise extends Exercise {
  const SentenceBuilderExercise({
    required this.targetSentence,
    required this.tokens,
    required super.explanation,
  });

  /// La frase correcta, ya montada.
  final String targetSentence;

  /// Las fichas que se le presentan al estudiante, en orden arbitrario.
  final List<String> tokens;
}

/// Rellenar un hueco.
final class GapFillExercise extends Exercise {
  const GapFillExercise({
    required this.sentenceWithGap,
    required this.acceptedAnswers,
    required super.explanation,
    this.hint,
  });

  /// La frase con el hueco marcado como `___`.
  final String sentenceWithGap;

  /// **Todas** las respuestas válidas.
  ///
  /// Más de una suele ser correcta (`is` y `'s`), y aceptar solo una penalizaría
  /// una respuesta buena. La comparación normaliza mayúsculas y espacios
  /// (FR-026), así que estas se declaran ya en minúsculas y sin espacios al
  /// borde.
  final List<String> acceptedAnswers;

  /// Pista opcional sobre qué se está practicando.
  final String? hint;
}

/// Comprensión auditiva: se escucha un audio y se responde sobre lo oído.
final class ListeningExercise extends OralExercise {
  const ListeningExercise({
    required this.spokenText,
    required this.question,
    required this.options,
    required this.answerIndex,
    required super.explanation,
    required String transcriptFallback,
  }) : super(accessibleAlternative: transcriptFallback);

  /// Lo que la síntesis de voz debe leer.
  final String spokenText;

  final String question;
  final List<String> options;
  final int answerIndex;

  /// El texto escrito del audio, para quien no pueda oírlo.
  ///
  /// Mismo valor que [accessibleAlternative]; se expone con este nombre porque
  /// en un ejercicio de escucha "transcripción" dice más que "alternativa".
  String get transcriptFallback => accessibleAlternative;
}

/// Pronunciación: se dice una frase en voz alta y se compara con la objetivo.
final class PronunciationExercise extends OralExercise {
  const PronunciationExercise({
    required this.targetPhrase,
    required this.translation,
    required super.explanation,
    required String writtenFallback,
  }) : super(accessibleAlternative: writtenFallback);

  /// La frase que el estudiante debe decir.
  final String targetPhrase;

  /// Su traducción al español, para que sepa qué está diciendo.
  final String translation;

  /// Cómo se completa el ejercicio por escrito.
  ///
  /// Mismo valor que [accessibleAlternative], con el nombre que usa el
  /// contrato de contenido.
  String get writtenFallback => accessibleAlternative;
}
