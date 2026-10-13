/// Verifica las puertas de la progresión y la matriz completa de transiciones.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/content/en/english_course.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/course.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/module.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/engine/progression.dart';

const Course course = englishCourse;

ActivityScore passed() => ActivityScore(
  kind: ActivityKind.moduleExam,
  bestScore: 0.9,
  lastAttemptAt: DateTime(2026, 10, 6),
);

ActivityScore failed() => ActivityScore(
  kind: ActivityKind.moduleExam,
  bestScore: 0.5,
  lastAttemptAt: DateTime(2026, 10, 6),
);

StudentProgress withState(
  LevelState a1, {
  Map<String, ActivityScore> scores = const <String, ActivityScore>{},
}) => StudentProgress(
  uid: 'u1',
  courseId: 'en',
  currentLevelId: 'A1',
  levelStates: <String, LevelState>{'A1': a1},
  activityScores: scores,
);

Module moduleAt(int index) => course.levels.single.modules[index];

void main() {
  group('disponibilidad de módulos', () {
    test('con A1 bloqueado, ningún módulo está disponible', () {
      final StudentProgress p = withState(LevelState.locked);
      for (final Module m in course.levels.single.modules) {
        expect(
          moduleAvailability(course: course, progress: p, module: m),
          ModuleAvailability.locked,
          reason: m.id,
        );
      }
    });

    test('con A1 desbloqueado, solo el primer módulo está disponible', () {
      final StudentProgress p = withState(LevelState.unlocked);

      expect(
        moduleAvailability(course: course, progress: p, module: moduleAt(0)),
        ModuleAvailability.available,
      );
      for (int i = 1; i < 4; i++) {
        expect(
          moduleAvailability(course: course, progress: p, module: moduleAt(i)),
          ModuleAvailability.locked,
          reason: 'Módulo ${i + 1}',
        );
      }
    });

    test('aprobar un módulo abre el siguiente, y solo el siguiente', () {
      final StudentProgress p = withState(
        LevelState.unlocked,
        scores: <String, ActivityScore>{moduleAt(0).moduleExam.id: passed()},
      );

      expect(
        moduleAvailability(course: course, progress: p, module: moduleAt(0)),
        ModuleAvailability.passed,
      );
      expect(
        moduleAvailability(course: course, progress: p, module: moduleAt(1)),
        ModuleAvailability.available,
      );
      expect(
        moduleAvailability(course: course, progress: p, module: moduleAt(2)),
        ModuleAvailability.locked,
      );
    });

    test('suspender el examen de módulo NO abre el siguiente', () {
      final StudentProgress p = withState(
        LevelState.unlocked,
        scores: <String, ActivityScore>{moduleAt(0).moduleExam.id: failed()},
      );

      expect(
        moduleAvailability(course: course, progress: p, module: moduleAt(1)),
        ModuleAvailability.locked,
      );
    });

    test('un nivel dominado por nivelación abre todos sus módulos', () {
      // No tiene sentido pedirle a quien ya demostró el nivel que lo recorra en
      // orden; lo abre completo para repaso.
      final StudentProgress p = withState(LevelState.mastered);
      for (final Module m in course.levels.single.modules) {
        expect(
          moduleAvailability(course: course, progress: p, module: m),
          ModuleAvailability.available,
          reason: m.id,
        );
      }
    });
  });

  group('el motivo del bloqueo se puede explicar', () {
    test('el segundo módulo señala el módulo que falta', () {
      final StudentProgress p = withState(LevelState.unlocked);
      final LockReason? reason = lockReasonFor(
        course: course,
        progress: p,
        module: moduleAt(1),
      );

      expect(reason, isNotNull);
      expect(reason!.moduleTitle, moduleAt(0).title);
    });

    test('con el nivel bloqueado, señala el nivel', () {
      final StudentProgress p = withState(LevelState.locked);
      final LockReason? reason = lockReasonFor(
        course: course,
        progress: p,
        module: moduleAt(0),
      );

      expect(reason, isNotNull);
      expect(reason!.levelName, isNotNull);
    });

    test('un módulo disponible no tiene motivo de bloqueo', () {
      final StudentProgress p = withState(LevelState.unlocked);
      expect(
        lockReasonFor(course: course, progress: p, module: moduleAt(0)),
        isNull,
      );
    });
  });

  group('examen de nivel', () {
    test('no está disponible hasta aprobar los CUATRO módulos', () {
      Map<String, ActivityScore> scores = <String, ActivityScore>{};
      for (int i = 0; i < 4; i++) {
        expect(
          isLevelExamAvailable(
            progress: withState(LevelState.unlocked, scores: scores),
            level: course.levels.single,
          ),
          isFalse,
          reason: 'Con $i módulos aprobados no debería estar disponible',
        );
        scores = <String, ActivityScore>{
          ...scores,
          moduleAt(i).moduleExam.id: passed(),
        };
      }

      expect(
        isLevelExamAvailable(
          progress: withState(LevelState.unlocked, scores: scores),
          level: course.levels.single,
        ),
        isTrue,
      );
    });

    test('el avance del nivel refleja los módulos aprobados', () {
      final StudentProgress p = withState(
        LevelState.unlocked,
        scores: <String, ActivityScore>{
          moduleAt(0).moduleExam.id: passed(),
          moduleAt(1).moduleExam.id: passed(),
        },
      );

      expect(passedModuleCount(progress: p, level: course.levels.single), 2);
      expect(
        levelCompletion(progress: p, level: course.levels.single),
        closeTo(0.5, 1e-9),
      );
    });
  });

  group('matriz completa de transiciones', () {
    test('toda transición ascendente se aplica', () {
      for (final LevelState from in LevelState.values) {
        for (final LevelState to in LevelState.values) {
          final StudentProgress before = withState(from);
          final StudentProgress after = applyLevelState(
            progress: before,
            levelId: 'A1',
            state: to,
          );

          if (to.rank > from.rank) {
            expect(
              after.stateOf('A1'),
              to,
              reason: '${from.name} → ${to.name} debe aplicarse',
            );
          } else {
            expect(
              after.stateOf('A1'),
              from,
              reason: '${from.name} → ${to.name} NO debe retroceder',
            );
          }
        }
      }
    });

    test('ninguna transición descendente pasa', () {
      // Explícito aparte de la matriz porque es la invariante que de verdad
      // protege al estudiante: nada de lo conseguido se pierde.
      for (final LevelState from in LevelState.values) {
        for (final LevelState to in LevelState.values) {
          if (to.rank >= from.rank) continue;
          final StudentProgress after = applyLevelState(
            progress: withState(from),
            levelId: 'A1',
            state: to,
          );
          expect(after.stateOf('A1').rank, greaterThanOrEqualTo(from.rank));
        }
      }
    });
  });

  group('aprobar el examen de nivel', () {
    test('marca el nivel como superado', () {
      final StudentProgress after = applyLevelExamPassed(
        course: course,
        progress: withState(LevelState.unlocked),
        level: course.levels.single,
      );
      expect(after.stateOf('A1'), LevelState.passed);
    });

    test('NO desbloquea A2, porque A2 no tiene contenido', () {
      // FR-038. Los niveles anunciados no son Level, así que no hay nada que
      // desbloquear: no existe el dato.
      final StudentProgress after = applyLevelExamPassed(
        course: course,
        progress: withState(LevelState.unlocked),
        level: course.levels.single,
      );

      expect(after.stateOf('A2'), LevelState.locked);
      expect(after.levelStates.containsKey('A2'), isFalse);
      expect(after.currentLevelId, 'A1');
    });

    test('un nivel anunciado no alcanza unlocked por ninguna vía', () {
      StudentProgress p = withState(LevelState.unlocked);

      // Todos los módulos aprobados.
      for (int i = 0; i < 4; i++) {
        p = p.copyWith(
          activityScores: <String, ActivityScore>{
            ...p.activityScores,
            moduleAt(i).moduleExam.id: passed(),
          },
        );
      }
      p = applyLevelExamPassed(
        course: course,
        progress: p,
        level: course.levels.single,
      );

      for (final String announced in course.upcomingLevelIds) {
        expect(
          p.stateOf(announced),
          LevelState.locked,
          reason: '$announced está solo anunciado',
        );
      }
    });
  });

  test('la clase de examen se deduce del curso', () {
    expect(
      examKindFor(course: course, examId: course.levels.single.levelExam.id),
      ActivityKind.levelExam,
    );
    expect(
      examKindFor(course: course, examId: moduleAt(0).moduleExam.id),
      ActivityKind.moduleExam,
    );
    expect(
      examKindFor(course: course, examId: 'no-existe'),
      ActivityKind.lesson,
    );
  });
}
