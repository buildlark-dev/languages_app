/// Evalúa la prueba de nivelación y la aplica al progreso.
///
/// La idea que sostiene todo el archivo: **el nivel estimado y el nivel asignado
/// son cosas distintas, y solo el primero se almacena.**
///
/// El estimado sale de la prueba y puede ser cualquier nivel MCER, incluso uno
/// sin una línea de contenido escrita. El asignado se **deriva** del estimado
/// contra el catálogo vigente, cada vez que se necesita. Guardar el asignado
/// sería guardar una conclusión que caduca: el día en que se publique A2, el
/// asignado de quien dio B1 debe subir solo, sin migración y sin volver a
/// examinar a nadie.
///
/// Por eso aquí no hay ningún `assignedLevelId` dentro de [PlacementResult]:
/// está en [assignedLevelFor], que es una función del catálogo.
library;

import '../core/course.dart';
import '../core/exam.dart';
import '../core/level.dart';
import '../core/level_state.dart';
import '../core/placement_result.dart';
import '../core/student_progress.dart';
import '../core/thresholds.dart';

/// Proporción de aciertos por nivel discriminado, de 0 a 1.
///
/// Un nivel que la prueba no cubre no aparece en el mapa. No aparece con cero,
/// que significaría «lo falló» y es una afirmación que nadie hizo.
Map<String, double> placementLevelScores({
  required PlacementExam exam,
  required List<bool> answers,
}) {
  assert(
    answers.length == exam.items.length,
    'Hay ${answers.length} respuestas para ${exam.items.length} ítems',
  );

  final Map<String, int> correct = <String, int>{};
  final Map<String, int> total = <String, int>{};

  for (int i = 0; i < exam.items.length; i++) {
    final String levelId = exam.items[i].levelId;
    total[levelId] = (total[levelId] ?? 0) + 1;
    if (i < answers.length && answers[i]) {
      correct[levelId] = (correct[levelId] ?? 0) + 1;
    }
  }

  return <String, double>{
    for (final String levelId in total.keys)
      levelId: (correct[levelId] ?? 0) / total[levelId]!,
  };
}

/// Niveles demostrados: la racha superada **desde el más bajo, sin huecos**.
///
/// Que la racha tenga que ser contigua es la decisión importante. Alguien que
/// falla A2 y acierta B1 no está en B1: acertó una pregunta. Promover por un
/// resultado aislado mandaría a la persona a un nivel donde no entiende nada,
/// y la nivelación existe precisamente para evitar el camino equivocado.
///
/// El umbral por nivel es [examPassThreshold], el mismo que decide un examen de
/// nivel. Con dos ítems por nivel eso significa **los dos**, que es lo que se
/// quiere: saltarse un nivel entero por acertar uno de dos es una moneda al
/// aire, y lo que se juega es un nivel de contenido sin estudiar.
List<String> demonstratedLevelIds({
  required PlacementExam exam,
  required List<bool> answers,
}) {
  final Map<String, double> scores = placementLevelScores(
    exam: exam,
    answers: answers,
  );
  final List<String> covered = scores.keys.toList()
    ..sort((String a, String b) => cefrRank(a).compareTo(cefrRank(b)));

  final List<String> demonstrated = <String>[];
  for (final String levelId in covered) {
    if (scores[levelId]! < examPassThreshold) break;
    demonstrated.add(levelId);
  }
  return demonstrated;
}

/// El nivel que la prueba estima: el primero que la persona **no** demostró.
///
/// Es el nivel por el que debería empezar, y se informa tal cual aunque la app
/// no tenga su contenido (FR-035). Decirle a alguien «tu nivel es B1, y aquí
/// hoy puedes estudiar A1» es honesto; rebajar la estimación para que cuadre
/// con lo publicado, no.
///
/// Dos topes:
///
/// * Sin nada demostrado, es el nivel más bajo que la prueba cubre. No existe
///   nada por debajo de A1.
/// * Demostrándolo todo, es el nivel más alto que la prueba cubre, no el
///   siguiente. La prueba llega hasta C1: afirmar C2 por acertar los ítems de
///   C1 sería afirmar algo que no se midió.
String estimatedLevelFor({
  required PlacementExam exam,
  required List<bool> answers,
}) {
  final List<String> covered = exam.coveredLevelIds.toList()
    ..sort((String a, String b) => cefrRank(a).compareTo(cefrRank(b)));
  if (covered.isEmpty) return cefrLevelIds.first;

  final List<String> demonstrated = demonstratedLevelIds(
    exam: exam,
    answers: answers,
  );
  if (demonstrated.isEmpty) return covered.first;
  if (demonstrated.length == covered.length) return covered.last;

  return covered[demonstrated.length];
}

/// El nivel con contenido donde la persona puede estudiar hoy.
///
/// Es el nivel con contenido **más alto que no supere** al estimado. Se calcula
/// aquí y no se almacena: es una función del catálogo, y el catálogo crece.
String assignedLevelFor({
  required Course course,
  required String estimatedLevelId,
}) {
  final int ceiling = cefrRank(estimatedLevelId);
  String assigned = course.levels.first.id;

  for (final Level level in course.levels) {
    if (cefrRank(level.id) <= ceiling) {
      assigned = level.id;
    }
  }
  return assigned;
}

/// Niveles con contenido que quedan marcados como dominados.
///
/// Son los demostrados que además existen en el catálogo. Un nivel demostrado
/// sin contenido no se marca: no hay nada que marcar, y `upcomingLevelIds` son
/// identificadores sueltos precisamente para que ningún dato pueda representar
/// la entrada a un nivel que no existe.
List<String> masteredLevelIdsFor({
  required Course course,
  required PlacementExam exam,
  required List<bool> answers,
}) {
  final List<String> demonstrated = demonstratedLevelIds(
    exam: exam,
    answers: answers,
  );
  return <String>[
    for (final Level level in course.levels)
      if (demonstrated.contains(level.id)) level.id,
  ];
}

/// Evalúa la prueba completa.
PlacementResult evaluatePlacement({
  required Course course,
  required PlacementExam exam,
  required List<bool> answers,
  required DateTime takenAt,
}) => PlacementResult(
  estimatedLevelId: estimatedLevelFor(exam: exam, answers: answers),
  masteredLevelIds: masteredLevelIdsFor(
    course: course,
    exam: exam,
    answers: answers,
  ),
  takenAt: takenAt,
);

/// Aplica el resultado de la nivelación al progreso.
///
/// Reglas, todas verificadas en `placement_evaluator_test.dart`:
///
/// * Los niveles dominados quedan en [LevelState.mastered], **abiertos para
///   repaso** (FR-037). `mastered` no es `passed`: la persona no presentó el
///   examen de nivel, y mezclarlos borraría la diferencia entre demostrar en una
///   prueba corta y superar el nivel entero.
/// * El nivel asignado queda abierto si estaba bloqueado, y **nunca se degrada**
///   lo que ya estuviera más avanzado. Esa es la invariante del Principio IV: la
///   fusión por máximo de rango vale también aquí, donde lo que se fusiona es el
///   estado previo con lo que dice la nivelación.
/// * Repasar un nivel dominado no altera la marca ni la estimación, porque esta
///   función es la **única** que las escribe y solo se llama al nivelar.
StudentProgress applyPlacement({
  required StudentProgress progress,
  required Course course,
  required PlacementResult result,
}) {
  final String assigned = assignedLevelFor(
    course: course,
    estimatedLevelId: result.estimatedLevelId,
  );

  final Map<String, LevelState> states = <String, LevelState>{
    ...progress.levelStates,
  };

  for (final String levelId in result.masteredLevelIds) {
    states[levelId] = LevelState.merge(
      states[levelId] ?? LevelState.locked,
      LevelState.mastered,
    );
  }

  states[assigned] = LevelState.merge(
    states[assigned] ?? LevelState.locked,
    LevelState.unlocked,
  );

  return progress.copyWith(
    currentLevelId: assigned,
    levelStates: states,
    placement: result,
  );
}

/// Si conviene ofrecer la nivelación por iniciativa de la app.
///
/// Solo a quien acaba de empezar. Quien ya tiene actividad registrada no debe
/// volver a verla ofrecida (FR, tarea T143): a esas alturas la nivelación no
/// informa nada que el progreso real no diga mejor, y una invitación a saltar
/// niveles delante de alguien que lleva tres módulos hechos solo consigue que
/// dude de lo que ya hizo.
///
/// Que alguien la haya **omitido** también cuenta como respuesta: se le preguntó
/// y dijo que no.
bool shouldOfferPlacement({
  required Course course,
  required StudentProgress progress,
}) {
  if (course.placementTest == null) return false;
  if (progress.placement != null) return false;
  return progress.activityScores.isEmpty;
}
