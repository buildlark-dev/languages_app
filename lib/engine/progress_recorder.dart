/// Aplica el resultado de una actividad al progreso del estudiante.
///
/// Es una función **pura**: recibe el progreso y devuelve el nuevo, sin tocar el
/// almacén. Quien persiste es `ProgressDao.save`, que escribe todo en **una**
/// transacción.
///
/// Ese reparto importa. La decisión de qué cambia —mejor puntaje, XP ganado,
/// racha, fecha de actividad— es lógica de aprendizaje y se prueba sin base de
/// datos. La atomicidad es responsabilidad del almacén. Mezclarlas obligaría a
/// montar SQLite para comprobar que un reintento peor no baja la nota.
library;

import '../core/activity_score.dart';
import '../core/clock.dart';
import '../core/student_progress.dart';
import 'scoring.dart';
import 'xp_calculator.dart';

/// Lo que cambió al registrar una actividad.
class RecordedActivity {
  const RecordedActivity({
    required this.progress,
    required this.xpGained,
    required this.streakIncreased,
  });

  /// El progreso resultante, listo para guardar.
  final StudentProgress progress;

  /// XP que esta actividad añadió de verdad. Cero al repetir sin mejorar.
  final int xpGained;

  /// Si la racha subió con esta actividad.
  final bool streakIncreased;
}

/// Registra el resultado de una actividad completada.
///
/// Garantías, todas verificadas en `progress_recorder_test.dart`:
///
/// * Solo se conserva el **mejor** puntaje, así que un reintento peor no puede
///   desaprobar algo ya aprobado (FR-027).
/// * El XP solo premia la **mejora**, de modo que repetir una lección fácil no es
///   una máquina infinita de puntos.
/// * La racha sube **una sola vez al día**, y se reinicia si pasó un día completo
///   sin actividad (FR-032).
RecordedActivity recordActivity({
  required StudentProgress progress,
  required String activityId,
  required ActivityKind kind,
  required ScoreResult result,
  required Clock clock,
}) {
  final DateTime now = clock();
  final DateTime today = dateOnly(now);

  final ActivityScore? previous = progress.activityScores[activityId];
  final double? previousBest = previous?.bestScore;

  final ActivityScore updated = previous == null
      ? ActivityScore(kind: kind, bestScore: result.ratio, lastAttemptAt: now)
      : previous.withAttempt(result.ratio, now);

  final int xpGained = xpGainForAttempt(
    result: result,
    kind: kind,
    previousBest: previousBest,
  );

  final (int streak, bool increased) = _advanceStreak(
    current: progress.streakCount,
    lastActivity: progress.lastActivityDate,
    today: today,
  );

  return RecordedActivity(
    progress: progress.copyWith(
      activityScores: <String, ActivityScore>{
        ...progress.activityScores,
        activityId: updated,
      },
      xp: progress.xp + xpGained,
      streakCount: streak,
      lastActivityDate: today,
    ),
    xpGained: xpGained,
    streakIncreased: increased,
  );
}

/// Avanza la racha según cuándo fue la última actividad.
(int, bool) _advanceStreak({
  required int current,
  required DateTime? lastActivity,
  required DateTime today,
}) {
  if (lastActivity == null) return (1, true);

  final int gap = daysBetween(lastActivity, today);

  // Mismo día: la racha ya está contada. Completar una segunda lección no la
  // incrementa dos veces.
  if (gap == 0) return (current == 0 ? 1 : current, false);

  // Día consecutivo: sube.
  if (gap == 1) return (current + 1, true);

  // Pasó un día completo sin estudiar: vuelve a empezar.
  return (1, true);
}
