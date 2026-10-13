/// Calificación de lecciones y exámenes.
///
/// La decisión que no es obvia está en [ExerciseOutcome.unavailable]: un
/// ejercicio oral que no se pudo intentar —sin micrófono, sin permiso, sin
/// paquete de idioma— **sale del denominador**. No cuenta como acierto ni como
/// fallo.
///
/// Es lo que exige FR-020, y es lo que hace posible SC-008: que una lección se
/// pueda aprobar con el micrófono denegado. Si esos ejercicios contaran como
/// fallos, una lección con dos ítems orales de diez tendría un techo del 80 % y
/// un examen sería inaprobable sin micrófono.
library;

import '../core/activity_score.dart';

/// Resultado de un ejercicio individual.
enum ExerciseOutcome {
  correct,
  incorrect,

  /// No se pudo intentar por una limitación del dispositivo o del permiso.
  ///
  /// Se resolvió por la alternativa accesible, o se omitió tras varios intentos
  /// de reconocimiento fallidos.
  unavailable,
}

/// Lo que una actividad calificada arroja.
class ScoreResult {
  const ScoreResult({
    required this.correct,
    required this.answered,
    required this.unavailable,
    required this.ratio,
    required this.passed,
  });

  /// Aciertos.
  final int correct;

  /// Ejercicios que sí contaron, es decir, el denominador.
  final int answered;

  /// Ejercicios excluidos por no poder intentarse.
  final int unavailable;

  /// Proporción de aciertos, de 0.0 a 1.0.
  final double ratio;

  /// Si alcanzó el umbral de su clase de actividad.
  final bool passed;

  /// Porcentaje redondeado, para mostrarlo.
  int get percentage => (ratio * 100).round();
}

/// Califica una actividad.
///
/// El umbral lo decide [kind]: 70 % una lección, 80 % un examen. Quien llama no
/// tiene que recordarlo.
ScoreResult scoreActivity({
  required List<ExerciseOutcome> outcomes,
  required ActivityKind kind,
}) {
  int correct = 0;
  int answered = 0;
  int unavailable = 0;

  for (final ExerciseOutcome outcome in outcomes) {
    switch (outcome) {
      case ExerciseOutcome.correct:
        correct++;
        answered++;
      case ExerciseOutcome.incorrect:
        answered++;
      case ExerciseOutcome.unavailable:
        unavailable++;
    }
  }

  // Si no quedó nada que contar, no hay nota que dar. Devolver 0 sin aprobar es
  // lo honesto: no se demostró dominio, pero tampoco se falló.
  final double ratio = answered == 0 ? 0 : correct / answered;

  return ScoreResult(
    correct: correct,
    answered: answered,
    unavailable: unavailable,
    ratio: ratio,
    passed: answered > 0 && ratio >= kind.passThreshold,
  );
}
