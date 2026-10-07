/// Verifica el recorrido de una lección, incluido el abandono a mitad.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/core/lesson.dart';
import 'package:languages_app/engine/lesson_session.dart';
import 'package:languages_app/engine/scoring.dart';

/// Lección de cinco ejercicios: tres escritos y dos orales.
Lesson buildLesson() => const Lesson(
  id: 'A1M1L1',
  title: 'Identidad y saludos',
  exercises: <Exercise>[
    MultipleChoiceExercise(
      prompt: 'She ___ a nurse.',
      options: <String>['am', 'is', 'are'],
      answerIndex: 1,
      explanation: 'Tercera persona del singular: is.',
    ),
    GapFillExercise(
      sentenceWithGap: 'My brother ___ a doctor.',
      acceptedAnswers: <String>['is', "'s"],
      explanation: 'Tercera persona del singular.',
    ),
    SentenceBuilderExercise(
      targetSentence: 'My sister is a teacher.',
      tokens: <String>['My', 'sister', 'is', 'a', 'teacher.'],
      explanation: 'Sujeto, verbo y atributo con artículo.',
    ),
    ListeningExercise(
      spokenText: 'My name is Elena and I am from Bogota.',
      question: '¿De dónde es?',
      options: <String>['De Bogotá', 'De Lima', 'De Quito'],
      answerIndex: 0,
      explanation: 'Dice «I am from Bogota».',
      transcriptFallback: 'My name is Elena and I am from Bogota.',
    ),
    PronunciationExercise(
      targetPhrase: 'Nice to meet you.',
      translation: 'Encantado de conocerte.',
      explanation: 'Fórmula fija de presentación.',
      writtenFallback: 'Escribe la frase: Nice to meet you.',
    ),
  ],
);

void main() {
  test('una sesión nueva empieza en el primer ejercicio', () {
    final LessonSession session = LessonSession.start(lesson: buildLesson());

    expect(session.currentIndex, 0);
    expect(session.totalCount, 5);
    expect(session.isComplete, isFalse);
    expect(session.canBeRecorded, isFalse);
    expect(session.currentExercise, isA<MultipleChoiceExercise>());
    expect(session.progress, 0);
  });

  test('responder avanza al siguiente ejercicio', () {
    final LessonSession session = LessonSession.start(lesson: buildLesson());

    session.answer(ExerciseOutcome.correct);
    expect(session.currentIndex, 1);
    expect(session.currentExercise, isA<GapFillExercise>());
    expect(session.progress, closeTo(0.2, 1e-9));
  });

  test('una lección abandonada a mitad NO se puede registrar', () {
    final LessonSession session = LessonSession.start(lesson: buildLesson());

    session.answer(ExerciseOutcome.correct);
    session.answer(ExerciseOutcome.correct);

    // Aquí el estudiante cierra la app. La sesión vive en memoria y se pierde,
    // que es exactamente lo que debe pasar: su mejor puntaje anterior queda
    // intacto porque nada parcial llegó al almacén.
    expect(session.isComplete, isFalse);
    expect(
      session.canBeRecorded,
      isFalse,
      reason: 'Una lección interrumpida no es una lección fallada',
    );
  });

  test('completarla la hace registrable y la califica', () {
    final LessonSession session = LessonSession.start(lesson: buildLesson());

    for (int i = 0; i < 5; i++) {
      session.answer(ExerciseOutcome.correct);
    }

    expect(session.isComplete, isTrue);
    expect(session.canBeRecorded, isTrue);
    expect(session.currentExercise, isNull);
    expect(session.result.percentage, 100);
    expect(session.result.passed, isTrue);
    expect(session.progress, 1);
  });

  test('los dos ejercicios orales por la alternativa no impiden aprobar', () {
    final LessonSession session = LessonSession.start(lesson: buildLesson());

    // Tres escritos acertados.
    session.answer(ExerciseOutcome.correct);
    session.answer(ExerciseOutcome.correct);
    session.answer(ExerciseOutcome.correct);
    // Los dos orales, sin micrófono.
    session.skipAsUnavailable();
    session.skipAsUnavailable();

    expect(session.isComplete, isTrue);
    expect(session.result.answered, 3);
    expect(session.result.unavailable, 2);
    expect(session.result.percentage, 100);
    expect(session.result.passed, isTrue);
  });

  test('tres de cinco no aprueba la lección', () {
    final LessonSession session = LessonSession.start(lesson: buildLesson());

    session.answer(ExerciseOutcome.correct);
    session.answer(ExerciseOutcome.correct);
    session.answer(ExerciseOutcome.correct);
    session.answer(ExerciseOutcome.incorrect);
    session.answer(ExerciseOutcome.incorrect);

    expect(session.result.percentage, 60);
    expect(session.result.passed, isFalse);
  });

  test('reiniciar la deja como nueva, para reintentarla', () {
    final LessonSession session = LessonSession.start(lesson: buildLesson());

    session.answer(ExerciseOutcome.incorrect);
    session.answer(ExerciseOutcome.incorrect);
    session.restart();

    expect(session.currentIndex, 0);
    expect(session.outcomes, isEmpty);
    expect(session.isComplete, isFalse);
  });

  test('responder más allá del final es un error de programación', () {
    final LessonSession session = LessonSession.start(lesson: buildLesson());

    for (int i = 0; i < 5; i++) {
      session.answer(ExerciseOutcome.correct);
    }

    expect(() => session.answer(ExerciseOutcome.correct), throwsStateError);
  });

  test('las respuestas registradas son inmutables desde fuera', () {
    final LessonSession session = LessonSession.start(lesson: buildLesson());
    session.answer(ExerciseOutcome.correct);

    expect(
      () => session.outcomes.add(ExerciseOutcome.incorrect),
      throwsUnsupportedError,
    );
  });
}
