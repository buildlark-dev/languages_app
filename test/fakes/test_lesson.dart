/// Módulo y lección de prueba, con los cinco tipos de ejercicio.
///
/// Se construye solo con contratos de `core`, igual que el catálogo falso: así la
/// prueba de la pantalla no depende del contenido real de inglés, y cambiar una
/// explicación de A1M1 no rompe pruebas de interfaz.
library;

import 'package:languages_app/core/exam.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/core/lesson.dart';
import 'package:languages_app/core/module.dart';
import 'package:languages_app/core/teaching_material.dart';
import 'package:languages_app/core/vocabulary_item.dart';

const Lesson testLesson = Lesson(
  id: 'TM1L1',
  title: 'Lección de prueba',
  readingRef: 'TM1R',
  exercises: <Exercise>[
    MultipleChoiceExercise(
      prompt: 'She ___ a nurse.',
      options: <String>['am', 'is', 'are'],
      answerIndex: 1,
      explanation:
          'Con <code>she</code> se usa la tercera persona del singular.',
    ),
    GapFillExercise(
      sentenceWithGap: 'My brother ___ a doctor.',
      acceptedAnswers: <String>['is', '\'s'],
      explanation: 'Tercera persona del singular del verbo <i>be</i>.',
      hint: 'tercera persona',
    ),
    SentenceBuilderExercise(
      targetSentence: 'My sister is a teacher.',
      tokens: <String>['My', 'sister', 'is', 'a', 'teacher.'],
      explanation: 'Orden fijo: sujeto, verbo y atributo con artículo.',
    ),
    ListeningExercise(
      spokenText: 'I am a nurse.',
      question: '¿Cuál es su profesión?',
      options: <String>['Profesora', 'Enfermera', 'Médica'],
      answerIndex: 1,
      explanation: 'Dice <i>nurse</i>, que es enfermera.',
      transcriptFallback: 'I am a nurse.',
    ),
    PronunciationExercise(
      targetPhrase: 'Nice to meet you.',
      translation: 'Encantado de conocerte.',
      explanation: 'Fórmula fija de presentación, no se traduce literalmente.',
      writtenFallback: 'Nice to meet you.',
    ),
  ],
);

const Module testModule = Module(
  id: 'TM1',
  order: 1,
  title: 'Módulo de prueba',
  canDo: 'Presentarte y decir a qué se dedica alguien.',
  vocabulary: <VocabularyItem>[
    VocabularyItem(term: 'name', translation: 'el nombre', hint: '🪪'),
    VocabularyItem(term: 'nurse', translation: 'la enfermera', hint: '🩺'),
  ],
  grammar: GrammarExplanation(
    title: 'El verbo <i>to be</i>',
    bodyHtml:
        '<p>El verbo <code>be</code> cambia según la persona.</p>'
        '<table><tr><th>Sujeto</th><th>Forma</th></tr>'
        '<tr><td>I</td><td>am</td></tr>'
        '<tr><td>she</td><td>is</td></tr></table>',
  ),
  examples: <BilingualExample>[
    BilingualExample(target: 'She is a nurse.', spanish: 'Ella es enfermera.'),
  ],
  reading: ReadingPassage(
    id: 'TM1R',
    title: 'A new neighbour',
    paragraphs: <String>['My name is Elena. I am a nurse.'],
  ),
  lessons: <Lesson>[testLesson],
  moduleExam: Exam(
    id: 'TM1EX',
    scope: ExamScope.module,
    exercises: <Exercise>[],
  ),
);
