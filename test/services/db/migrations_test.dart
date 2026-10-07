/// Verifica la infraestructura de migración **antes** de que haya una v2.
///
/// El Principio IV exige que ningún cambio de esquema borre progreso. Esta
/// prueba no convierte nada todavía —v1 es la primera versión— pero deja montado
/// y comprobado el mecanismo: abrir, poblar, cerrar, reabrir y confirmar que
/// nada se perdió.
///
/// El momento de construir el rescate no es cuando ya hay progreso de
/// estudiantes en juego. Cuando exista v2, esta prueba se extiende con el salto
/// real y el patrón ya está escrito.
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/services/db/app_database.dart';
import 'package:languages_app/services/db/progress_dao.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('languages_app_migration');
    dbFile = File('${tempDir.path}/progress.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  AppDatabase open() => AppDatabase.withExecutor(NativeDatabase(dbFile));

  /// El progreso de referencia con el que se comprueba que nada se pierde.
  StudentProgress sampleProgress() {
    final DateTime now = DateTime(2026, 10, 6, 9, 15);
    return StudentProgress(
      uid: 'u1',
      courseId: 'en',
      currentLevelId: 'A1',
      xp: 530,
      streakCount: 12,
      lastActivityDate: DateTime(2026, 10, 6),
      levelStates: const <String, LevelState>{'A1': LevelState.passed},
      activityScores: <String, ActivityScore>{
        'A1M1L1': ActivityScore(
          kind: ActivityKind.lesson,
          bestScore: 0.95,
          attempts: 3,
          lastAttemptAt: now,
        ),
        'A1EX': ActivityScore(
          kind: ActivityKind.levelExam,
          bestScore: 0.88,
          lastAttemptAt: now,
        ),
      },
      reviewCards: <String, ReviewCard>{
        'A1M1|neighbour': ReviewCard(
          moduleId: 'A1M1',
          term: 'neighbour',
          translation: 'el vecino / la vecina',
          intervalStep: 4,
          dueDate: DateTime(2026, 11, 10),
          lapses: 2,
        ),
      },
    );
  }

  test('onCreate registra la versión del esquema', () async {
    final AppDatabase db = open();
    await ProgressDao(db).load(uid: 'u1', courseId: 'en');

    final List<SchemaMetaRow> meta = await db.select(db.schemaMeta).get();
    expect(meta.single.version, 1);
    expect(
      meta.single.migratedAt,
      isNull,
      reason: 'Una base recién creada no ha migrado nada',
    );

    await db.close();
  });

  test('el progreso sobrevive a cerrar y reabrir la base', () async {
    final StudentProgress original = sampleProgress();

    final AppDatabase first = open();
    await ProgressDao(first).save(original);
    await first.close();

    final AppDatabase second = open();
    final StudentProgress? reloaded = await ProgressDao(
      second,
    ).load(uid: 'u1', courseId: 'en');

    // Nada de esto puede haber cambiado: es el avance del estudiante.
    expect(reloaded, isNotNull);
    expect(reloaded!.xp, original.xp);
    expect(reloaded.streakCount, original.streakCount);
    expect(reloaded.lastActivityDate, original.lastActivityDate);
    expect(reloaded.stateOf('A1'), LevelState.passed);
    expect(reloaded.scoreOf('A1M1L1')!.bestScore, closeTo(0.95, 1e-9));
    expect(reloaded.scoreOf('A1M1L1')!.attempts, 3);
    expect(reloaded.scoreOf('A1EX')!.kind, ActivityKind.levelExam);
    expect(reloaded.reviewCards['A1M1|neighbour']!.intervalStep, 4);
    expect(reloaded.reviewCards['A1M1|neighbour']!.lapses, 2);
    expect(
      reloaded.reviewCards['A1M1|neighbour']!.dueDate,
      DateTime(2026, 11, 10),
    );

    await second.close();
  });

  test('reabrir no vuelve a ejecutar onCreate ni duplica la fila de versión',
      () async {
    final AppDatabase first = open();
    await ProgressDao(first).save(sampleProgress());
    await first.close();

    final AppDatabase second = open();
    final List<SchemaMetaRow> meta = await second.select(second.schemaMeta).get();
    expect(meta, hasLength(1));
    await second.close();
  });

  test('las claves foráneas quedan activas al abrir', () async {
    // beforeOpen las enciende. Activarlas desde v1 evita que una versión futura
    // las añada y descubra datos ya inconsistentes.
    final AppDatabase db = open();
    final rows = await db.customSelect('PRAGMA foreign_keys').get();
    expect(rows.single.data.values.first, 1);
    await db.close();
  });
}
