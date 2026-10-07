/// Prueba de nivelación de inglés.
///
/// Cada ítem declara el nivel MCER que **discrimina**, y la lista cubre de A1 a
/// C1. Que incluya niveles sin contenido construido es deliberado y lo autoriza
/// la invariante 20 del contrato de contenido: la prueba estima el nivel real de
/// la persona, no el nivel al que la app puede llevarla hoy.
///
/// De esa distinción vive FR-035 y FR-036: el **nivel estimado** puede ser B1,
/// mientras el **nivel asignado** se limita a A1 porque es el único con
/// contenido. Decirle a alguien que está en B1 y a la vez que empiece por A1 es
/// honesto; rebajar la estimación para que cuadre con lo que existe, no.
///
/// Es corta a propósito: dos ítems por nivel. Una nivelación que cansa se
/// abandona, y abandonarla manda a la persona a A1, que es justo lo que trata de
/// evitar.
library;

import '../../core/exam.dart';
import '../../core/exercise.dart';

const PlacementExam englishPlacementTest = PlacementExam(
  id: 'ENPLACE',
  items: <PlacementItem>[
    // A1 — to be, there is, presente simple.
    PlacementItem(
      levelId: 'A1',
      exercise: MultipleChoiceExercise(
        prompt: 'She ___ a teacher.',
        options: <String>['am', 'is', 'are', 'be'],
        answerIndex: 1,
        explanation:
            'Tercera persona del singular del verbo <i>be</i>: '
            '<code>is</code>.',
      ),
    ),
    PlacementItem(
      levelId: 'A1',
      exercise: MultipleChoiceExercise(
        prompt: 'He ___ work on Sundays.',
        options: <String>['don\'t', 'doesn\'t', 'isn\'t', 'not'],
        answerIndex: 1,
        explanation:
            'Negativo del presente simple en tercera persona: '
            '<code>doesn\'t</code>.',
      ),
    ),
    // A2 — pasado simple, comparativos.
    PlacementItem(
      levelId: 'A2',
      exercise: MultipleChoiceExercise(
        prompt: 'Yesterday I ___ to the market.',
        options: <String>['go', 'goed', 'went', 'gone'],
        answerIndex: 2,
        explanation:
            'Pasado simple irregular de <i>go</i>: <code>went</code>.',
      ),
    ),
    PlacementItem(
      levelId: 'A2',
      exercise: MultipleChoiceExercise(
        prompt: 'This street is ___ than mine.',
        options: <String>['more quiet', 'quieter', 'quietest', 'as quiet'],
        answerIndex: 1,
        explanation:
            'Los adjetivos cortos forman el comparativo con <code>-er</code>: '
            '<code>quieter</code>.',
      ),
    ),
    // B1 — presente perfecto, condicional primero.
    PlacementItem(
      levelId: 'B1',
      exercise: MultipleChoiceExercise(
        prompt: 'I ___ lived here since 2019.',
        options: <String>['am', 'have', 'did', 'was'],
        answerIndex: 1,
        explanation:
            '<code>since</code> marca una acción que continúa, así que pide '
            'presente perfecto: <code>have lived</code>.',
      ),
    ),
    PlacementItem(
      levelId: 'B1',
      exercise: MultipleChoiceExercise(
        prompt: 'If it rains, we ___ at home.',
        options: <String>['stayed', 'will stay', 'would stay', 'stay'],
        answerIndex: 1,
        explanation:
            'Primer condicional: condición en presente y consecuencia con '
            '<code>will</code>.',
      ),
    ),
    // B2 — voz pasiva, concesión.
    PlacementItem(
      levelId: 'B2',
      exercise: MultipleChoiceExercise(
        prompt: 'The report ___ before the meeting started.',
        options: <String>[
          'had been finished',
          'has finished',
          'was finishing',
          'is finished',
        ],
        answerIndex: 0,
        explanation:
            'Pasiva en pasado anterior a otro pasado: '
            '<code>had been finished</code>.',
      ),
    ),
    PlacementItem(
      levelId: 'B2',
      exercise: MultipleChoiceExercise(
        prompt: '___ the delay, the team delivered on time.',
        options: <String>['Despite', 'Although', 'However', 'Because'],
        answerIndex: 0,
        explanation:
            '<code>Despite</code> va seguido de sustantivo; '
            '<i>although</i> exigiría una oración completa.',
      ),
    ),
    // C1 — inversión, subjuntivo, colocación.
    PlacementItem(
      levelId: 'C1',
      exercise: MultipleChoiceExercise(
        prompt: 'Rarely ___ such a clear example.',
        options: <String>[
          'we have seen',
          'have we seen',
          'we saw',
          'did we saw',
        ],
        answerIndex: 1,
        explanation:
            'Un adverbio negativo al inicio fuerza la inversión del sujeto y '
            'el auxiliar: <code>have we seen</code>.',
      ),
    ),
    PlacementItem(
      levelId: 'C1',
      exercise: MultipleChoiceExercise(
        prompt: 'The committee recommended that the deadline ___ extended.',
        options: <String>['is', 'was', 'be', 'would be'],
        answerIndex: 2,
        explanation:
            'Tras verbos de recomendación el inglés usa subjuntivo en forma '
            'base: <code>be extended</code>.',
      ),
    ),
  ],
);
