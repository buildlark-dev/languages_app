/// Recorre una lista de ejercicios, corrige y entrega el resultado.
///
/// Lo usan la lección y el examen: la mecánica es la misma y solo cambia el
/// umbral, que viaja en [ActivityKind]. Duplicarla habría significado dos sitios
/// donde arreglar la corrección de un hueco.
///
/// Dos reglas que no son negociables aquí:
///
/// * **Nada se guarda hasta terminar.** Una sesión abandonada a mitad se trata
///   como no presentada, nunca como fallada.
/// * **Cada respuesta se corrige en el momento**, con su explicación. Dejar la
///   corrección para el final convierte el repaso en un trámite.
library;

import 'package:flutter/material.dart';

import '../../core/activity_score.dart';
import '../../core/exercise.dart';
import '../../core/lesson.dart';
import '../../core/teaching_material.dart';
import '../../engine/answer_matcher.dart';
import '../../engine/lesson_session.dart';
import '../../engine/scoring.dart';
import '../widgets/feedback_panel.dart';
import '../widgets/pronunciation_exercise_view.dart';
import '../widgets/reading_passage_view.dart';
import 'lesson_exercise_body.dart';

/// Se invoca **solo** cuando la tanda está completa.
typedef ExercisesCompleted = Future<void> Function(ScoreResult result);

class ExerciseRunner extends StatefulWidget {
  const ExerciseRunner({
    required this.exercises,
    required this.kind,
    required this.onCompleted,
    required this.onFinishedBuilder,
    this.languageTag = 'en-US',
    this.supportingPassage,
    super.key,
  });

  final List<Exercise> exercises;
  final ActivityKind kind;
  final ExercisesCompleted onCompleted;

  /// Idioma del curso, para la voz.
  final String languageTag;

  /// Qué mostrar al terminar. Lo decide la pantalla que lo usa.
  final Widget Function(ScoreResult result, VoidCallback onRetry)
  onFinishedBuilder;

  /// Pasaje que queda consultable mientras se responde, si lo hay.
  final ReadingPassage? supportingPassage;

  @override
  State<ExerciseRunner> createState() => _ExerciseRunnerState();
}

class _ExerciseRunnerState extends State<ExerciseRunner> {
  late LessonSession _session;
  int? _choice;
  String _typed = '';
  List<int> _chosenTokens = <int>[];
  bool? _lastCorrect;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _session = _newSession();

    // Una tanda vacía ya está completa al nacer, así que _advance nunca corre y
    // el resultado se mostraría sin reportarse. No ocurre con contenido real
    // —la prueba de integridad exige diez ejercicios por examen— pero un motor
    // que muestra un resultado que no registra es incoherente, y la prueba lo
    // destapó.
    if (_session.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reportIfNeeded());
    }
  }

  Future<void> _reportIfNeeded() async {
    if (_saved || !_session.isComplete) return;
    _saved = true;
    await widget.onCompleted(_session.result);
    if (mounted) setState(() {});
  }

  LessonSession _newSession() => LessonSession.start(
    lesson: Lesson(
      id: 'runner',
      title: 'runner',
      exercises: widget.exercises,
    ),
    kind: widget.kind,
  );

  void _resetExercise() {
    _choice = null;
    _typed = '';
    _chosenTokens = <int>[];
    _lastCorrect = null;
  }

  void _check() {
    final Exercise? exercise = _session.currentExercise;
    if (exercise == null || _lastCorrect != null) return;

    final bool correct = switch (exercise) {
      MultipleChoiceExercise(:final int answerIndex) => _choice == answerIndex,
      ListeningExercise(:final int answerIndex) => _choice == answerIndex,
      GapFillExercise(:final List<String> acceptedAnswers) => matchesAnswer(
        _typed,
        acceptedAnswers,
      ),
      SentenceBuilderExercise(:final String targetSentence) => matchesSentence(
        _chosenTokens.map((int i) => exercise.tokens[i]).join(' '),
        targetSentence,
      ),
      // La interfaz con micrófono llega en la Historia 4. Hasta entonces se
      // resuelve por la alternativa escrita, que es la ruta que SC-008 exige que
      // exista siempre.
      PronunciationExercise(:final String targetPhrase) => matchesSentence(
        _typed,
        targetPhrase,
      ),
    };

    setState(() => _lastCorrect = correct);
  }

  Future<void> _advance() async {
    final bool? correct = _lastCorrect;
    if (correct == null) return;

    _session.answer(
      correct ? ExerciseOutcome.correct : ExerciseOutcome.incorrect,
    );

    if (!_session.isComplete) {
      setState(_resetExercise);
      return;
    }

    setState(_resetExercise);

    // Solo al completar se toca el almacén: una tanda abandonada a mitad no se
    // guarda nunca.
    await _reportIfNeeded();
  }

  /// Resuelve un intento de pronunciación.
  ///
  /// `unavailable` **avanza sin contar** ni como acierto ni como fallo: sale del
  /// denominador de la nota (FR-020), que es lo que hace alcanzable SC-008.
  Future<void> _handlePronunciation(PronunciationAttempt attempt) async {
    switch (attempt) {
      case PronunciationAttempt.correct:
        setState(() => _lastCorrect = true);
      case PronunciationAttempt.incorrect:
        setState(() => _lastCorrect = false);
      case PronunciationAttempt.unavailable:
        _session.skipAsUnavailable();
        if (!_session.isComplete) {
          setState(_resetExercise);
          return;
        }
        setState(_resetExercise);
        await _reportIfNeeded();
    }
  }

  void _retry() => setState(() {
    _session = _newSession();
    _saved = false;
    _resetExercise();
  });

  @override
  Widget build(BuildContext context) {
    if (_session.isComplete) {
      return widget.onFinishedBuilder(_session.result, _retry);
    }

    final Exercise exercise = _session.currentExercise!;
    final bool answered = _lastCorrect != null;
    final bool canCheck = switch (exercise) {
      MultipleChoiceExercise() || ListeningExercise() => _choice != null,
      GapFillExercise() || PronunciationExercise() => _typed.trim().isNotEmpty,
      SentenceBuilderExercise() => _chosenTokens.isNotEmpty,
    };

    return Column(
      children: <Widget>[
        LinearProgressIndicator(value: _session.progress),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'Ejercicio ${_session.currentIndex + 1} de '
                '${_session.totalCount}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 16),
              if (widget.supportingPassage != null) ...<Widget>[
                // El pasaje sigue disponible mientras se responde: las preguntas
                // de comprensión no son un ejercicio de memoria.
                ExpansionTile(
                  title: Text(widget.supportingPassage!.title),
                  tilePadding: EdgeInsets.zero,
                  children: <Widget>[
                    ReadingPassageView(passage: widget.supportingPassage!),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              LessonExerciseBody(
                exercise: exercise,
                answered: answered,
                choice: _choice,
                chosenTokens: _chosenTokens,
                languageTag: widget.languageTag,
                onChoice: (int i) => setState(() => _choice = i),
                onTyped: (String v) => setState(() => _typed = v),
                onToggleToken: (int i) => setState(() {
                  _chosenTokens = _chosenTokens.contains(i)
                      ? (<int>[..._chosenTokens]..remove(i))
                      : <int>[..._chosenTokens, i];
                }),
                onSubmit: _check,
                onPronunciationAttempt: _handlePronunciation,
              ),
              const SizedBox(height: 24),
              if (answered)
                FeedbackPanel(
                  correct: _lastCorrect!,
                  explanation: exercise.explanation,
                  expectedAnswer: expectedAnswerOf(exercise),
                ),
              const SizedBox(height: 24),
              // La pronunciación tiene sus propios botones dentro del ejercicio,
              // así que aquí solo aparece el de avanzar una vez resuelta.
              if (exercise is! PronunciationExercise || answered)
                FilledButton(
                  onPressed: answered ? _advance : (canCheck ? _check : null),
                  child: Text(answered ? 'Continuar' : 'Comprobar'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// La respuesta esperada de un ejercicio, para mostrarla al fallar.
String? expectedAnswerOf(Exercise exercise) => switch (exercise) {
  MultipleChoiceExercise(:final String correctOption) => correctOption,
  ListeningExercise(:final List<String> options, :final int answerIndex) =>
    options[answerIndex],
  GapFillExercise(:final List<String> acceptedAnswers) => acceptedAnswers.first,
  SentenceBuilderExercise(:final String targetSentence) => targetSentence,
  PronunciationExercise(:final String targetPhrase) => targetPhrase,
};
