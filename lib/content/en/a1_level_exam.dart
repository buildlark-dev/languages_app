/// A1 · Examen de nivel.
///
/// Es la puerta a A2: se aprueba con el 80 % (FR-022). Mezcla las cuatro
/// destrezas y los cuatro módulos, para que aprobarlo signifique dominar el
/// nivel y no solo recordar el último módulo.
///
/// **No** incluye ejercicios de pronunciación a propósito. La invariante 22 del
/// contrato de contenido lo permite, y aquí se aprovecha: el examen que decide
/// el paso de nivel no debe poner en desventaja a quien no tenga micrófono. La
/// escucha sí entra, porque su alternativa accesible es una transcripción que no
/// pierde nada del ejercicio.
library;

import '../../core/exam.dart';
import '../../core/exercise.dart';

const Exam a1LevelExam = Exam(
  id: 'A1EX',
  scope: ExamScope.level,
  exercises: <Exercise>[
    // Módulo 1: to be, identidad.
    MultipleChoiceExercise(
      prompt: 'My neighbours ___ from Peru.',
      options: <String>['is', 'am', 'are', 'be'],
      answerIndex: 2,
      explanation:
          '<i>Neighbours</i> es plural, así que el verbo <i>be</i> toma '
          '<code>are</code>.',
    ),
    MultipleChoiceExercise(
      prompt: 'Traduce: «Ella tiene veinte años.»',
      options: <String>[
        'She has twenty years.',
        'She is twenty years old.',
        'She has twenty years old.',
        'She is twenty years.',
      ],
      answerIndex: 1,
      explanation:
          'La edad se expresa con <i>be</i> y <code>years old</code>, nunca '
          'con <i>have</i>.',
    ),
    // Módulo 2: there is / there are, lugar.
    MultipleChoiceExercise(
      prompt: '___ any chairs in the kitchen?',
      options: <String>['Is there', 'Are there', 'There are', 'Have there'],
      answerIndex: 1,
      explanation:
          'Plural en pregunta: <code>Are there…?</code>, acompañado de '
          '<code>any</code>.',
    ),
    GapFillExercise(
      sentenceWithGap: 'The market is ___ to the library.',
      acceptedAnswers: <String>['next'],
      explanation:
          '<code>next to</code> indica proximidad inmediata: al lado de.',
    ),
    // Módulo 3: presente simple y frecuencia.
    MultipleChoiceExercise(
      prompt: 'She ___ English every afternoon.',
      options: <String>['teach', 'teachs', 'teaches', 'is teach'],
      answerIndex: 2,
      explanation:
          'Tercera persona con verbo en <code>-ch</code>: añade '
          '<code>-es</code>.',
    ),
    MultipleChoiceExercise(
      prompt: '¿Cuál frase es correcta?',
      options: <String>[
        'He doesn\'t works on Sundays.',
        'He don\'t work on Sundays.',
        'He doesn\'t work on Sundays.',
        'He not work on Sundays.',
      ],
      answerIndex: 2,
      explanation:
          'Con <code>doesn\'t</code>, el verbo principal pierde la -s. Es el '
          'error más repetido de todo el nivel.',
    ),
    GapFillExercise(
      sentenceWithGap: 'I ___ wake up at five; I hate early mornings.',
      acceptedAnswers: <String>['never'],
      explanation:
          'La segunda frase justifica la negación, así que el adverbio de '
          'frecuencia es <code>never</code>, delante del verbo principal.',
    ),
    // Módulo 4: like + -ing, can, pronombres objeto.
    MultipleChoiceExercise(
      prompt: 'We love ___ on Sundays.',
      options: <String>['cook', 'to cooking', 'cooking', 'cooks'],
      answerIndex: 2,
      explanation:
          'Después de <code>love</code> el verbo siguiente va en '
          '<code>-ing</code>.',
    ),
    MultipleChoiceExercise(
      prompt: 'She ___ swim, but she can drive.',
      options: <String>['can\'t', 'doesn\'t can', 'cans not', 'not can'],
      answerIndex: 0,
      explanation:
          'El negativo de <code>can</code> es <code>can\'t</code>, sin '
          'auxiliar.',
    ),
    GapFillExercise(
      sentenceWithGap: 'I don\'t like cheese. I never eat ___.',
      acceptedAnswers: <String>['it'],
      explanation:
          'El pronombre objeto para una cosa es <code>it</code>, y va después '
          'del verbo.',
    ),
    // Producción escrita, los dos tipos.
    SentenceBuilderExercise(
      targetSentence: 'There are two parks in my city.',
      tokens: <String>['city.', 'There', 'two', 'are', 'my', 'parks', 'in'],
      explanation:
          'Existencia en plural más ubicación: <i>there are</i>, el objeto y '
          'después el lugar.',
    ),
    SentenceBuilderExercise(
      targetSentence: 'My sister usually finishes work at four.',
      tokens: <String>[
        'work',
        'My',
        'four.',
        'usually',
        'sister',
        'finishes',
        'at',
      ],
      explanation:
          'Adverbio de frecuencia antes del verbo principal, y tercera persona '
          'con <code>-es</code>.',
    ),
    // Escucha. Su alternativa es la transcripción, que no quita dificultad.
    ListeningExercise(
      spokenText:
          'Hello. My name is Elena. I am a nurse and I work at the hospital '
          'from eight to four. I never work on Sundays.',
      question: '¿Cuándo no trabaja Elena?',
      options: <String>['Los sábados', 'Los domingos', 'Por la tarde', 'Nunca'],
      answerIndex: 1,
      explanation:
          'Dice «I never work on Sundays». Cuidado con la última opción: '
          '«nunca» a secas contradiría que trabaja de ocho a cuatro.',
      transcriptFallback:
          'Hello. My name is Elena. I am a nurse and I work at the hospital '
          'from eight to four. I never work on Sundays.',
    ),
    ListeningExercise(
      spokenText:
          'There is a market next to the library, and there are two bus stops '
          'on my street.',
      question: '¿Qué hay al lado de la biblioteca?',
      options: <String>[
        'Un parque',
        'Un mercado',
        'Una parada de bus',
        'Una cocina',
      ],
      answerIndex: 1,
      explanation:
          'Dice «There is a market next to the library». Las dos paradas están '
          'en su calle, no al lado de la biblioteca.',
      transcriptFallback:
          'There is a market next to the library, and there are two bus stops '
          'on my street.',
    ),
  ],
);
