/// Verifica que aprobar un examen de nivel se persiste **en una sola
/// transacción**, con el nivel superado y el siguiente desbloqueado a la vez.
///
/// Sin atomicidad, un corte dejaría «A1 superado» sin «A2 desbloqueado», y el
/// estudiante aprobaría el nivel para quedarse sin nada que estudiar.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/course.dart';
import 'package:languages_app/core/exam.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/core/lesson.dart';
import 'package:languages_app/core/level.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/module.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/core/teaching_material.dart';
import 'package:languages_app/core/vocabulary_item.dart';
import 'package:languages_app/engine/progress_recorder.dart';
import 'package:languages_app/engine/progression.dart';
import 'package:languages_app/engine/scoring.dart';
import 'package:languages_app/services/db/app_database.dart';
import 'package:languages_app/services/db/progress_dao.dart';

/// Curso con **dos** niveles con contenido, para poder comprobar el desbloqueo.
///
/// El curso real solo tiene A1, así que A2 está únicamente anunciado y no se
/// desbloquea nunca. Aquí hace falta un segundo nivel con contenido para
/// ejercitar la ruta que se usará cuando A2 exista.
Module tinyModule(String id, int order) => Module(
  id: id,
  order: order,
  title: 'Módulo $id',
  canDo: 'Hacer algo.',
  vocabulary: const <VocabularyItem>[
    VocabularyItem(term: 'one', translation: 'uno'),
  ],
  grammar: const GrammarExplanation(title: 'T', bodyHtml: '<p>T</p>'),
  examples: const <BilingualExample>[
    BilingualExample(target: 'One.', spanish: 'Uno.'),
  ],
  reading: ReadingPassage(
    id: '${id}R',
    title: 'R',
    paragraphs: const <String>['Texto.'],
  ),
  lessons: const <Lesson>[],
  moduleExam: Exam(
    id: '${id}EX',
    scope: ExamScope.module,
    exercises: const <Exercise>[],
  ),
);

Level tinyLevel(String id) => Level(
  id: id,
  name: '$id · Prueba',
  description: 'Nivel $id.',
  modules: <Module>[tinyModule('${id}M1', 1)],
  levelExam: Exam(
    id: '${id}EX',
    scope: ExamScope.level,
    exercises: const <Exercise>[],
  ),
);

final Course twoLevelCourse = Course(
  id: 'xx',
  name: 'Curso de prueba',
  studyLanguageTag: 'xx-XX',
  supportLanguageTag: 'es',
  levels: <Level>[tinyLevel('A1'), tinyLevel('A2')],
  upcomingLevelIds: const <String>['B1'],
);

void main() {
  late AppDatabase db;
  late ProgressDao dao;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = ProgressDao(db);
  });

  tearDown(() => db.close());

  test(
    'aprobar el examen de nivel persiste el superado y el desbloqueo juntos',
    () async {
      final Level a1 = twoLevelCourse.levels.first;

      StudentProgress progress = StudentProgress(
        uid: 'u1',
        courseId: 'xx',
        currentLevelId: 'A1',
        levelStates: const <String, LevelState>{'A1': LevelState.unlocked},
        activityScores: <String, ActivityScore>{
          'A1M1EX': ActivityScore(
            kind: ActivityKind.moduleExam,
            bestScore: 0.9,
            lastAttemptAt: DateTime(2026, 10, 6),
          ),
        },
      );

      // Registrar el resultado del examen de nivel y aplicar la progresión.
      progress = recordActivity(
        progress: progress,
        activityId: a1.levelExam.id,
        kind: ActivityKind.levelExam,
        result: const ScoreResult(
          correct: 9,
          answered: 10,
          unavailable: 0,
          ratio: 0.9,
          passed: true,
        ),
        clock: fixedClock(DateTime(2026, 10, 7)),
      ).progress;

      progress = applyLevelExamPassed(
        course: twoLevelCourse,
        progress: progress,
        level: a1,
      );

      // Una sola llamada, una sola transacción.
      await dao.save(progress);

      final StudentProgress? loaded = await dao.load(uid: 'u1', courseId: 'xx');
      expect(loaded, isNotNull);
      expect(loaded!.stateOf('A1'), LevelState.passed);
      expect(loaded.stateOf('A2'), LevelState.unlocked);
      expect(loaded.currentLevelId, 'A2');
      expect(loaded.hasPassed(a1.levelExam.id), isTrue);
    },
  );

  test('un corte durante la escritura no deja el nivel a medias', () async {
    final Level a1 = twoLevelCourse.levels.first;
    final StudentProgress progress = applyLevelExamPassed(
      course: twoLevelCourse,
      progress: const StudentProgress(
        uid: 'u1',
        courseId: 'xx',
        currentLevelId: 'A1',
        levelStates: <String, LevelState>{'A1': LevelState.unlocked},
      ),
      level: a1,
    );

    await expectLater(
      () => db.transaction(() async {
        await dao.save(progress);
        throw StateError('corte');
      }),
      throwsA(isA<StateError>()),
    );

    // Lo que se evita: «A1 superado» sin «A2 desbloqueado».
    expect(await dao.load(uid: 'u1', courseId: 'xx'), isNull);
  });

  test('un nivel solo anunciado no se persiste como desbloqueado', () async {
    final Level a2 = twoLevelCourse.levels.last;
    final StudentProgress progress = applyLevelExamPassed(
      course: twoLevelCourse,
      progress: const StudentProgress(
        uid: 'u1',
        courseId: 'xx',
        currentLevelId: 'A2',
        levelStates: <String, LevelState>{'A2': LevelState.unlocked},
      ),
      level: a2,
    );

    await dao.save(progress);
    final StudentProgress? loaded = await dao.load(uid: 'u1', courseId: 'xx');

    expect(loaded!.stateOf('A2'), LevelState.passed);
    // B1 está solo anunciado: no hay Level, así que no hay nada que desbloquear.
    expect(loaded.stateOf('B1'), LevelState.locked);
    expect(loaded.levelStates.containsKey('B1'), isFalse);
  });
}
