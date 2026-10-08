/// Prueba de nivelación: presentación, recorrido y resultado.
///
/// Tres decisiones que la separan de una lección:
///
/// * **Se puede omitir de un toque**, desde la primera pantalla y sin
///   penalización (FR-034). Quien empieza de cero no debería tener que demostrar
///   que empieza de cero.
/// * **No corrige cada respuesta.** Una lección explica en el momento porque
///   está enseñando; la nivelación está midiendo, y mostrar la respuesta
///   enseñaría el patrón justo antes del siguiente ítem del mismo nivel.
/// * **No se puede suspender.** No hay umbral ni reintento: el resultado es una
///   estimación, no una nota.
library;

import 'package:flutter/material.dart';

import '../../core/course.dart';
import '../../core/exam.dart';
import '../../core/exercise.dart';
import '../../core/level.dart';
import '../../core/placement_result.dart';
import '../../engine/answer_check.dart';
import '../../engine/placement_evaluator.dart';
import '../widgets/placement_result_view.dart';
import 'lesson_exercise_body.dart';

/// Se invoca una sola vez, con el resultado listo para aplicar al progreso.
typedef PlacementFinished = Future<void> Function(PlacementResult result);

class PlacementScreen extends StatefulWidget {
  const PlacementScreen({
    required this.course,
    required this.onFinished,
    required this.now,
    super.key,
  });

  final Course course;

  /// Resultado de la prueba, o el de omitirla.
  final PlacementFinished onFinished;

  /// Fecha del intento. Llega por parámetro y no de `DateTime.now()` para que la
  /// prueba de widget pueda situarse en un día concreto.
  final DateTime now;

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

enum _Phase { intro, running, done }

class _PlacementScreenState extends State<PlacementScreen> {
  _Phase _phase = _Phase.intro;
  int _index = 0;
  AnswerDraft _draft = const AnswerDraft();
  final List<bool> _answers = <bool>[];

  PlacementResult? _result;

  PlacementExam get _exam => widget.course.placementTest!;

  Future<void> _skip() => _finish(PlacementResult.skippedAt(widget.now));

  Future<void> _submitCurrent() async {
    final PlacementItem item = _exam.items[_index];
    _answers.add(isAnswerCorrect(item.exercise, _draft));

    if (_index + 1 < _exam.items.length) {
      setState(() {
        _index++;
        _draft = const AnswerDraft();
      });
      return;
    }

    await _finish(
      evaluatePlacement(
        course: widget.course,
        exam: _exam,
        answers: _answers,
        takenAt: widget.now,
      ),
    );
  }

  Future<void> _finish(PlacementResult result) async {
    setState(() {
      _result = result;
      _phase = _Phase.done;
    });
    await widget.onFinished(result);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Nivelación'),
      // Sin flecha de volver durante el recorrido: salir a mitad dejaría un
      // resultado parcial, y la salida honesta es «empezar desde cero», que está
      // en la primera pantalla.
      automaticallyImplyLeading: _phase != _Phase.running,
    ),
    body: SafeArea(child: _body()),
  );

  Widget _body() => switch (_phase) {
    _Phase.intro => _Intro(
      itemCount: _exam.items.length,
      onStart: () => setState(() => _phase = _Phase.running),
      onSkip: _skip,
    ),
    _Phase.running => _Running(
      exam: _exam,
      index: _index,
      draft: _draft,
      languageTag: widget.course.studyLanguageTag,
      onDraft: (AnswerDraft draft) => setState(() => _draft = draft),
      onSubmit: _submitCurrent,
    ),
    _Phase.done => _resultView(),
  };

  Widget _resultView() {
    final PlacementResult result = _result!;
    final String assignedId = assignedLevelFor(
      course: widget.course,
      estimatedLevelId: result.estimatedLevelId,
    );
    final Level? assigned = widget.course.levelById(assignedId);

    return PlacementResultView(
      result: result,
      assignedLevelId: assignedId,
      assignedLevelName: assigned?.description ?? assignedId,
      assignedIsMastered: result.masteredLevelIds.contains(assignedId),
      onContinue: () => Navigator.of(context).maybePop(),
    );
  }
}

/// Qué es la prueba y cómo salirse de ella.
class _Intro extends StatelessWidget {
  const _Intro({
    required this.itemCount,
    required this.onStart,
    required this.onSkip,
  });

  final int itemCount;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: <Widget>[
      Text(
        '¿Ya sabes algo del idioma?',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 16),
      Text(
        'Son $itemCount preguntas y no se aprueba ni se suspende: solo sirven '
        'para no hacerte repetir lo que ya sabes. Los niveles que demuestres '
        'quedan marcados como dominados, y podrás repasarlos cuando quieras.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 32),
      FilledButton(onPressed: onStart, child: const Text('Hacer la prueba')),
      const SizedBox(height: 12),
      // A un toque y sin advertencias: empezar de cero es una opción legítima,
      // no un error que haya que confirmar.
      OutlinedButton(
        onPressed: onSkip,
        child: const Text('Empezar desde cero'),
      ),
    ],
  );
}

/// El ítem en curso. Sin corrección y sin vuelta atrás.
class _Running extends StatelessWidget {
  const _Running({
    required this.exam,
    required this.index,
    required this.draft,
    required this.languageTag,
    required this.onDraft,
    required this.onSubmit,
  });

  final PlacementExam exam;
  final int index;
  final AnswerDraft draft;
  final String languageTag;
  final ValueChanged<AnswerDraft> onDraft;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final Exercise exercise = exam.items[index].exercise;
    final bool canSubmit = isDraftComplete(exercise, draft);
    final int total = exam.items.length;

    return Column(
      children: <Widget>[
        LinearProgressIndicator(value: index / total),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'Pregunta ${index + 1} de $total',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              LessonExerciseBody(
                exercise: exercise,
                // Nunca «respondido»: no hay fase de corrección, así que los
                // controles siguen activos hasta que se avanza.
                answered: false,
                choice: draft.choice,
                chosenTokens: draft.chosenTokens,
                languageTag: languageTag,
                onChoice: (int i) => onDraft(draft.withChoice(i)),
                onTyped: (String v) => onDraft(draft.withTyped(v)),
                onToggleToken: (int i) => onDraft(draft.toggling(i)),
                onSubmit: onSubmit,
                // La nivelación no mide pronunciación: necesitaría micrófono
                // disponible, y una prueba que no se puede terminar sin permisos
                // manda a A1 a quien los niegue.
                onPronunciationAttempt: (_) {},
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: canSubmit ? onSubmit : null,
                child: Text(index + 1 == total ? 'Terminar' : 'Siguiente'),
              ),
              const SizedBox(height: 8),
              Text(
                'No se corrige sobre la marcha. Si no sabes una, responde lo '
                'que te parezca y sigue.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
