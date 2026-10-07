/// A1 · Módulo 1 — lecciones y examen.
///
/// Lo **calificable** del módulo. Incluye las preguntas de comprensión de la
/// lectura, que cuentan para el umbral del 70 % (FR-013), y al menos un
/// ejercicio de escucha y uno de pronunciación, que las invariantes 10 y 11 del
/// contrato de contenido exigen.
library;

import '../../core/exam.dart';
import '../../core/exercise.dart';
import '../../core/lesson.dart';

const List<Lesson> a1Module1Lessons = <Lesson>[
  Lesson(
    id: 'A1M1L1',
    title: 'Presentarse y preguntar',
    readingRef: 'A1M1R',
    exercises: <Exercise>[
      // Comprensión de la lectura. Cuenta para el 70 % (FR-013).
      MultipleChoiceExercise(
        prompt: '¿Dónde vive Elena ahora?',
        options: <String>[
          'En Bogotá',
          'En Rionegro',
          'En el hospital',
          'Con sus estudiantes',
        ],
        answerIndex: 1,
        explanation:
            'Dice «but now I live in Rionegro». El conector <i>but</i> marca '
            'el contraste con su lugar de origen, que es Bogotá.',
      ),
      MultipleChoiceExercise(
        prompt: 'El trabajo de la hermana de Elena es…',
        options: <String>[
          'enfermera',
          'médica',
          'profesora de inglés',
          'cocinera',
        ],
        answerIndex: 2,
        explanation:
            'Dice «She\'s an English teacher». Fíjate en el artículo '
            '<code>an</code>: en inglés las profesiones siempre lo llevan.',
      ),
      MultipleChoiceExercise(
        prompt: 'She ___ a nurse at the hospital.',
        options: <String>['am', 'is', 'are', 'be'],
        answerIndex: 1,
        explanation:
            'Con <code>she</code> el verbo <i>be</i> toma la forma '
            '<code>is</code>. Es tercera persona del singular.',
      ),
      GapFillExercise(
        sentenceWithGap: '___ you from Peru? — No, I ___ from Chile.',
        acceptedAnswers: <String>['are am', 'are, am'],
        explanation:
            'La pregunta pone el verbo delante del sujeto '
            '(<code>Are you…?</code>) y la respuesta lo devuelve a su sitio '
            '(<code>I am…</code>).',
        hint: 'pregunta y respuesta con to be',
      ),
      SentenceBuilderExercise(
        targetSentence: 'My sister is a teacher.',
        tokens: <String>['a', 'My', 'teacher.', 'sister', 'is'],
        explanation:
            'Orden fijo del inglés: sujeto, verbo, atributo. Y la profesión '
            'lleva artículo: <code>a teacher</code>.',
      ),
      ListeningExercise(
        spokenText:
            'Hello, my name is Elena. I am a nurse and I am from Bogota.',
        question: '¿Cuál es su profesión?',
        options: <String>['Profesora', 'Enfermera', 'Estudiante', 'Médica'],
        answerIndex: 1,
        explanation:
            'Dice «I am a nurse». <i>Nurse</i> es enfermera; <i>doctor</i> '
            'sería médica.',
        transcriptFallback:
            'Hello, my name is Elena. I am a nurse and I am from Bogota.',
      ),
      PronunciationExercise(
        targetPhrase: 'Nice to meet you.',
        translation: 'Encantado de conocerte.',
        explanation:
            'Fórmula fija al presentarse. No se traduce palabra por palabra: '
            'literalmente sería «agradable conocerte».',
        writtenFallback:
            'Escribe la fórmula de cortesía al conocer a alguien: '
            '«Nice to meet you.»',
      ),
    ],
  ),
  Lesson(
    id: 'A1M1L2',
    title: 'Edad, dirección y datos personales',
    exercises: <Exercise>[
      GapFillExercise(
        sentenceWithGap: 'My brother ___ a doctor. He works in Cali.',
        acceptedAnswers: <String>['is', '\'s'],
        explanation:
            'Tercera persona del singular: <code>is</code>. La contracción '
            '<code>\'s</code> también es correcta.',
        hint: 'tercera persona',
      ),
      GapFillExercise(
        sentenceWithGap: 'I ___ twenty-nine years old.',
        acceptedAnswers: <String>['am', '\'m'],
        explanation:
            'La edad se dice con <i>be</i>, no con «tener». '
            '<s>I have 29 years</s> es el calco más frecuente del español.',
        hint: 'la edad no se «tiene» en inglés',
      ),
      MultipleChoiceExercise(
        prompt: 'Elige la forma correcta: «Ella no es colombiana.»',
        options: <String>[
          'She not is Colombian.',
          'She isn\'t Colombian.',
          'She don\'t is Colombian.',
          'She no is Colombian.',
        ],
        answerIndex: 1,
        explanation:
            'La negación de <i>be</i> se forma con <code>not</code> después '
            'del verbo: <code>is not</code> → <code>isn\'t</code>. No se usa '
            '<i>don\'t</i> con <i>be</i>.',
      ),
      SentenceBuilderExercise(
        targetSentence: 'What is your phone number?',
        tokens: <String>['your', 'What', 'number?', 'is', 'phone'],
        explanation:
            'En las preguntas con <i>wh-</i> el verbo va justo después de la '
            'palabra interrogativa: <code>What is…?</code>',
      ),
      PronunciationExercise(
        targetPhrase: 'How do you spell your surname?',
        translation: '¿Cómo se deletrea tu apellido?',
        explanation:
            'Pregunta imprescindible para datos personales. <i>Spell</i> es '
            'deletrear, algo que en inglés se pide constantemente.',
        writtenFallback:
            'Escribe la pregunta para pedir que alguien deletree su '
            'apellido: «How do you spell your surname?»',
      ),
    ],
  ),
];

const Exam a1Module1Exam = Exam(
  id: 'A1M1EX',
  scope: ExamScope.module,
  exercises: <Exercise>[
    MultipleChoiceExercise(
      prompt: 'I ___ from Medellín.',
      options: <String>['am', 'is', 'are', 'be'],
      answerIndex: 0,
      explanation: 'Con <code>I</code> la forma es siempre <code>am</code>.',
    ),
    MultipleChoiceExercise(
      prompt: 'They ___ my neighbours.',
      options: <String>['am', 'is', 'are', 'be'],
      answerIndex: 2,
      explanation:
          'Con <code>they</code>, plural, la forma es <code>are</code>.',
    ),
    MultipleChoiceExercise(
      prompt: '___ she a student?',
      options: <String>['Is', 'Are', 'Am', 'Be'],
      answerIndex: 0,
      explanation:
          'Para preguntar, <i>be</i> va delante del sujeto, y con '
          '<code>she</code> la forma es <code>is</code>.',
    ),
    MultipleChoiceExercise(
      prompt: '¿Cuál frase es correcta?',
      options: <String>[
        'He is teacher.',
        'He is a teacher.',
        'He teacher.',
        'He has a teacher job.',
      ],
      answerIndex: 1,
      explanation:
          'Las profesiones llevan artículo en inglés: <code>a teacher</code>. '
          'Omitirlo es un calco del español.',
    ),
    MultipleChoiceExercise(
      prompt: 'Traduce: «Tengo treinta años.»',
      options: <String>[
        'I have thirty years.',
        'I am thirty years old.',
        'I have thirty years old.',
        'I am thirty years.',
      ],
      answerIndex: 1,
      explanation:
          'La edad se dice con <i>be</i> y con <code>years old</code>: '
          '<code>I am thirty years old</code>.',
    ),
    GapFillExercise(
      sentenceWithGap: 'We ___ not from Bogotá; we ___ from Cali.',
      acceptedAnswers: <String>['are are'],
      explanation:
          'Con <code>we</code> la forma es <code>are</code> en las dos '
          'partes de la frase.',
    ),
    GapFillExercise(
      sentenceWithGap: 'His neighbour ___ very friendly.',
      acceptedAnswers: <String>['is', '\'s'],
      explanation:
          '<code>His neighbour</code> es tercera persona del singular, así '
          'que el verbo es <code>is</code>.',
    ),
    SentenceBuilderExercise(
      targetSentence: 'Are you a student here?',
      tokens: <String>['you', 'Are', 'here?', 'a', 'student'],
      explanation:
          'La pregunta invierte el orden: primero el verbo, después el '
          'sujeto.',
    ),
    ListeningExercise(
      spokenText:
          'This is my friend Pedro. He is twenty years old and he is a '
          'student.',
      question: '¿Cuántos años tiene Pedro?',
      options: <String>['Doce', 'Veinte', 'Veintidós', 'Treinta'],
      answerIndex: 1,
      explanation:
          'Dice «twenty years old». Cuidado de no confundir <i>twenty</i> '
          '(veinte) con <i>twelve</i> (doce): es una confusión clásica.',
      transcriptFallback:
          'This is my friend Pedro. He is twenty years old and he is a '
          'student.',
    ),
    PronunciationExercise(
      targetPhrase: 'I am from Colombia and I am a student.',
      translation: 'Soy de Colombia y soy estudiante.',
      explanation:
          'Repite el sujeto en las dos partes de la frase, porque en inglés '
          'no puede omitirse.',
      writtenFallback:
          'Escribe la presentación completa: «I am from Colombia and I am a '
          'student.»',
    ),
  ],
);
