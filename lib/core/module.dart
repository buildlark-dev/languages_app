/// Un módulo: la unidad temática dentro de un nivel.
library;

import 'exam.dart';
import 'exercise.dart';
import 'lesson.dart';
import 'teaching_material.dart';
import 'vocabulary_item.dart';

class Module {
  const Module({
    required this.id,
    required this.order,
    required this.title,
    required this.canDo,
    required this.vocabulary,
    required this.grammar,
    required this.examples,
    required this.reading,
    required this.lessons,
    required this.moduleExam,
  });

  /// Único en todo el curso. Ej.: `A1M1`.
  final String id;

  /// Posición dentro del nivel, desde 1 y consecutiva.
  final int order;

  final String title;

  /// Objetivo funcional en formato "puedo hacer X".
  ///
  /// Visible antes de empezar el módulo (FR-011). Es lo que convierte una lista
  /// de ejercicios en una promesa concreta: "presentarte, deletrear tu nombre y
  /// preguntar lo mismo a otra persona".
  final String canDo;

  /// Mínimo ocho ítems, según la invariante 6 del contrato de contenido.
  final List<VocabularyItem> vocabulary;

  final GrammarExplanation grammar;

  /// Mínimo tres ejemplos.
  final List<BilingualExample> examples;

  /// Solo el texto. Sus preguntas son ejercicios de la lección que lo
  /// referencia.
  final ReadingPassage reading;

  /// Mínimo una lección.
  final List<Lesson> lessons;

  final Exam moduleExam;

  /// Todos los ejercicios del módulo, de todas sus lecciones.
  ///
  /// Lo usa la prueba de integridad del contenido para comprobar que el módulo
  /// cubre las cuatro destrezas.
  Iterable<Exercise> get allLessonExercises =>
      lessons.expand((Lesson lesson) => lesson.exercises);

  /// Si el módulo ejercita la escucha.
  bool get hasListening =>
      allLessonExercises.any((Exercise e) => e is ListeningExercise);

  /// Si el módulo ejercita el habla.
  bool get hasPronunciation =>
      allLessonExercises.any((Exercise e) => e is PronunciationExercise);

  /// Si el módulo ejercita la producción escrita.
  bool get hasWrittenProduction => allLessonExercises.any(
    (Exercise e) => e is SentenceBuilderExercise || e is GapFillExercise,
  );
}
