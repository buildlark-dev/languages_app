/// Verifica que el XP recompense sin volverse una máquina de puntos.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/engine/scoring.dart';
import 'package:languages_app/engine/xp_calculator.dart';

ScoreResult result(double ratio, ActivityKind kind) => ScoreResult(
  correct: 0,
  answered: 10,
  unavailable: 0,
  ratio: ratio,
  passed: ratio >= kind.passThreshold,
);

void main() {
  group('XP por resultado', () {
    test('una lección perfecta da el máximo más la bonificación', () {
      expect(
        xpForResult(result(1, ActivityKind.lesson), ActivityKind.lesson),
        20 + 10,
      );
    });

    test('aprobar justo en el umbral ya da la bonificación', () {
      expect(
        xpForResult(result(0.7, ActivityKind.lesson), ActivityKind.lesson),
        14 + 10,
      );
    });

    test('suspender todavía recompensa los aciertos', () {
      // 60 % no aprueba, pero algo se aprendió. Dar cero convierte un tropiezo
      // en pérdida total.
      final int xp = xpForResult(
        result(0.6, ActivityKind.lesson),
        ActivityKind.lesson,
      );
      expect(xp, 12);
      expect(xp, greaterThan(0));
    });

    test('no acertar nada da cero', () {
      expect(
        xpForResult(result(0, ActivityKind.lesson), ActivityKind.lesson),
        0,
      );
    });

    test('un examen vale más que una lección con el mismo porcentaje', () {
      final ScoreResult perfectLesson = result(1, ActivityKind.lesson);
      final ScoreResult perfectModule = result(1, ActivityKind.moduleExam);
      final ScoreResult perfectLevel = result(1, ActivityKind.levelExam);

      final int lesson = xpForResult(perfectLesson, ActivityKind.lesson);
      final int module = xpForResult(perfectModule, ActivityKind.moduleExam);
      final int level = xpForResult(perfectLevel, ActivityKind.levelExam);

      expect(module, greaterThan(lesson));
      expect(level, greaterThan(module));
    });

    test('el XP no depende de cuántos ejercicios tuviera la actividad', () {
      // Una lección de 5 y otra de 20, ambas al 80 %, dan lo mismo. Si no, una
      // lección larga valdría más por el solo hecho de ser larga.
      const ScoreResult short = ScoreResult(
        correct: 4,
        answered: 5,
        unavailable: 0,
        ratio: 0.8,
        passed: true,
      );
      const ScoreResult long = ScoreResult(
        correct: 16,
        answered: 20,
        unavailable: 0,
        ratio: 0.8,
        passed: true,
      );

      expect(
        xpForResult(short, ActivityKind.lesson),
        xpForResult(long, ActivityKind.lesson),
      );
    });
  });

  group('reintentos: solo la mejora puntúa', () {
    test('el primer intento da el XP completo', () {
      expect(
        xpGainForAttempt(
          result: result(0.8, ActivityKind.lesson),
          kind: ActivityKind.lesson,
          previousBest: null,
        ),
        xpForResult(result(0.8, ActivityKind.lesson), ActivityKind.lesson),
      );
    });

    test('repetir con el mismo puntaje NO da XP', () {
      // Sin esto, repetir una lección fácil sería XP infinito y la cifra dejaría
      // de significar nada.
      expect(
        xpGainForAttempt(
          result: result(0.8, ActivityKind.lesson),
          kind: ActivityKind.lesson,
          previousBest: 0.8,
        ),
        0,
      );
    });

    test('repetir peor NO quita XP', () {
      expect(
        xpGainForAttempt(
          result: result(0.4, ActivityKind.lesson),
          kind: ActivityKind.lesson,
          previousBest: 0.9,
        ),
        0,
      );
    });

    test('mejorar da solo la diferencia', () {
      // De 60 % (12 XP, sin bonificación) a 100 % (30 XP) → 18.
      expect(
        xpGainForAttempt(
          result: result(1, ActivityKind.lesson),
          kind: ActivityKind.lesson,
          previousBest: 0.6,
        ),
        18,
      );
    });

    test('pasar de suspenso a aprobado incluye la bonificación', () {
      // De 60 % (12) a 70 % (14 + 10 = 24) → 12.
      expect(
        xpGainForAttempt(
          result: result(0.7, ActivityKind.lesson),
          kind: ActivityKind.lesson,
          previousBest: 0.6,
        ),
        12,
      );
    });
  });
}
