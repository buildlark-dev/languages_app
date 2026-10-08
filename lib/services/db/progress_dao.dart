/// Lectura y escritura del progreso completo de un estudiante.
///
/// Toda escritura va en **una** transacción. Aprobar una lección toca tres
/// tablas, y un corte a mitad dejaría estados imposibles: XP sumado sin la
/// lección aprobada, o un módulo aprobado sin desbloquear el siguiente.
library;

import 'package:drift/drift.dart';

import '../../core/activity_score.dart';
import '../../core/level_state.dart';
import '../../core/placement_result.dart';
import '../../core/review_card.dart';
import '../../core/student_progress.dart';
import 'app_database.dart';

class ProgressDao {
  ProgressDao(this._db);

  final AppDatabase _db;

  /// Carga el progreso completo, o nulo si el estudiante no tiene nada guardado.
  Future<StudentProgress?> load({
    required String uid,
    required String courseId,
  }) async {
    final StudentProfileRow? profile =
        await (_db.select(_db.studentProfile)
              ..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId)))
            .getSingleOrNull();

    if (profile == null) return null;

    final List<LevelProgressRow> levels = await (_db.select(
      _db.levelProgress,
    )..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId))).get();

    final List<ActivityResultRow> activities = await (_db.select(
      _db.activityResults,
    )..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId))).get();

    final List<ReviewCardRow> cards = await (_db.select(
      _db.reviewCards,
    )..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId))).get();

    final PlacementResultRow? placement =
        await (_db.select(_db.placementResults)
              ..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId)))
            .getSingleOrNull();

    return StudentProgress(
      uid: uid,
      courseId: courseId,
      currentLevelId: profile.currentLevelId,
      xp: profile.xp,
      streakCount: profile.streakCount,
      lastActivityDate: profile.lastActivityDate,
      levelStates: <String, LevelState>{
        for (final LevelProgressRow row in levels)
          row.levelId: LevelState.fromRank(row.state),
      },
      activityScores: <String, ActivityScore>{
        for (final ActivityResultRow row in activities)
          row.activityId: ActivityScore(
            kind: ActivityKind.fromCode(row.activityKind),
            bestScore: row.bestScore,
            attempts: row.attempts,
            lastAttemptAt: row.lastAttemptAt,
          ),
      },
      reviewCards: <String, ReviewCard>{
        for (final ReviewCardRow row in cards)
          '${row.moduleId}|${row.term}': ReviewCard(
            moduleId: row.moduleId,
            term: row.term,
            translation: row.translation,
            intervalStep: row.intervalStep,
            dueDate: row.dueDate,
            lapses: row.lapses,
          ),
      },
      placement: placement == null
          ? null
          : PlacementResult(
              estimatedLevelId: placement.estimatedLevelId,
              masteredLevelIds: _splitLevelIds(placement.masteredLevelIds),
              takenAt: placement.takenAt,
              skipped: placement.skipped,
            ),
    );
  }

  /// Guarda el progreso completo en una sola transacción.
  ///
  /// `insertOnConflictUpdate` hace la escritura idempotente: guardar dos veces el
  /// mismo estado no duplica filas ni falla, lo que importa porque la
  /// sincronización puede reescribir el mismo progreso más de una vez.
  Future<void> save(StudentProgress progress) async {
    await _db.transaction(() async {
      await _db
          .into(_db.studentProfile)
          .insertOnConflictUpdate(
            StudentProfileRow(
              uid: progress.uid,
              courseId: progress.courseId,
              currentLevelId: progress.currentLevelId,
              xp: progress.xp,
              streakCount: progress.streakCount,
              lastActivityDate: progress.lastActivityDate,
            ),
          );

      for (final MapEntry<String, LevelState> entry
          in progress.levelStates.entries) {
        await _db
            .into(_db.levelProgress)
            .insertOnConflictUpdate(
              LevelProgressRow(
                uid: progress.uid,
                courseId: progress.courseId,
                levelId: entry.key,
                state: entry.value.rank,
              ),
            );
      }

      for (final MapEntry<String, ActivityScore> entry
          in progress.activityScores.entries) {
        await _db
            .into(_db.activityResults)
            .insertOnConflictUpdate(
              ActivityResultRow(
                uid: progress.uid,
                courseId: progress.courseId,
                activityId: entry.key,
                activityKind: entry.value.kind.code,
                bestScore: entry.value.bestScore,
                attempts: entry.value.attempts,
                lastAttemptAt: entry.value.lastAttemptAt,
              ),
            );
      }

      // Las tarjetas de repaso se **fusionan**, no se sobrescriben.
      //
      // El resto del progreso vive en memoria y se guarda entero, pero la cola
      // de repaso no: `ReviewDao` la escribe por su cuenta cada vez que se
      // califica una tarjeta, y el progreso en memoria conserva la instantánea
      // que se cargó al arrancar. Con `insertOnConflictUpdate` a secas,
      // calificar una tarjeta y terminar después cualquier lección devolvía esa
      // tarjeta a su intervalo anterior: el repaso se deshacía solo.
      //
      // La regla de esta frontera **no** es la de `ReviewCard.mergeWith`, y la
      // diferencia importa. Esa fusiona dos dispositivos, donde ambas fechas
      // son legítimas y conviene quedarse con la más próxima. Aquí uno de los
      // dos lados es una instantánea caducada del **mismo** dispositivo, y
      // quedarse con su fecha es un retroceso disfrazado de fusión: el
      // intervalo sobreviviría y la palabra volvería a vencer hoy igualmente.
      //
      // Por eso: si los pasos difieren, gana entera la tarjeta más avanzada,
      // con su fecha. Si coinciden —que es el caso real cuando la nube trae
      // algo tras pasar por `mergeProgress`— se aplica `mergeWith`, y entonces
      // sí gana la fecha más próxima.
      for (final ReviewCard card in progress.reviewCards.values) {
        final ReviewCardRow? existing =
            await (_db.select(_db.reviewCards)..where(
                  (t) =>
                      t.uid.equals(progress.uid) &
                      t.courseId.equals(progress.courseId) &
                      t.moduleId.equals(card.moduleId) &
                      t.term.equals(card.term),
                ))
                .getSingleOrNull();

        final ReviewCard merged = existing == null
            ? card
            : _reconcile(
                incoming: card,
                stored: ReviewCard(
                  moduleId: existing.moduleId,
                  term: existing.term,
                  translation: existing.translation,
                  intervalStep: existing.intervalStep,
                  dueDate: existing.dueDate,
                  lapses: existing.lapses,
                ),
              );

        await _db
            .into(_db.reviewCards)
            .insertOnConflictUpdate(
              ReviewCardRow(
                uid: progress.uid,
                courseId: progress.courseId,
                moduleId: merged.moduleId,
                term: merged.term,
                translation: merged.translation,
                intervalStep: merged.intervalStep,
                dueDate: merged.dueDate,
                lapses: merged.lapses,
              ),
            );
      }

      final PlacementResult? placement = progress.placement;
      if (placement != null) {
        await _db
            .into(_db.placementResults)
            .insertOnConflictUpdate(
              PlacementResultRow(
                uid: progress.uid,
                courseId: progress.courseId,
                estimatedLevelId: placement.estimatedLevelId,
                masteredLevelIds: placement.masteredLevelIds.join(','),
                skipped: placement.skipped,
                takenAt: placement.takenAt,
              ),
            );
      }
    });
  }

  /// Borra todo el progreso de un estudiante en un curso.
  ///
  /// El servicio no pregunta nada: la confirmación explícita que exige FR-046 es
  /// responsabilidad de la interfaz.
  Future<void> wipe({required String uid, required String courseId}) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.reviewCards,
      )..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId))).go();
      await (_db.delete(
        _db.activityResults,
      )..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId))).go();
      await (_db.delete(
        _db.levelProgress,
      )..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId))).go();
      await (_db.delete(
        _db.placementResults,
      )..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId))).go();
      await (_db.delete(
        _db.studentProfile,
      )..where((t) => t.uid.equals(uid) & t.courseId.equals(courseId))).go();
    });
  }

  static List<String> _splitLevelIds(String raw) => raw.isEmpty
      ? const <String>[]
      : raw
            .split(',')
            .where((String s) => s.isNotEmpty)
            .toList(growable: false);
}

/// Reconcilia la tarjeta que trae el progreso con la que ya está guardada.
///
/// Ver el comentario de `ProgressDao.save`: con pasos distintos gana entera la
/// más avanzada, porque el lado menos avanzado suele ser una instantánea
/// caducada del mismo dispositivo; con pasos iguales se aplica la fusión normal
/// entre dispositivos, que adelanta la fecha.
ReviewCard _reconcile({
  required ReviewCard incoming,
  required ReviewCard stored,
}) {
  if (incoming.intervalStep > stored.intervalStep) return incoming;
  if (stored.intervalStep > incoming.intervalStep) return stored;
  return incoming.mergeWith(stored);
}
