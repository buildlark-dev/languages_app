/// Puntos de experiencia por actividad completada.
///
/// Dos decisiones de diseño que importan más de lo que parece:
///
/// * **Los aciertos puntúan aunque no se apruebe.** Alguien que saca 60 % se
///   llevó algo: castigarlo con cero XP convierte un tropiezo en una pérdida
///   total y es la forma más rápida de que abandone.
/// * **El XP no depende de cuántos ejercicios tuviera la actividad**, sino de la
///   proporción acertada. Si no, una lección larga valdría más que una corta por
///   el solo hecho de ser larga, y los ejercicios orales no intentables —que
///   salen del denominador— alterarían la recompensa.
library;

import '../core/activity_score.dart';
import 'scoring.dart';

/// XP por una actividad perfecta, según su clase.
///
/// Un examen vale más porque exige dominar el módulo o el nivel completo, no un
/// puñado de ejercicios.
const Map<ActivityKind, int> maxXpByKind = <ActivityKind, int>{
  ActivityKind.lesson: 20,
  ActivityKind.moduleExam: 50,
  ActivityKind.levelExam: 120,
};

/// Bonificación por alcanzar el umbral de aprobación.
const Map<ActivityKind, int> passBonusByKind = <ActivityKind, int>{
  ActivityKind.lesson: 10,
  ActivityKind.moduleExam: 25,
  ActivityKind.levelExam: 60,
};

/// XP que otorga un resultado.
int xpForResult(ScoreResult result, ActivityKind kind) {
  final int max = maxXpByKind[kind]!;
  final int earned = (max * result.ratio).round();
  if (!result.passed) return earned;
  return earned + passBonusByKind[kind]!;
}

/// XP que un reintento añade de verdad.
///
/// Solo se concede la **diferencia** respecto a lo que esa actividad ya había
/// dado. Sin esto, repetir una lección fácil sería una máquina infinita de XP y
/// la cifra dejaría de significar nada.
///
/// [previousBest] es la proporción del mejor intento anterior, o nulo si es el
/// primero.
int xpGainForAttempt({
  required ScoreResult result,
  required ActivityKind kind,
  required double? previousBest,
}) {
  final int now = xpForResult(result, kind);
  if (previousBest == null) return now;

  final int before = xpForResult(
    ScoreResult(
      correct: 0,
      answered: 1,
      unavailable: 0,
      ratio: previousBest,
      passed: previousBest >= kind.passThreshold,
    ),
    kind,
  );

  final int gain = now - before;
  return gain > 0 ? gain : 0;
}
