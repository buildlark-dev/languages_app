/// A1 · Módulo 3 — lecciones y examen.
library;

import '../../core/exam.dart';
import '../../core/exercise.dart';
import '../../core/lesson.dart';

const List<Lesson> a1Module3Lessons = <Lesson>[
  Lesson(
    id: 'A1M3L1',
    title: 'Contar mi día',
    readingRef: 'A1M3R',
    exercises: <Exercise>[
      MultipleChoiceExercise(
        prompt: '¿A qué hora salen de casa?',
        options: <String>[
          'A las cinco y media',
          'A las siete',
          'A las ocho',
          'A las once',
        ],
        answerIndex: 1,
        explanation:
            'Dice «we leave home at seven». <i>Half past five</i> es la hora de '
            'despertarse, no de salir.',
      ),
      MultipleChoiceExercise(
        prompt: '¿Por qué cocina él la cena?',
        options: <String>[
          'Porque le gusta cocinar',
          'Porque su hermana termina a las ocho',
          'Porque su hermana no sabe cocinar',
          'Porque llega a las cinco',
        ],
        answerIndex: 1,
        explanation:
            'Dice «I cook dinner, because my sister finishes at eight». El '
            'conector <i>because</i> introduce el motivo.',
      ),
      MultipleChoiceExercise(
        prompt: 'She ___ English in the afternoon.',
        options: <String>['teach', 'teaches', 'teachs', 'is teach'],
        answerIndex: 1,
        explanation:
            'Tercera persona del singular con verbo en <code>-ch</code>: añade '
            '<code>-es</code> → <code>teaches</code>.',
      ),
      GapFillExercise(
        sentenceWithGap: 'He ___ work on Sundays.',
        acceptedAnswers: <String>['doesn\'t', 'does not'],
        explanation:
            'Negativo en tercera persona: <code>doesn\'t</code> y el verbo '
            'principal <b>sin</b> -s.',
        hint: 'negativo en tercera persona',
      ),
      SentenceBuilderExercise(
        targetSentence: 'I always wake up at six.',
        tokens: <String>['up', 'I', 'six.', 'always', 'wake', 'at'],
        explanation:
            'El adverbio de frecuencia va <b>antes</b> del verbo principal: '
            '<code>I always wake up</code>.',
      ),
      ListeningExercise(
        spokenText:
            'I usually have breakfast at seven, and I never go to bed before '
            'eleven.',
        question: '¿Qué dice sobre irse a la cama?',
        options: <String>[
          'Que se acuesta antes de las once',
          'Que nunca se acuesta antes de las once',
          'Que se acuesta a las siete',
          'Que no desayuna',
        ],
        answerIndex: 1,
        explanation:
            'Dice «I never go to bed before eleven». <i>Never</i> niega sin '
            'necesidad de <i>don\'t</i>.',
        transcriptFallback:
            'I usually have breakfast at seven, and I never go to bed before '
            'eleven.',
      ),
    ],
  ),
  Lesson(
    id: 'A1M3L2',
    title: 'Preguntar por la rutina de otra persona',
    exercises: <Exercise>[
      MultipleChoiceExercise(
        prompt: '___ she study English every day?',
        options: <String>['Do', 'Does', 'Is', 'Are'],
        answerIndex: 1,
        explanation:
            'Pregunta en tercera persona del singular: '
            '<code>Does she study…?</code>',
      ),
      MultipleChoiceExercise(
        prompt: '¿Cuál frase es correcta?',
        options: <String>[
          'She doesn\'t works here.',
          'She doesn\'t work here.',
          'She don\'t work here.',
          'She not work here.',
        ],
        answerIndex: 1,
        explanation:
            'La regla de oro: con <code>doesn\'t</code>, el verbo principal '
            'pierde la -s.',
      ),
      GapFillExercise(
        sentenceWithGap: '___ you usually get home at five?',
        acceptedAnswers: <String>['do'],
        explanation:
            'Con <code>you</code> el auxiliar es <code>do</code>, no '
            '<code>does</code>.',
        hint: 'auxiliar de pregunta',
      ),
      SentenceBuilderExercise(
        targetSentence: 'My sister is never late.',
        tokens: <String>['never', 'My', 'late.', 'sister', 'is'],
        explanation:
            'Con el verbo <i>be</i> el adverbio de frecuencia va '
            '<b>después</b>, no antes: <code>is never</code>.',
      ),
      PronunciationExercise(
        targetPhrase: 'What time do you usually wake up?',
        translation: '¿A qué hora te despiertas normalmente?',
        explanation:
            'Pregunta de rutina con <i>what time</i>. El auxiliar <i>do</i> va '
            'después de la expresión interrogativa.',
        writtenFallback:
            'Escribe la pregunta sobre la hora de despertarse: '
            '«What time do you usually wake up?»',
      ),
    ],
  ),
];

const Exam a1Module3Exam = Exam(
  id: 'A1M3EX',
  scope: ExamScope.module,
  exercises: <Exercise>[
    MultipleChoiceExercise(
      prompt: 'He ___ at the hospital.',
      options: <String>['work', 'works', 'working', 'is work'],
      answerIndex: 1,
      explanation: 'Tercera persona del singular: añade <code>-s</code>.',
    ),
    MultipleChoiceExercise(
      prompt: 'She ___ her classes in the morning.',
      options: <String>['studys', 'studies', 'studyes', 'study'],
      answerIndex: 1,
      explanation:
          'La <code>-y</code> tras consonante cambia a <code>-ies</code>: '
          '<code>study → studies</code>.',
    ),
    MultipleChoiceExercise(
      prompt: '___ they work on Saturdays?',
      options: <String>['Does', 'Do', 'Is', 'Are'],
      answerIndex: 1,
      explanation:
          'Con <code>they</code>, plural, el auxiliar es <code>do</code>.',
    ),
    MultipleChoiceExercise(
      prompt: '¿Dónde va el adverbio? «Ella siempre llega tarde.»',
      options: <String>[
        'She always is late.',
        'She is always late.',
        'Always she is late.',
        'She is late always.',
      ],
      answerIndex: 1,
      explanation:
          'Con <i>be</i> el adverbio de frecuencia va después del verbo: '
          '<code>is always late</code>.',
    ),
    MultipleChoiceExercise(
      prompt: 'I ___ have breakfast at home; I eat at work.',
      options: <String>['never', 'always', 'usually', 'often'],
      answerIndex: 0,
      explanation:
          'La segunda frase dice que come en el trabajo, así que el adverbio '
          'tiene que negar la primera: <code>never</code>.',
    ),
    GapFillExercise(
      sentenceWithGap: 'My brother ___ (not) cook dinner on Mondays.',
      acceptedAnswers: <String>['doesn\'t', 'does not'],
      explanation:
          'Tercera persona del singular en negativo: <code>doesn\'t</code>.',
    ),
    GapFillExercise(
      sentenceWithGap: 'We ___ home at seven every morning.',
      acceptedAnswers: <String>['leave'],
      explanation:
          'Con <code>we</code> el verbo va sin <code>-s</code>: '
          '<code>leave</code>.',
    ),
    SentenceBuilderExercise(
      targetSentence: 'She usually finishes work at four.',
      tokens: <String>['work', 'She', 'four.', 'usually', 'finishes', 'at'],
      explanation:
          'Adverbio antes del verbo principal, y tercera persona con '
          '<code>-es</code> porque <i>finish</i> termina en <code>-sh</code>.',
    ),
    ListeningExercise(
      spokenText:
          'My sister does not work in the morning. She teaches English in the '
          'afternoon.',
      question: '¿Cuándo trabaja su hermana?',
      options: <String>[
        'Por la mañana',
        'Por la tarde',
        'Por la noche',
        'No trabaja',
      ],
      answerIndex: 1,
      explanation:
          'Dice «She teaches English in the afternoon», después de negar la '
          'mañana.',
      transcriptFallback:
          'My sister does not work in the morning. She teaches English in the '
          'afternoon.',
    ),
    PronunciationExercise(
      targetPhrase: 'She doesn\'t work on Sundays.',
      translation: 'Ella no trabaja los domingos.',
      explanation:
          'Practica la contracción <i>doesn\'t</i> y el verbo sin -s detrás, '
          'que es el error más común del nivel.',
      writtenFallback:
          'Escribe la negación en tercera persona: '
          '«She doesn\'t work on Sundays.»',
    ),
  ],
);
