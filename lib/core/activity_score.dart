/// El mejor resultado de una actividad calificable.
///
/// "Actividad" cubre lecciones y exámenes porque las tres comparten la misma
/// regla: se conserva solo el mejor intento. Guardar únicamente el máximo es lo
/// que hace **imposible** que un reintento peor desapruebe algo ya aprobado
/// (FR-027). No es una comprobación en el código: es la forma del dato.
library;

import 'thresholds.dart';

/// Qué clase de actividad es.
///
/// El valor entero es el que se persiste, así que no se reordena: añadir una
/// clase nueva usa un número nuevo.
enum ActivityKind {
  lesson(0, lessonPassThreshold),
  moduleExam(1, examPassThreshold),
  levelExam(2, examPassThreshold);

  const ActivityKind(this.code, this.passThreshold);

  /// Valor persistido.
  final int code;

  /// Umbral de aprobación que le corresponde.
  ///
  /// Vive aquí para que preguntar "¿aprobó?" no obligue a quien llama a saber
  /// qué umbral aplica a qué clase de actividad.
  final double passThreshold;

  static ActivityKind fromCode(int code) => ActivityKind.values.firstWhere(
    (ActivityKind kind) => kind.code == code,
    orElse: () => ActivityKind.lesson,
  );
}

class ActivityScore {
  const ActivityScore({
    required this.kind,
    required this.bestScore,
    required this.lastAttemptAt,
    this.attempts = 1,
  });

  final ActivityKind kind;

  /// Proporción de aciertos del mejor intento, de 0.0 a 1.0.
  final double bestScore;

  final int attempts;
  final DateTime lastAttemptAt;

  /// Si el mejor intento alcanzó el umbral de esta clase de actividad.
  bool get isPassed => bestScore >= kind.passThreshold;

  /// Fusiona dos versiones del mismo resultado.
  ///
  /// El puntaje es el **máximo**; los intentos, el máximo también; la fecha, la
  /// más reciente. Nada puede decrecer, que es la invariante de la que depende
  /// FR-042.
  ActivityScore mergeWith(ActivityScore other) => ActivityScore(
    kind: kind,
    bestScore: bestScore >= other.bestScore ? bestScore : other.bestScore,
    attempts: attempts >= other.attempts ? attempts : other.attempts,
    lastAttemptAt: lastAttemptAt.isAfter(other.lastAttemptAt)
        ? lastAttemptAt
        : other.lastAttemptAt,
  );

  /// Registra un intento nuevo, conservando el mejor puntaje.
  ActivityScore withAttempt(double score, DateTime at) => ActivityScore(
    kind: kind,
    bestScore: score > bestScore ? score : bestScore,
    attempts: attempts + 1,
    lastAttemptAt: at,
  );
}
