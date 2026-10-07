/// Un examen: módulo, nivel o nivelación.
library;

import 'exercise.dart';
import 'thresholds.dart';

/// A qué sirve un examen.
enum ExamScope {
  /// Cierra un módulo y abre el siguiente.
  module,

  /// Cierra un nivel. Es la puerta al nivel siguiente.
  level,

  /// Estima el nivel del estudiante al empezar. No aprueba ni suspende.
  placement,
}

class Exam {
  const Exam({
    required this.id,
    required this.scope,
    required this.exercises,
  });

  /// Único en todo el curso.
  final String id;

  final ExamScope scope;

  /// Mínimo diez ejercicios, según la invariante 8 del contrato de contenido.
  final List<Exercise> exercises;

  /// Proporción de aciertos necesaria para aprobar.
  ///
  /// Se lee de [examPassThreshold] en lugar de declararse por examen: el umbral
  /// es una regla de producto uniforme (Principio III), no una propiedad que
  /// cada examen pueda ajustar a su gusto.
  ///
  /// Un examen de nivelación no se aprueba ni se suspende —estima un nivel— así
  /// que su umbral no se usa.
  double get passThreshold => examPassThreshold;
}

/// Un ejercicio de nivelación junto al nivel que discrimina.
///
/// La prueba de nivelación necesita saber qué nivel pone a prueba cada ítem para
/// poder estimar. Ese dato no pertenece al ejercicio en sí —el mismo tipo de
/// ejercicio se usa en lecciones, donde el nivel lo da el módulo— así que se
/// adjunta aquí.
class PlacementItem {
  const PlacementItem({
    required this.levelId,
    required this.exercise,
  });

  /// Nivel MCER que este ítem discrimina.
  ///
  /// **Puede ser un nivel sin contenido construido.** La prueba estima el nivel
  /// real de la persona, no el nivel al que la app puede llevarla todavía
  /// (invariante 20 del contrato de contenido).
  final String levelId;

  final Exercise exercise;
}

/// Examen de nivelación: ejercicios etiquetados por nivel.
class PlacementExam {
  const PlacementExam({
    required this.id,
    required this.items,
  });

  final String id;
  final List<PlacementItem> items;

  /// Los niveles que la prueba es capaz de discriminar, en orden de aparición.
  Set<String> get coveredLevelIds =>
      items.map((PlacementItem item) => item.levelId).toSet();
}
