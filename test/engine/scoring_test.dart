/// Verifica los umbrales y, sobre todo, que un ejercicio oral no intentable no
/// cuente como fallo.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/engine/scoring.dart';

/// Construye una lista con [correct] aciertos, [incorrect] fallos y
/// [unavailable] ejercicios no intentables.
List<ExerciseOutcome> outcomes({
  int correct = 0,
  int incorrect = 0,
  int unavailable = 0,
}) => <ExerciseOutcome>[
  ...List<ExerciseOutcome>.filled(correct, ExerciseOutcome.correct),
  ...List<ExerciseOutcome>.filled(incorrect, ExerciseOutcome.incorrect),
  ...List<ExerciseOutcome>.filled(unavailable, ExerciseOutcome.unavailable),
];

void main() {
  group('umbral de lección: 70 %', () {
    test('7 de 10 aprueba, justo en el límite', () {
      final ScoreResult r = scoreActivity(
        outcomes: outcomes(correct: 7, incorrect: 3),
        kind: ActivityKind.lesson,
      );
      expect(r.percentage, 70);
      expect(r.passed, isTrue);
    });

    test('69 % no aprueba', () {
      // 69 de 100 para caer justo por debajo sin ambigüedad de redondeo.
      final ScoreResult r = scoreActivity(
        outcomes: outcomes(correct: 69, incorrect: 31),
        kind: ActivityKind.lesson,
      );
      expect(r.percentage, 69);
      expect(r.passed, isFalse);
    });
  });

  group('umbral de examen: 80 %', () {
    test('8 de 10 aprueba, justo en el límite', () {
      final ScoreResult r = scoreActivity(
        outcomes: outcomes(correct: 8, incorrect: 2),
        kind: ActivityKind.moduleExam,
      );
      expect(r.percentage, 80);
      expect(r.passed, isTrue);
    });

    test('79 % no aprueba', () {
      final ScoreResult r = scoreActivity(
        outcomes: outcomes(correct: 79, incorrect: 21),
        kind: ActivityKind.levelExam,
      );
      expect(r.passed, isFalse);
    });

    test('7 de 10 aprueba una lección pero NO un examen', () {
      final List<ExerciseOutcome> same = outcomes(correct: 7, incorrect: 3);
      expect(
        scoreActivity(outcomes: same, kind: ActivityKind.lesson).passed,
        isTrue,
      );
      expect(
        scoreActivity(outcomes: same, kind: ActivityKind.moduleExam).passed,
        isFalse,
      );
    });
  });

  group('ejercicios orales no intentables', () {
    test('salen del denominador, no cuentan como fallo', () {
      // Siete aciertos, un fallo, dos ejercicios orales imposibles de intentar.
      // Si contaran como fallos sería 7/10 = 70 % y no aprobaría el examen.
      final ScoreResult r = scoreActivity(
        outcomes: outcomes(correct: 7, incorrect: 1, unavailable: 2),
        kind: ActivityKind.moduleExam,
      );
      expect(r.answered, 8);
      expect(r.unavailable, 2);
      expect(r.percentage, 88);
      expect(
        r.passed,
        isTrue,
        reason:
            'SC-008 exige que una lección se pueda aprobar con el micrófono '
            'denegado',
      );
    });

    test('una lección entera por la ruta alternativa se aprueba', () {
      // El caso de SC-008: micrófono denegado y sonido apagado. Los dos
      // ejercicios orales se resuelven por la alternativa y el resto se acierta.
      final ScoreResult r = scoreActivity(
        outcomes: outcomes(correct: 5, unavailable: 2),
        kind: ActivityKind.lesson,
      );
      expect(r.percentage, 100);
      expect(r.passed, isTrue);
    });

    test('si no quedó nada que contar, no aprueba, pero tampoco revienta', () {
      final ScoreResult r = scoreActivity(
        outcomes: outcomes(unavailable: 5),
        kind: ActivityKind.lesson,
      );
      expect(r.answered, 0);
      expect(r.ratio, 0);
      expect(r.passed, isFalse);
    });
  });

  test('una actividad vacía no aprueba', () {
    final ScoreResult r = scoreActivity(
      outcomes: const <ExerciseOutcome>[],
      kind: ActivityKind.lesson,
    );
    expect(r.passed, isFalse);
  });
}
