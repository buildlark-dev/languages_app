/// Verifica que el progreso sobrevive, que es la promesa del Principio IV.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/placement_result.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/services/db/app_database.dart';
import 'package:languages_app/services/db/progress_dao.dart';

void main() {
  late AppDatabase db;
  late ProgressDao dao;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = ProgressDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('el esquema nace en la versión 1 y la registra', () async {
    // Forzar la apertura con cualquier consulta.
    await dao.load(uid: 'u1', courseId: 'en');

    final List<SchemaMetaRow> meta = await db.select(db.schemaMeta).get();
    expect(meta, hasLength(1));
    expect(meta.single.version, appSchemaVersion);
    expect(meta.single.version, 1);
  });

  test('un estudiante sin progreso devuelve null, no un objeto vacío', () async {
    expect(await dao.load(uid: 'u1', courseId: 'en'), isNull);
  });

  test('el progreso completo sobrevive a una ida y vuelta', () async {
    final DateTime now = DateTime(2026, 10, 6, 14, 30);
    final StudentProgress original = StudentProgress(
      uid: 'u1',
      courseId: 'en',
      currentLevelId: 'A1',
      xp: 240,
      streakCount: 7,
      lastActivityDate: DateTime(2026, 10, 6),
      levelStates: const <String, LevelState>{
        'A1': LevelState.unlocked,
        'A2': LevelState.locked,
      },
      activityScores: <String, ActivityScore>{
        'A1M1L1': ActivityScore(
          kind: ActivityKind.lesson,
          bestScore: 0.85,
          attempts: 2,
          lastAttemptAt: now,
        ),
        'A1M1EX': ActivityScore(
          kind: ActivityKind.moduleExam,
          bestScore: 0.9,
          lastAttemptAt: now,
        ),
      },
      reviewCards: <String, ReviewCard>{
        'A1M1|name': ReviewCard(
          moduleId: 'A1M1',
          term: 'name',
          translation: 'el nombre',
          intervalStep: 2,
          dueDate: DateTime(2026, 10, 13),
          lapses: 1,
        ),
      },
      placement: PlacementResult(
        estimatedLevelId: 'B1',
        masteredLevelIds: const <String>['A1'],
        takenAt: now,
      ),
    );

    await dao.save(original);
    final StudentProgress? loaded = await dao.load(uid: 'u1', courseId: 'en');

    expect(loaded, isNotNull);
    expect(loaded!.xp, 240);
    expect(loaded.streakCount, 7);
    expect(loaded.currentLevelId, 'A1');
    expect(loaded.stateOf('A1'), LevelState.unlocked);
    expect(loaded.stateOf('A2'), LevelState.locked);

    // El tipo de actividad viaja, no solo el puntaje: de él depende el umbral.
    expect(loaded.scoreOf('A1M1L1')!.kind, ActivityKind.lesson);
    expect(loaded.scoreOf('A1M1L1')!.bestScore, closeTo(0.85, 1e-9));
    expect(loaded.scoreOf('A1M1L1')!.attempts, 2);
    expect(loaded.scoreOf('A1M1EX')!.kind, ActivityKind.moduleExam);

    final ReviewCard card = loaded.reviewCards['A1M1|name']!;
    expect(card.intervalStep, 2);
    expect(card.lapses, 1);
    expect(card.dueDate, DateTime(2026, 10, 13));

    expect(loaded.placement!.estimatedLevelId, 'B1');
    expect(loaded.placement!.masteredLevelIds, <String>['A1']);
  });

  test('guardar dos veces el mismo progreso es idempotente', () async {
    final StudentProgress progress = StudentProgress.initial(
      uid: 'u1',
      courseId: 'en',
      firstLevelId: 'A1',
    );

    await dao.save(progress);
    await dao.save(progress);

    final List<LevelProgressRow> levels = await db
        .select(db.levelProgress)
        .get();
    expect(levels, hasLength(1), reason: 'No debe duplicar filas');
  });

  test('un reintento peor no baja el mejor puntaje guardado', () async {
    final DateTime now = DateTime(2026, 10, 6);
    final ActivityScore good = ActivityScore(
      kind: ActivityKind.lesson,
      bestScore: 0.9,
      lastAttemptAt: now,
    );

    // La regla vive en el modelo, no en la base: el dato guardado ya es el
    // máximo, así que no existe forma de escribir un valor peor por descuido.
    final ActivityScore afterWorseAttempt = good.withAttempt(0.4, now);
    expect(afterWorseAttempt.bestScore, closeTo(0.9, 1e-9));
    expect(afterWorseAttempt.attempts, 2);
    expect(afterWorseAttempt.isPassed, isTrue);
  });

  test('borrar el progreso lo elimina de todas las tablas', () async {
    final DateTime now = DateTime(2026, 10, 6);
    await dao.save(
      StudentProgress(
        uid: 'u1',
        courseId: 'en',
        currentLevelId: 'A1',
        levelStates: const <String, LevelState>{'A1': LevelState.unlocked},
        activityScores: <String, ActivityScore>{
          'A1M1L1': ActivityScore(
            kind: ActivityKind.lesson,
            bestScore: 0.8,
            lastAttemptAt: now,
          ),
        },
        reviewCards: <String, ReviewCard>{
          'A1M1|name': ReviewCard(
            moduleId: 'A1M1',
            term: 'name',
            translation: 'el nombre',
            intervalStep: 0,
            dueDate: now,
          ),
        },
        placement: PlacementResult.skippedAt(now),
      ),
    );

    await dao.wipe(uid: 'u1', courseId: 'en');

    expect(await dao.load(uid: 'u1', courseId: 'en'), isNull);
    expect(await db.select(db.reviewCards).get(), isEmpty);
    expect(await db.select(db.activityResults).get(), isEmpty);
    expect(await db.select(db.levelProgress).get(), isEmpty);
    expect(await db.select(db.placementResults).get(), isEmpty);
  });

  test('el progreso de dos cursos no se mezcla', () async {
    await dao.save(
      StudentProgress.initial(uid: 'u1', courseId: 'en', firstLevelId: 'A1'),
    );
    await dao.save(
      StudentProgress.initial(uid: 'u1', courseId: 'fr', firstLevelId: 'A1'),
    );

    await dao.wipe(uid: 'u1', courseId: 'en');

    expect(await dao.load(uid: 'u1', courseId: 'en'), isNull);
    expect(
      await dao.load(uid: 'u1', courseId: 'fr'),
      isNotNull,
      reason: 'La clave compuesta debe aislar los cursos',
    );
  });
}
