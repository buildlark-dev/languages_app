/// Verifica el registro de una actividad: mejor puntaje, XP y racha.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/engine/progress_recorder.dart';
import 'package:languages_app/engine/scoring.dart';

ScoreResult result(double ratio) => ScoreResult(
  correct: 0,
  answered: 10,
  unavailable: 0,
  ratio: ratio,
  passed: ratio >= 0.70,
);

StudentProgress base({
  int xp = 0,
  int streak = 0,
  DateTime? lastActivity,
  Map<String, ActivityScore> scores = const <String, ActivityScore>{},
}) => StudentProgress(
  uid: 'u1',
  courseId: 'en',
  currentLevelId: 'A1',
  xp: xp,
  streakCount: streak,
  lastActivityDate: lastActivity,
  activityScores: scores,
);

RecordedActivity record(
  StudentProgress progress,
  double ratio,
  DateTime when, {
  String activityId = 'L1',
  ActivityKind kind = ActivityKind.lesson,
}) => recordActivity(
  progress: progress,
  activityId: activityId,
  kind: kind,
  result: result(ratio),
  clock: fixedClock(when),
);

void main() {
  group('mejor puntaje', () {
    test('el primer intento se guarda tal cual', () {
      final RecordedActivity r = record(base(), 0.8, DateTime(2026, 10, 6));
      expect(r.progress.scoreOf('L1')!.bestScore, closeTo(0.8, 1e-9));
      expect(r.progress.scoreOf('L1')!.attempts, 1);
      expect(r.progress.hasPassed('L1'), isTrue);
    });

    test('un reintento PEOR no baja el puntaje ni desaprueba', () {
      // FR-027. Es la garantía que convierte reintentar en algo sin riesgo.
      StudentProgress p = record(base(), 0.9, DateTime(2026, 10, 6)).progress;
      p = record(p, 0.2, DateTime(2026, 10, 7)).progress;

      expect(p.scoreOf('L1')!.bestScore, closeTo(0.9, 1e-9));
      expect(p.hasPassed('L1'), isTrue);
      expect(p.scoreOf('L1')!.attempts, 2, reason: 'El intento sí se cuenta');
    });

    test('un reintento mejor sube el puntaje', () {
      StudentProgress p = record(base(), 0.5, DateTime(2026, 10, 6)).progress;
      p = record(p, 0.95, DateTime(2026, 10, 7)).progress;

      expect(p.scoreOf('L1')!.bestScore, closeTo(0.95, 1e-9));
    });

    test('el umbral depende de la clase de actividad', () {
      // 0.75 aprueba una lección pero no un examen.
      final StudentProgress lesson = record(
        base(),
        0.75,
        DateTime(2026, 10, 6),
      ).progress;
      final StudentProgress exam = record(
        base(),
        0.75,
        DateTime(2026, 10, 6),
        activityId: 'EX',
        kind: ActivityKind.moduleExam,
      ).progress;

      expect(lesson.hasPassed('L1'), isTrue);
      expect(exam.hasPassed('EX'), isFalse);
    });
  });

  group('XP', () {
    test('la primera vez suma el XP completo', () {
      final RecordedActivity r = record(base(), 1, DateTime(2026, 10, 6));
      expect(r.xpGained, 30);
      expect(r.progress.xp, 30);
    });

    test('repetir sin mejorar NO suma XP', () {
      final StudentProgress p = record(
        base(),
        0.8,
        DateTime(2026, 10, 6),
      ).progress;
      final int before = p.xp;

      final RecordedActivity again = record(p, 0.8, DateTime(2026, 10, 7));
      expect(again.xpGained, 0);
      expect(again.progress.xp, before);
    });

    test('mejorar suma solo la diferencia', () {
      final StudentProgress p = record(
        base(),
        0.6,
        DateTime(2026, 10, 6),
      ).progress;
      final int before = p.xp;

      final RecordedActivity better = record(p, 1, DateTime(2026, 10, 7));
      expect(better.xpGained, greaterThan(0));
      expect(better.progress.xp, before + better.xpGained);
    });
  });

  group('racha', () {
    test('la primera actividad la pone en 1', () {
      final RecordedActivity r = record(base(), 0.8, DateTime(2026, 10, 6));
      expect(r.progress.streakCount, 1);
      expect(r.streakIncreased, isTrue);
      expect(r.progress.lastActivityDate, DateTime(2026, 10, 6));
    });

    test('un día consecutivo la incrementa', () {
      final RecordedActivity r = record(
        base(streak: 4, lastActivity: DateTime(2026, 10, 5)),
        0.8,
        DateTime(2026, 10, 6),
      );
      expect(r.progress.streakCount, 5);
      expect(r.streakIncreased, isTrue);
    });

    test('dos lecciones el mismo día NO la incrementan dos veces', () {
      // FR-032. Es el error más fácil de cometer aquí.
      final RecordedActivity r = record(
        base(streak: 4, lastActivity: DateTime(2026, 10, 6)),
        0.8,
        DateTime(2026, 10, 6),
        activityId: 'L2',
      );
      expect(r.progress.streakCount, 4);
      expect(r.streakIncreased, isFalse);
    });

    test('dos días sin actividad la reinicia en 1', () {
      final RecordedActivity r = record(
        base(streak: 30, lastActivity: DateTime(2026, 10, 4)),
        0.8,
        DateTime(2026, 10, 6),
      );
      expect(r.progress.streakCount, 1);
    });

    test('la hora del día no afecta: cuenta la fecha', () {
      // Estudiar a las 23:50 y de nuevo a las 00:10 son dos días distintos, y
      // estudiar dos veces el mismo día a horas distintas es uno solo.
      final RecordedActivity sameDay = record(
        base(streak: 3, lastActivity: DateTime(2026, 10, 6)),
        0.8,
        DateTime(2026, 10, 6, 23, 50),
      );
      expect(sameDay.progress.streakCount, 3);

      final RecordedActivity nextDay = record(
        base(streak: 3, lastActivity: DateTime(2026, 10, 6, 23, 50)),
        0.8,
        DateTime(2026, 10, 7, 0, 10),
      );
      expect(nextDay.progress.streakCount, 4);
    });

    test('una racha larga se mantiene día a día', () {
      StudentProgress p = base();
      for (int day = 1; day <= 7; day++) {
        p = record(
          p,
          0.9,
          DateTime(2026, 10, day),
          activityId: 'L$day',
        ).progress;
      }
      expect(p.streakCount, 7, reason: 'SC-012: siete días seguidos');
    });
  });

  test('no se pierde nada del progreso anterior', () {
    final StudentProgress before = base(
      xp: 100,
      scores: <String, ActivityScore>{
        'OTRA': ActivityScore(
          kind: ActivityKind.moduleExam,
          bestScore: 0.88,
          lastAttemptAt: DateTime(2026, 10, 1),
        ),
      },
    );

    final StudentProgress after = record(
      before,
      0.9,
      DateTime(2026, 10, 6),
    ).progress;

    expect(after.scoreOf('OTRA')!.bestScore, closeTo(0.88, 1e-9));
    expect(after.xp, greaterThan(100));
  });
}
