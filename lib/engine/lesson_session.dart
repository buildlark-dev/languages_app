/// Estado de una lección mientras se recorre.
///
/// La regla que gobierna este archivo: **una lección interrumpida no es una
/// lección fallada.** Si la app se cierra a mitad, al volver la lección aparece
/// como no presentada, con su mejor puntaje anterior intacto.
///
/// Por eso el resultado solo se puede registrar cuando la sesión está completa
/// ([canBeRecorded]), y la sesión vive en memoria: nada parcial llega al almacén.
library;

import '../core/activity_score.dart';
import '../core/exercise.dart';
import '../core/lesson.dart';
import 'scoring.dart';

class LessonSession {
  LessonSession.start({required this.lesson, this.kind = ActivityKind.lesson})
    : _outcomes = <ExerciseOutcome>[];

  final Lesson lesson;
  final ActivityKind kind;

  final List<ExerciseOutcome> _outcomes;

  /// Cuántos ejercicios se han resuelto.
  int get answeredCount => _outcomes.length;

  /// Índice del ejercicio en curso.
  int get currentIndex => _outcomes.length;

  /// Total de ejercicios de la lección.
  int get totalCount => lesson.exercises.length;

  /// Progreso dentro de la lección, de 0.0 a 1.0. Para la barra de avance.
  double get progress => totalCount == 0 ? 1 : answeredCount / totalCount;

  bool get isComplete => _outcomes.length >= totalCount;

  /// El ejercicio que toca, o nulo si ya se terminó.
  Exercise? get currentExercise =>
      isComplete ? null : lesson.exercises[currentIndex];

  /// Las respuestas dadas hasta ahora, en orden.
  List<ExerciseOutcome> get outcomes =>
      List<ExerciseOutcome>.unmodifiable(_outcomes);

  /// Registra el resultado del ejercicio en curso y avanza.
  ///
  /// Lanza si ya estaba completa: avanzar más allá del final sería un error de
  /// programación de la interfaz, no un caso que haya que tolerar en silencio.
  void answer(ExerciseOutcome outcome) {
    if (isComplete) {
      throw StateError('La lección ya está completa: no hay nada que responder');
    }
    _outcomes.add(outcome);
  }

  /// Marca el ejercicio en curso como no intentable y avanza.
  ///
  /// Es el camino del ejercicio oral sin micrófono, sin permiso o con el
  /// reconocimiento fallando: no cuenta como fallo (FR-020) y permite seguir.
  void skipAsUnavailable() => answer(ExerciseOutcome.unavailable);

  /// Reinicia la lección desde el principio, para reintentarla.
  void restart() => _outcomes.clear();

  /// Solo una sesión completa se puede guardar.
  ///
  /// Mientras sea false, el almacén no debe tocarse: así una lección abandonada
  /// a mitad no puede empeorar un resultado anterior.
  bool get canBeRecorded => isComplete;

  /// La calificación de la sesión. Solo tiene sentido si está completa.
  ScoreResult get result =>
      scoreActivity(outcomes: _outcomes, kind: kind);
}
