/// Fusión del progreso entre dos dispositivos.
///
/// Es la pieza de la que depende FR-042 y SC-005: **fusionar nunca puede quitarle
/// avance a nadie.**
///
/// Toda regla es un máximo sobre un orden total o una unión de conjuntos, lo que
/// convierte el progreso en un *join-semilattice*. De ahí se siguen tres
/// propiedades que `progress_merger_test.dart` verifica directamente:
///
/// * **conmutativa** — da igual qué dispositivo sincronice primero;
/// * **asociativa** — tres o más dispositivos convergen igual;
/// * **idempotente** — sincronizar dos veces no cambia nada.
///
/// ## La racha y el par (fecha, racha)
///
/// La racha es el único campo que **no** se puede fusionar por máximo a secas.
/// Racha 7 con última actividad el lunes, fusionada con racha 1 del jueves,
/// daría «siete días seguidos» a quien no estudió el martes ni el miércoles, lo
/// que incumple FR-032 de forma visible.
///
/// La solución no es un recálculo posterior —eso rompe la asociatividad, y el
/// contraejemplo está escrito en `streak_tracker.dart`— sino tratar la racha y su
/// fecha como **una sola unidad**: gana la del dispositivo que estudió más
/// recientemente, y en empate de fecha, la racha mayor.
///
/// Eso sigue siendo un máximo, ahora sobre el orden lexicográfico
/// `(lastActivityDate, streakCount)`, así que conserva las tres propiedades y
/// además respeta FR-032: una racha caducada no revive.
library;

import '../core/activity_score.dart';
import '../core/level_state.dart';
import '../core/placement_result.dart';
import '../core/review_card.dart';
import '../core/student_progress.dart';
import '../core/thresholds.dart';
import 'streak_tracker.dart';

/// Fusiona dos estados del progreso del mismo estudiante en el mismo curso.
///
/// `syncState` no se fusiona: describe la relación de un dispositivo concreto con
/// la nube, así que el resultado conserva el de [local].
StudentProgress mergeProgress(StudentProgress local, StudentProgress remote) {
  assert(
    local.uid == remote.uid && local.courseId == remote.courseId,
    'Solo se fusiona el progreso del mismo estudiante en el mismo curso',
  );

  final StreakPoint streak = mergeStreak(
    StreakPoint(date: local.lastActivityDate, count: local.streakCount),
    StreakPoint(date: remote.lastActivityDate, count: remote.streakCount),
  );

  return StudentProgress(
    uid: local.uid,
    courseId: local.courseId,
    schemaVersion: _maxInt(local.schemaVersion, remote.schemaVersion),
    currentLevelId: _moreAdvancedLevel(
      local.currentLevelId,
      remote.currentLevelId,
    ),
    xp: _maxInt(local.xp, remote.xp),
    streakCount: streak.count,
    lastActivityDate: streak.date,
    levelStates: _mergeMap<LevelState>(
      local.levelStates,
      remote.levelStates,
      LevelState.merge,
    ),
    activityScores: _mergeMap<ActivityScore>(
      local.activityScores,
      remote.activityScores,
      (ActivityScore a, ActivityScore b) => a.mergeWith(b),
    ),
    reviewCards: _mergeMap<ReviewCard>(
      local.reviewCards,
      remote.reviewCards,
      (ReviewCard a, ReviewCard b) => a.mergeWith(b),
    ),
    placement: PlacementResult.merge(local.placement, remote.placement),
    syncState: local.syncState,
  );
}

int _maxInt(int a, int b) => a >= b ? a : b;

/// El más avanzado de dos niveles del Marco Común Europeo.
///
/// Un identificador desconocido pierde: así, si una versión futura introdujera un
/// nivel nuevo y ese progreso llegara a una versión vieja de la app por
/// sincronización, el estudiante no quedaría apuntando a un nivel que esta
/// versión no sabe mostrar.
String _moreAdvancedLevel(String a, String b) {
  final int indexA = cefrLevelIds.indexOf(a);
  final int indexB = cefrLevelIds.indexOf(b);
  if (indexA < 0) return b;
  if (indexB < 0) return a;
  return indexA >= indexB ? a : b;
}

/// Une dos mapas aplicando [combine] a las claves que aparecen en ambos.
///
/// Las claves que solo están en uno pasan tal cual: la unión nunca pierde
/// entradas, que es la mitad de la garantía de no decrecimiento.
Map<String, T> _mergeMap<T>(
  Map<String, T> a,
  Map<String, T> b,
  T Function(T, T) combine,
) {
  final Map<String, T> result = <String, T>{...a};
  for (final MapEntry<String, T> entry in b.entries) {
    final T? existing = result[entry.key];
    result[entry.key] = existing == null
        ? entry.value
        : combine(existing, entry.value);
  }
  return Map<String, T>.unmodifiable(result);
}
