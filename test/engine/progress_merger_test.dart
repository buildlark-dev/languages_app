/// Verifica que fusionar NUNCA le quite avance a nadie.
///
/// Es la prueba más importante del proyecto. Si falla, un estudiante pierde
/// trabajo real al sincronizar dos dispositivos.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/placement_result.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/engine/progress_merger.dart';

const String uid = 'u1';
const String courseId = 'en';

DateTime day(int d) => DateTime(2026, 10, d);

ActivityScore score(double value, {DateTime? at, int attempts = 1}) =>
    ActivityScore(
      kind: ActivityKind.lesson,
      bestScore: value,
      attempts: attempts,
      lastAttemptAt: at ?? day(1),
    );

ReviewCard card(String term, {required int step, required DateTime due, int lapses = 0}) =>
    ReviewCard(
      moduleId: 'A1M1',
      term: term,
      translation: term,
      intervalStep: step,
      dueDate: due,
      lapses: lapses,
    );

StudentProgress progress({
  int xp = 0,
  int streak = 0,
  DateTime? lastActivity,
  String level = 'A1',
  Map<String, LevelState> levels = const <String, LevelState>{},
  Map<String, ActivityScore> scores = const <String, ActivityScore>{},
  Map<String, ReviewCard> cards = const <String, ReviewCard>{},
  PlacementResult? placement,
}) => StudentProgress(
  uid: uid,
  courseId: courseId,
  currentLevelId: level,
  xp: xp,
  streakCount: streak,
  lastActivityDate: lastActivity,
  levelStates: levels,
  activityScores: scores,
  reviewCards: cards,
  placement: placement,
);

/// Los estados con los que se prueban las propiedades algebraicas.
List<StudentProgress> sampleStates() => <StudentProgress>[
  progress(),
  progress(xp: 100, streak: 3, lastActivity: day(3), levels: <String, LevelState>{
    'A1': LevelState.unlocked,
  }),
  progress(
    xp: 40,
    streak: 7,
    lastActivity: day(1),
    level: 'A2',
    levels: <String, LevelState>{'A1': LevelState.passed, 'A2': LevelState.unlocked},
    scores: <String, ActivityScore>{'L1': score(0.9), 'L2': score(0.5)},
  ),
  progress(
    xp: 220,
    streak: 1,
    lastActivity: day(5),
    levels: <String, LevelState>{'A1': LevelState.mastered},
    scores: <String, ActivityScore>{'L1': score(0.6), 'L3': score(1)},
    cards: <String, ReviewCard>{
      'A1M1|name': card('name', step: 4, due: day(20), lapses: 2),
    },
    placement: PlacementResult(
      estimatedLevelId: 'B1',
      masteredLevelIds: const <String>['A1'],
      takenAt: day(2),
    ),
  ),
  progress(
    xp: 220,
    streak: 9,
    lastActivity: day(5),
    cards: <String, ReviewCard>{
      'A1M1|name': card('name', step: 1, due: day(8)),
      'A1M1|city': card('city', step: 0, due: day(6)),
    },
  ),
];

/// Comprueba que [merged] no es menor que [input] en ninguna magnitud.
void expectNoRegression(StudentProgress merged, StudentProgress input) {
  expect(merged.xp, greaterThanOrEqualTo(input.xp));
  expect(
    merged.activityScores.length,
    greaterThanOrEqualTo(input.activityScores.length),
  );
  expect(
    merged.reviewCards.length,
    greaterThanOrEqualTo(input.reviewCards.length),
  );
  expect(merged.levelStates.length, greaterThanOrEqualTo(input.levelStates.length));

  for (final MapEntry<String, ActivityScore> e in input.activityScores.entries) {
    expect(
      merged.activityScores[e.key]!.bestScore,
      greaterThanOrEqualTo(e.value.bestScore),
      reason: 'El puntaje de ${e.key} no puede bajar',
    );
  }
  for (final MapEntry<String, LevelState> e in input.levelStates.entries) {
    expect(
      merged.levelStates[e.key]!.rank,
      greaterThanOrEqualTo(e.value.rank),
      reason: 'El estado de ${e.key} no puede retroceder',
    );
  }
  for (final MapEntry<String, ReviewCard> e in input.reviewCards.entries) {
    final ReviewCard m = merged.reviewCards[e.key]!;
    expect(m.intervalStep, greaterThanOrEqualTo(e.value.intervalStep));
    expect(
      m.dueDate.isAfter(e.value.dueDate),
      isFalse,
      reason: 'La fecha de repaso solo puede adelantarse, nunca retrasarse',
    );
  }
}

/// Igualdad de los campos que las propiedades algebraicas deben preservar.
void expectSameProgress(StudentProgress a, StudentProgress b) {
  expect(a.xp, b.xp);
  expect(a.streakCount, b.streakCount);
  expect(a.lastActivityDate, b.lastActivityDate);
  expect(a.currentLevelId, b.currentLevelId);
  expect(a.levelStates, b.levelStates);
  expect(a.activityScores.keys.toSet(), b.activityScores.keys.toSet());
  for (final String key in a.activityScores.keys) {
    expect(a.activityScores[key]!.bestScore, b.activityScores[key]!.bestScore);
  }
  expect(a.reviewCards.keys.toSet(), b.reviewCards.keys.toSet());
  for (final String key in a.reviewCards.keys) {
    expect(a.reviewCards[key]!.intervalStep, b.reviewCards[key]!.intervalStep);
    expect(a.reviewCards[key]!.dueDate, b.reviewCards[key]!.dueDate);
  }
  expect(a.placement?.estimatedLevelId, b.placement?.estimatedLevelId);
}

void main() {
  final List<StudentProgress> states = sampleStates();

  group('propiedades algebraicas sobre todas las permutaciones', () {
    test('conmutativa: merge(a,b) == merge(b,a)', () {
      for (final StudentProgress a in states) {
        for (final StudentProgress b in states) {
          expectSameProgress(mergeProgress(a, b), mergeProgress(b, a));
        }
      }
    });

    test('asociativa: merge(merge(a,b),c) == merge(a,merge(b,c))', () {
      for (final StudentProgress a in states) {
        for (final StudentProgress b in states) {
          for (final StudentProgress c in states) {
            expectSameProgress(
              mergeProgress(mergeProgress(a, b), c),
              mergeProgress(a, mergeProgress(b, c)),
            );
          }
        }
      }
    });

    test('idempotente: merge(a,a) == a', () {
      for (final StudentProgress a in states) {
        expectSameProgress(mergeProgress(a, a), a);
      }
    });

    test('vuelve a fusionar sin cambiar nada', () {
      for (final StudentProgress a in states) {
        for (final StudentProgress b in states) {
          final StudentProgress once = mergeProgress(a, b);
          expectSameProgress(mergeProgress(once, b), once);
          expectSameProgress(mergeProgress(once, a), once);
        }
      }
    });
  });

  test('INVARIANTE CENTRAL: fusionar nunca reduce nada', () {
    for (final StudentProgress a in states) {
      for (final StudentProgress b in states) {
        final StudentProgress merged = mergeProgress(a, b);
        expectNoRegression(merged, a);
        expectNoRegression(merged, b);
      }
    }
  });

  group('reglas por campo', () {
    test('el XP toma el máximo, no la suma', () {
      // Sumar contaría dos veces la misma actividad sincronizada dos veces.
      final StudentProgress merged = mergeProgress(
        progress(xp: 100),
        progress(xp: 250),
      );
      expect(merged.xp, 250);
    });

    test('el estado de nivel toma el más avanzado', () {
      final StudentProgress merged = mergeProgress(
        progress(levels: <String, LevelState>{'A1': LevelState.unlocked}),
        progress(levels: <String, LevelState>{'A1': LevelState.passed}),
      );
      expect(merged.stateOf('A1'), LevelState.passed);
    });

    test('el nivel actual toma el más avanzado del MCER', () {
      expect(
        mergeProgress(progress(level: 'A1'), progress(level: 'B1')).currentLevelId,
        'B1',
      );
    });

    test('el puntaje de cada actividad toma el máximo', () {
      final StudentProgress merged = mergeProgress(
        progress(scores: <String, ActivityScore>{'L1': score(0.9)}),
        progress(scores: <String, ActivityScore>{'L1': score(0.4)}),
      );
      expect(merged.activityScores['L1']!.bestScore, closeTo(0.9, 1e-9));
    });

    test('las actividades de ambos lados se conservan', () {
      final StudentProgress merged = mergeProgress(
        progress(scores: <String, ActivityScore>{'L1': score(0.9)}),
        progress(scores: <String, ActivityScore>{'L2': score(0.8)}),
      );
      expect(merged.activityScores.keys, containsAll(<String>['L1', 'L2']));
    });

    test('la tarjeta de repaso toma la fecha MÁS PRÓXIMA', () {
      // Ante la duda se repasa antes: repasar de más cuesta treinta segundos, no
      // repasar lo que se estaba olvidando cuesta el aprendizaje.
      final StudentProgress merged = mergeProgress(
        progress(
          cards: <String, ReviewCard>{
            'A1M1|name': card('name', step: 4, due: day(30)),
          },
        ),
        progress(
          cards: <String, ReviewCard>{
            'A1M1|name': card('name', step: 1, due: day(8)),
          },
        ),
      );
      final ReviewCard merged1 = merged.reviewCards['A1M1|name']!;
      expect(merged1.dueDate, day(8));
      expect(merged1.intervalStep, 4, reason: 'El paso sí toma el máximo');
    });

    test('la nivelación más reciente gana', () {
      final StudentProgress merged = mergeProgress(
        progress(
          placement: PlacementResult(
            estimatedLevelId: 'A1',
            masteredLevelIds: const <String>[],
            takenAt: day(1),
          ),
        ),
        progress(
          placement: PlacementResult(
            estimatedLevelId: 'B1',
            masteredLevelIds: const <String>['A1'],
            takenAt: day(9),
          ),
        ),
      );
      expect(merged.placement!.estimatedLevelId, 'B1');
    });
  });

  group('la racha caducada NO revive', () {
    test('racha 7 del lunes + racha 1 del jueves da 1', () {
      // El caso que destapó el análisis cruzado. Con máximo a secas daría 7:
      // «siete días seguidos» para quien no estudió el martes ni el miércoles,
      // incumpliendo FR-032 de forma visible.
      final StudentProgress phone = progress(streak: 7, lastActivity: day(5));
      final StudentProgress laptop = progress(streak: 1, lastActivity: day(8));

      final StudentProgress merged = mergeProgress(phone, laptop);
      expect(merged.streakCount, 1);
      expect(merged.lastActivityDate, day(8));

      // Y da lo mismo en el otro orden.
      expect(mergeProgress(laptop, phone).streakCount, 1);
    });

    test('mismo día: gana la racha mayor, que favorece al estudiante', () {
      final StudentProgress merged = mergeProgress(
        progress(streak: 7, lastActivity: day(5)),
        progress(streak: 3, lastActivity: day(5)),
      );
      expect(merged.streakCount, 7);
    });

    test('días consecutivos: la racha del día posterior es la vigente', () {
      final StudentProgress merged = mergeProgress(
        progress(streak: 7, lastActivity: day(5)),
        progress(streak: 8, lastActivity: day(6)),
      );
      expect(merged.streakCount, 8);
      expect(merged.lastActivityDate, day(6));
    });

    test('un dispositivo sin actividad no borra la racha del otro', () {
      final StudentProgress merged = mergeProgress(
        progress(streak: 5, lastActivity: day(5)),
        progress(),
      );
      expect(merged.streakCount, 5);
      expect(merged.lastActivityDate, day(5));
    });
  });

  test('el estado de sincronización NO se fusiona: es del dispositivo', () {
    final StudentProgress local = progress();
    final StudentProgress merged = mergeProgress(local, progress(xp: 99));
    expect(merged.syncState, same(local.syncState));
  });
}
