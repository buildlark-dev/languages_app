/// A1 · Módulo 2 — lecciones y examen.
library;

import '../../core/exam.dart';
import '../../core/exercise.dart';
import '../../core/lesson.dart';

const List<Lesson> a1Module2Lessons = <Lesson>[
  Lesson(
    id: 'A1M2L1',
    title: 'Qué hay en mi casa',
    readingRef: 'A1M2R',
    exercises: <Exercise>[
      MultipleChoiceExercise(
        prompt: '¿Por qué comen en la cocina?',
        options: <String>[
          'Porque la cocina es grande',
          'Porque no hay comedor',
          'Porque no hay sillas',
          'Porque la nevera está ahí',
        ],
        answerIndex: 1,
        explanation:
            'Dice «There isn\'t a dining room, so we eat in the kitchen». El '
            'conector <i>so</i> introduce la consecuencia.',
      ),
      MultipleChoiceExercise(
        prompt: '¿Dónde deja las llaves?',
        options: <String>[
          'Sobre la mesa',
          'En la ventana',
          'Sobre la nevera',
          'Al lado del parque',
        ],
        answerIndex: 2,
        explanation:
            'Dice «I always leave my keys on the fridge». <code>on</code> '
            'indica sobre una superficie.',
      ),
      MultipleChoiceExercise(
        prompt: '___ two windows in the bedroom.',
        options: <String>['There is', 'There are', 'It is', 'They are'],
        answerIndex: 1,
        explanation:
            'Con plural (<i>two windows</i>) se usa <code>there are</code>. '
            '<code>It is</code> describiría algo ya mencionado, no su '
            'existencia.',
      ),
      GapFillExercise(
        sentenceWithGap: '___ a market near here? — Yes, next to the library.',
        acceptedAnswers: <String>['is there'],
        explanation:
            'Para preguntar por la existencia de algo en singular se invierte: '
            '<code>Is there…?</code>',
        hint: 'pregunta de existencia',
      ),
      SentenceBuilderExercise(
        targetSentence: 'The fridge is next to the window.',
        tokens: <String>['window.', 'The', 'next', 'fridge', 'to', 'is', 'the'],
        explanation:
            '<code>next to</code> es una preposición de dos palabras: funciona '
            'como una sola unidad.',
      ),
      ListeningExercise(
        spokenText:
            'There are two bus stops on my street, and there is a park at the '
            'end.',
        question: '¿Cuántas paradas de bus hay?',
        options: <String>['Una', 'Dos', 'Tres', 'Ninguna'],
        answerIndex: 1,
        explanation:
            'Dice «There are two bus stops». El plural <i>are</i> ya anticipa '
            'que serán más de una.',
        transcriptFallback:
            'There are two bus stops on my street, and there is a park at the '
            'end.',
      ),
    ],
  ),
  Lesson(
    id: 'A1M2L2',
    title: 'Ubicar cosas en el espacio',
    exercises: <Exercise>[
      GapFillExercise(
        sentenceWithGap: 'There ___ any chairs in the bathroom.',
        acceptedAnswers: <String>['aren\'t', 'are not'],
        explanation:
            'Con plural y en negativo se usa <code>aren\'t</code> junto a '
            '<code>any</code>.',
        hint: 'negativo en plural',
      ),
      MultipleChoiceExercise(
        prompt: 'Elige el plural correcto de <i>library</i>.',
        options: <String>['librarys', 'libraries', 'librarees', 'library'],
        answerIndex: 1,
        explanation:
            'La <code>-y</code> tras consonante cambia a <code>-ies</code>: '
            '<code>library → libraries</code>.',
      ),
      MultipleChoiceExercise(
        prompt: 'My bedroom is ___ the kitchen and the bathroom.',
        options: <String>['in', 'on', 'between', 'under'],
        answerIndex: 2,
        explanation:
            '<code>between</code> se usa con dos referencias. <code>in</code> '
            'sería dentro y <code>on</code> sobre una superficie.',
      ),
      SentenceBuilderExercise(
        targetSentence: 'There is a park at the end of my street.',
        tokens: <String>[
          'of',
          'There',
          'street.',
          'is',
          'a',
          'the',
          'park',
          'at',
          'end',
          'my',
        ],
        explanation:
            'Estructura de existencia más lugar: primero <i>there is</i>, '
            'después el objeto y por último la ubicación.',
      ),
      PronunciationExercise(
        targetPhrase: 'Is there a bus stop near here?',
        translation: '¿Hay una parada de bus por aquí cerca?',
        explanation:
            'Pregunta práctica de orientación. La entonación sube al final, '
            'como en toda pregunta de respuesta sí o no.',
        writtenFallback:
            'Escribe la pregunta para saber si hay una parada de bus cerca: '
            '«Is there a bus stop near here?»',
      ),
    ],
  ),
];

const Exam a1Module2Exam = Exam(
  id: 'A1M2EX',
  scope: ExamScope.module,
  exercises: <Exercise>[
    MultipleChoiceExercise(
      prompt: '___ a fridge in the kitchen.',
      options: <String>['There are', 'There is', 'It is', 'Have'],
      answerIndex: 1,
      explanation: 'Singular (<i>a fridge</i>) pide <code>there is</code>.',
    ),
    MultipleChoiceExercise(
      prompt: '___ any keys on the table?',
      options: <String>['Is there', 'Are there', 'There are', 'Have there'],
      answerIndex: 1,
      explanation:
          'Plural en pregunta: <code>Are there…?</code> con <code>any</code>.',
    ),
    MultipleChoiceExercise(
      prompt: 'The book is ___ the chair.',
      options: <String>['on', 'in', 'between', 'of'],
      answerIndex: 0,
      explanation:
          '<code>on</code> indica contacto con una superficie: encima de la '
          'silla.',
    ),
    MultipleChoiceExercise(
      prompt: '¿Cuál frase es correcta?',
      options: <String>[
        'There are a window.',
        'There is two windows.',
        'There are two windows.',
        'It are two windows.',
      ],
      answerIndex: 2,
      explanation:
          'El verbo concuerda con el número del objeto: plural '
          '(<i>two windows</i>) pide <code>are</code>.',
    ),
    MultipleChoiceExercise(
      prompt: 'Elige el plural correcto de <i>bench</i>.',
      options: <String>['benchs', 'benches', 'benchies', 'bench'],
      answerIndex: 1,
      explanation:
          'Las palabras terminadas en <code>-ch</code> añaden '
          '<code>-es</code>.',
    ),
    GapFillExercise(
      sentenceWithGap: 'There ___ a park and two libraries in my city.',
      acceptedAnswers: <String>['is'],
      explanation:
          'El verbo concuerda con el <b>primer</b> elemento de la enumeración, '
          'que aquí es singular (<i>a park</i>).',
    ),
    GapFillExercise(
      sentenceWithGap: 'The market is ___ to the bus stop.',
      acceptedAnswers: <String>['next'],
      explanation: '<code>next to</code> significa al lado de.',
    ),
    SentenceBuilderExercise(
      targetSentence: 'There are four chairs in the kitchen.',
      tokens: <String>[
        'kitchen.',
        'There',
        'four',
        'are',
        'the',
        'chairs',
        'in',
      ],
      explanation:
          'Existencia en plural más ubicación con <code>in</code>, que indica '
          'dentro de un espacio.',
    ),
    ListeningExercise(
      spokenText:
          'There is a library on my street, but there aren\'t any '
          'supermarkets.',
      question: '¿Qué NO hay en su calle?',
      options: <String>[
        'Biblioteca',
        'Supermercados',
        'Parque',
        'Parada de bus',
      ],
      answerIndex: 1,
      explanation:
          'Dice «there aren\'t any supermarkets». El conector <i>but</i> marca '
          'el contraste con lo que sí hay.',
      transcriptFallback:
          'There is a library on my street, but there aren\'t any '
          'supermarkets.',
    ),
    PronunciationExercise(
      targetPhrase: 'There are two bedrooms and one bathroom.',
      translation: 'Hay dos dormitorios y un baño.',
      explanation:
          'Practica el contraste entre <i>there are</i> en plural y el '
          'singular <i>one bathroom</i> en la misma frase.',
      writtenFallback:
          'Escribe la descripción: «There are two bedrooms and one bathroom.»',
    ),
  ],
);
