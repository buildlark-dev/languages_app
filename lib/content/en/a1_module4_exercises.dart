/// A1 · Módulo 4 — lecciones y examen.
library;

import '../../core/exam.dart';
import '../../core/exercise.dart';
import '../../core/lesson.dart';

const List<Lesson> a1Module4Lessons = <Lesson>[
  Lesson(
    id: 'A1M4L1',
    title: 'Gustos y preferencias',
    readingRef: 'A1M4R',
    exercises: <Exercise>[
      MultipleChoiceExercise(
        prompt: '¿Por qué nunca ponen queso en la mesa?',
        options: <String>[
          'Porque a nadie le gusta',
          'Porque Elena no puede comerlo',
          'Porque no lo compran',
          'Porque es picante',
        ],
        answerIndex: 1,
        explanation:
            'Dice «She can\'t eat cheese, so we never put it on the table». '
            '<i>Can\'t</i> aquí indica imposibilidad, no falta de ganas.',
      ),
      MultipleChoiceExercise(
        prompt: '¿Qué hacen por separado después del almuerzo?',
        options: <String>[
          'Cocinar y lavar',
          'Dibujar y nadar',
          'Comer y hablar',
          'Nada, lo hacen todo juntos',
        ],
        answerIndex: 1,
        explanation:
            'Dice «my sister draws and I swim», y después explica que no lo '
            'hacen juntos porque a cada una le gusta una cosa distinta.',
      ),
      MultipleChoiceExercise(
        prompt: 'I like ___ rice and beans.',
        options: <String>['cook', 'to cooking', 'cooking', 'cooks'],
        answerIndex: 2,
        explanation:
            'Después de <code>like</code> el segundo verbo va en '
            '<code>-ing</code>. <s>I like cook</s> es el error más frecuente '
            'del nivel.',
      ),
      GapFillExercise(
        sentenceWithGap: 'She ___ drive, but she ___ swim.',
        acceptedAnswers: <String>['can can\'t', 'can cannot'],
        explanation:
            '<code>can</code> no cambia según la persona y nunca lleva '
            '<i>to</i>. Su negativo es <code>can\'t</code>.',
        hint: 'habilidad afirmativa y negativa',
      ),
      SentenceBuilderExercise(
        targetSentence: 'I really like it.',
        tokens: <String>['like', 'I', 'it.', 'really'],
        explanation:
            'El pronombre objeto <code>it</code> va después del verbo. '
            '<i>Really</i> intensifica el gusto.',
      ),
      ListeningExercise(
        spokenText:
            'I love cooking, but I hate washing up. My sister can cook very '
            'well.',
        question: '¿Qué odia hacer?',
        options: <String>[
          'Cocinar',
          'Lavar los platos',
          'Comer pollo',
          'Nadar',
        ],
        answerIndex: 1,
        explanation:
            'Dice «I hate washing up». <i>Washing up</i> es lavar los platos, '
            'no lavarse.',
        transcriptFallback:
            'I love cooking, but I hate washing up. My sister can cook very '
            'well.',
      ),
    ],
  ),
  Lesson(
    id: 'A1M4L2',
    title: 'Capacidades y pedir comida',
    exercises: <Exercise>[
      MultipleChoiceExercise(
        prompt: '¿Cuál frase es correcta?',
        options: <String>[
          'She cans swim.',
          'She can to swim.',
          'She can swim.',
          'She can swims.',
        ],
        answerIndex: 2,
        explanation:
            '<code>can</code> no toma <code>-s</code> ni va seguido de '
            '<i>to</i>, y el verbo siguiente queda en infinitivo sin '
            'partícula.',
      ),
      MultipleChoiceExercise(
        prompt: 'I work with ___ every Sunday.',
        options: <String>['they', 'them', 'their', 'theirs'],
        answerIndex: 1,
        explanation:
            'Después de una preposición va el pronombre objeto: '
            '<code>with them</code>.',
      ),
      GapFillExercise(
        sentenceWithGap: 'We don\'t mind ___ (wait) for them.',
        acceptedAnswers: <String>['waiting'],
        explanation:
            '<code>don\'t mind</code> pertenece al grupo que pide '
            '<code>-ing</code> en el verbo siguiente.',
        hint: 'verbo en -ing',
      ),
      SentenceBuilderExercise(
        targetSentence: 'Can you cook spicy food?',
        tokens: <String>['you', 'Can', 'food?', 'cook', 'spicy'],
        explanation:
            'Para preguntar con <i>can</i> se invierte el orden: primero '
            '<code>Can</code>, después el sujeto.',
      ),
      PronunciationExercise(
        targetPhrase: 'What kind of food do you like?',
        translation: '¿Qué tipo de comida te gusta?',
        explanation:
            'Pregunta abierta sobre gustos. <i>Kind of</i> equivale a «tipo '
            'de» y se pronuncia casi unido.',
        writtenFallback:
            'Escribe la pregunta sobre preferencias de comida: '
            '«What kind of food do you like?»',
      ),
    ],
  ),
];

const Exam a1Module4Exam = Exam(
  id: 'A1M4EX',
  scope: ExamScope.module,
  exercises: <Exercise>[
    MultipleChoiceExercise(
      prompt: 'They love ___ at the weekend.',
      options: <String>['swim', 'swimming', 'to swimming', 'swims'],
      answerIndex: 1,
      explanation:
          'Después de <code>love</code>, el verbo siguiente va en '
          '<code>-ing</code>.',
    ),
    MultipleChoiceExercise(
      prompt: 'He ___ drive, he hasn\'t got a licence.',
      options: <String>['can\'t', 'cans not', 'doesn\'t can', 'not can'],
      answerIndex: 0,
      explanation:
          'El negativo de <code>can</code> es <code>can\'t</code>, sin '
          'auxiliar <i>do</i>.',
    ),
    MultipleChoiceExercise(
      prompt: 'I don\'t like cheese. I never eat ___.',
      options: <String>['it', 'its', 'him', 'they'],
      answerIndex: 0,
      explanation:
          'El pronombre objeto para una cosa es <code>it</code>, y va después '
          'del verbo.',
    ),
    MultipleChoiceExercise(
      prompt: 'Traduce: «Me encanta dibujar.»',
      options: <String>[
        'I love draw.',
        'I love to drawing.',
        'I love drawing.',
        'I loving draw.',
      ],
      answerIndex: 2,
      explanation:
          '<code>love</code> pide <code>-ing</code>: '
          '<code>I love drawing</code>.',
    ),
    MultipleChoiceExercise(
      prompt: '___ she cook rice and beans?',
      options: <String>['Cans', 'Can', 'Does can', 'Is can'],
      answerIndex: 1,
      explanation:
          'Para preguntar por una habilidad, <code>can</code> se pone delante '
          'del sujeto, sin auxiliar.',
    ),
    GapFillExercise(
      sentenceWithGap: 'My sister hates ___ (wash) up after lunch.',
      acceptedAnswers: <String>['washing'],
      explanation:
          '<code>hate</code> pertenece al grupo que pide <code>-ing</code>.',
    ),
    GapFillExercise(
      sentenceWithGap: 'We work with ___ every Sunday. (they)',
      acceptedAnswers: <String>['them'],
      explanation:
          'Tras preposición se usa el pronombre objeto: <code>them</code>.',
    ),
    SentenceBuilderExercise(
      targetSentence: 'She can cook very well.',
      tokens: <String>['cook', 'She', 'well.', 'can', 'very'],
      explanation:
          'Tras <code>can</code>, el verbo va en infinitivo sin <i>to</i> y sin '
          '<code>-s</code>.',
    ),
    ListeningExercise(
      spokenText: 'She really likes spicy food, but we do not like it much.',
      question: '¿A quién le gusta mucho lo picante?',
      options: <String>[
        'A ella',
        'A nosotros',
        'A nadie',
        'A los dos por igual',
      ],
      answerIndex: 0,
      explanation:
          'Dice «She really likes spicy food», y después contrasta con '
          '«we do not like it much».',
      transcriptFallback:
          'She really likes spicy food, but we do not like it much.',
    ),
    PronunciationExercise(
      targetPhrase: 'I like cooking, but I can\'t draw.',
      translation: 'Me gusta cocinar, pero no sé dibujar.',
      explanation:
          'Reúne las dos estructuras del módulo: <i>like + -ing</i> para el '
          'gusto y <i>can\'t</i> para la falta de habilidad.',
      writtenFallback:
          'Escribe la frase que combina gusto y habilidad: '
          '«I like cooking, but I can\'t draw.»',
    ),
  ],
);
