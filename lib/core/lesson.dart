/// Una lección: la única unidad calificable junto a los exámenes.
library;

import 'exercise.dart';

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.exercises,
    this.readingRef,
  });

  /// Único en todo el curso.
  final String id;

  final String title;

  /// Identificador del pasaje de lectura que esta lección usa como apoyo.
  ///
  /// Nulo si la lección no se apoya en una lectura.
  final String? readingRef;

  /// Los ejercicios que se califican.
  ///
  /// Mínimo cinco, para que el umbral del 70 % tenga sentido: con cuatro
  /// ejercicios, 70 % no es alcanzable de forma exacta y el umbral real sería
  /// 75 %.
  final List<Exercise> exercises;

  /// Cuántos ejercicios hay que acertar para aprobar.
  ///
  /// No está aquí el cálculo del umbral: eso es responsabilidad del motor
  /// (`engine/scoring.dart`). Esto es solo el tamaño del examen.
  int get exerciseCount => exercises.length;
}
