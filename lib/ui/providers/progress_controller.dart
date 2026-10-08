/// El progreso del estudiante, leído del almacén y escrito por el motor.
///
/// Es la costura que une las tres capas sin que ninguna sepa de las otras:
///
/// * El **motor** decide qué cambia. `recordActivity` y `applyPlacement` son
///   funciones puras que reciben un progreso y devuelven otro.
/// * El **almacén** persiste. Una sola llamada, una sola transacción.
/// * La **sincronización** se pide después, nunca antes, y nunca bloquea.
///
/// El orden importa y no es negociable: primero se guarda en local, después se
/// pide sincronizar. Al revés, un empujón que falla dejaría la lección aprobada
/// solo en memoria, y cerrar la app la perdería. El almacén local es la fuente
/// de verdad (FR-039); la nube es respaldo y segundo dispositivo.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/activity_score.dart';
import '../../core/clock.dart';
import '../../core/course.dart';
import '../../core/placement_result.dart';
import '../../core/student_progress.dart';
import '../../engine/placement_evaluator.dart';
import '../../engine/progress_recorder.dart';
import '../../engine/scoring.dart';
import '../../services/sync/sync_scheduler.dart';
import 'clock_providers.dart';
import 'content_providers.dart';
import 'progress_providers.dart';
import 'scope_providers.dart';

class StudentProgressController extends AsyncNotifier<StudentProgress?> {
  @override
  Future<StudentProgress?> build() async {
    final StudentScope? scope = await watchStudentScope(ref);
    if (scope == null) return null;

    final StudentProgress? stored = await ref
        .read(progressStoreProvider)
        .load(uid: scope.uid, courseId: scope.courseId);
    if (stored != null) return stored;

    // Primer arranque en este curso. Se crea y se guarda de inmediato en lugar
    // de dejarlo en memoria: si no, el primer nivel aparecería abierto y al
    // cerrar la app volvería a estar bloqueado.
    final Course? course = ref.read(activeCourseProvider);
    if (course == null) return null;

    final StudentProgress fresh = StudentProgress.initial(
      uid: scope.uid,
      courseId: scope.courseId,
      firstLevelId: course.levels.first.id,
    );
    await ref.read(progressStoreProvider).save(fresh);
    return fresh;
  }

  /// Registra una lección o un examen terminados.
  ///
  /// Devuelve lo que cambió, para que la pantalla pueda decir «+20 XP» o «racha
  /// de 4 días» sin recalcularlo por su cuenta y llegar a otro número.
  Future<RecordedActivity?> recordResult({
    required String activityId,
    required ActivityKind kind,
    required ScoreResult result,
  }) async {
    final StudentProgress? current = state.value;
    if (current == null) return null;

    final Clock clock = ref.read(clockProvider);
    final RecordedActivity recorded = recordActivity(
      progress: current,
      activityId: activityId,
      kind: kind,
      result: result,
      clock: clock,
    );

    await _persist(recorded.progress, SyncTrigger.activityFinished);
    return recorded;
  }

  /// Aplica el resultado de la nivelación, o el de haberla omitido.
  Future<void> applyPlacementResult(PlacementResult result) async {
    final StudentProgress? current = state.value;
    final Course? course = ref.read(activeCourseProvider);
    if (current == null || course == null) return;

    await _persist(
      applyPlacement(progress: current, course: course, result: result),
      SyncTrigger.activityFinished,
    );
  }

  /// Adopta un progreso que ya viene fusionado, sin volver a escribirlo.
  ///
  /// Lo usa la sincronización después de guardar lo fusionado: si en su lugar
  /// llamara a [_persist], cada empujón provocaría otro empujón.
  void adopt(StudentProgress merged) =>
      state = AsyncValue<StudentProgress>.data(merged);

  Future<void> _persist(StudentProgress next, SyncTrigger trigger) async {
    // Local primero, y el estado de la interfaz con él: si la escritura falla,
    // la pantalla no debe mostrar un avance que no existe en disco.
    await ref.read(progressStoreProvider).save(next);
    state = AsyncValue<StudentProgress>.data(next);

    // `request` no lanza nunca, así que no hace falta envolverlo: un fallo de
    // red queda en `SyncService.syncStatus`, que es lo que observa el aviso de
    // la pantalla (FR-043).
    await ref.read(syncSchedulerProvider).request(trigger);
  }
}

final AsyncNotifierProvider<StudentProgressController, StudentProgress?>
studentProgressProvider =
    AsyncNotifierProvider<StudentProgressController, StudentProgress?>(
      StudentProgressController.new,
    );
