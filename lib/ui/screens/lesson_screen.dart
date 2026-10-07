/// Recorrido de una lección: estudiar, responder y ver el resultado.
///
/// Tres decisiones gobiernan esta pantalla:
///
/// * **El material de estudio va antes y permanece disponible.** Vocabulario,
///   gramática y lectura no se puntúan (FR-013), así que se consultan y se vuelve
///   a ellos; solo los ejercicios avanzan.
/// * **Nada se guarda hasta terminar.** Una lección abandonada a mitad se trata
///   como no presentada, nunca como fallada, así que la sesión vive en memoria y
///   el almacén solo se toca al completarla.
/// * **Cada respuesta se corrige en el momento**, con su explicación. Dejar la
///   corrección para el final convierte el repaso en un trámite.
library;

import 'package:flutter/material.dart';

import '../../core/exercise.dart';
import '../../core/lesson.dart';
import '../../core/module.dart';
import '../../engine/answer_matcher.dart';
import '../../engine/lesson_session.dart';
import '../../engine/scoring.dart';

import '../widgets/feedback_panel.dart';

import '../widgets/reading_passage_view.dart';
import 'lesson_exercise_body.dart';
import 'lesson_result_view.dart';
import 'lesson_study_view.dart';

/// Qué hacer con el resultado de una lección completada.
typedef LessonCompleted =
    Future<void> Function(Lesson lesson, ScoreResult result);

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    required this.module,
    required this.lesson,
    required this.onCompleted,
    super.key,
  });

  final Module module;
  final Lesson lesson;

  /// Se invoca **solo** cuando la lección está completa.
  final LessonCompleted onCompleted;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

/// Fases del recorrido.
enum _Stage { study, exercises, result }

class _LessonScreenState extends State<LessonScreen> {
  late LessonSession _session;
  _Stage _stage = _Stage.study;

  // Estado del ejercicio en curso.
  int? _choice;
  String _typed = '';
  List<int> _chosenTokens = <int>[];
  bool? _lastCorrect;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _session = LessonSession.start(lesson: widget.lesson);
  }

  void _resetExerciseState() {
    _choice = null;
    _typed = '';
    _chosenTokens = <int>[];
    _lastCorrect = null;
  }

  /// Corrige el ejercicio en curso sin avanzar todavía.
  void _check() {
    final Exercise? exercise = _session.currentExercise;
    if (exercise == null || _lastCorrect != null) return;

    final bool correct = switch (exercise) {
      MultipleChoiceExercise(:final int answerIndex) => _choice == answerIndex,
      ListeningExercise(:final int answerIndex) => _choice == answerIndex,
      GapFillExercise(:final List<String> acceptedAnswers) =>
        matchesAnswer(_typed, acceptedAnswers),
      SentenceBuilderExercise(:final String targetSentence) => matchesSentence(
        _chosenTokens.map((int i) => exercise.tokens[i]).join(' '),
        targetSentence,
      ),
      // La pronunciación llega en la Historia 4. Hasta entonces se resuelve por
      // su alternativa escrita, que es la ruta que SC-008 exige que exista.
      PronunciationExercise(:final String targetPhrase) => matchesSentence(
        _typed,
        targetPhrase,
      ),
    };

    setState(() => _lastCorrect = correct);
  }

  /// Registra la respuesta y pasa al siguiente ejercicio.
  Future<void> _advance() async {
    final bool? correct = _lastCorrect;
    if (correct == null) return;

    _session.answer(
      correct ? ExerciseOutcome.correct : ExerciseOutcome.incorrect,
    );

    if (!_session.isComplete) {
      setState(_resetExerciseState);
      return;
    }

    setState(() {
      _resetExerciseState();
      _stage = _Stage.result;
    });

    // Solo aquí se toca el almacén: una sesión incompleta no se guarda nunca.
    if (!_saved) {
      _saved = true;
      await widget.onCompleted(widget.lesson, _session.result);
    }
  }

  void _retry() {
    setState(() {
      _session = LessonSession.start(lesson: widget.lesson);
      _saved = false;
      _resetExerciseState();
      _stage = _Stage.exercises;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.lesson.title),
      bottom: _stage == _Stage.exercises
          ? PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(value: _session.progress),
            )
          : null,
    ),
    body: SafeArea(
      child: switch (_stage) {
        _Stage.study => LessonStudyView(
          module: widget.module,
          lesson: widget.lesson,
          onStart: () => setState(() => _stage = _Stage.exercises),
        ),
        _Stage.exercises => _buildExercise(context),
        _Stage.result => LessonResultView(
          result: _session.result,
          onRetry: _retry,
          onClose: () => Navigator.of(context).maybePop(),
        ),
      },
    ),
  );

  Widget _buildExercise(BuildContext context) {
    final Exercise? exercise = _session.currentExercise;
    if (exercise == null) return const SizedBox.shrink();

    final bool answered = _lastCorrect != null;
    final bool canCheck = switch (exercise) {
      MultipleChoiceExercise() || ListeningExercise() => _choice != null,
      GapFillExercise() || PronunciationExercise() => _typed.trim().isNotEmpty,
      SentenceBuilderExercise() => _chosenTokens.isNotEmpty,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Ejercicio ${_session.currentIndex + 1} de ${_session.totalCount}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 16),
        if (widget.lesson.readingRef != null) ...<Widget>[
          // El pasaje sigue disponible mientras se responde: las preguntas de
          // comprensión no son un ejercicio de memoria.
          ExpansionTile(
            title: Text(widget.module.reading.title),
            tilePadding: EdgeInsets.zero,
            children: <Widget>[
              ReadingPassageView(passage: widget.module.reading),
            ],
          ),
          const SizedBox(height: 16),
        ],
        LessonExerciseBody(
          exercise: exercise,
          answered: answered,
          choice: _choice,
          chosenTokens: _chosenTokens,
          onChoice: (int i) => setState(() => _choice = i),
          onTyped: (String v) => setState(() => _typed = v),
          onToggleToken: (int i) => setState(() {
            _chosenTokens = _chosenTokens.contains(i)
                ? (<int>[..._chosenTokens]..remove(i))
                : <int>[..._chosenTokens, i];
          }),
          onSubmit: _check,
        ),
        const SizedBox(height: 24),
        if (answered)
          FeedbackPanel(
            correct: _lastCorrect!,
            explanation: exercise.explanation,
            expectedAnswer: _expectedAnswerOf(exercise),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: answered
              ? _advance
              : (canCheck ? _check : null),
          child: Text(answered ? 'Continuar' : 'Comprobar'),
        ),
      ],
    );
  }

  String? _expectedAnswerOf(Exercise exercise) => switch (exercise) {
    MultipleChoiceExercise(:final String correctOption) => correctOption,
    ListeningExercise(:final List<String> options, :final int answerIndex) =>
      options[answerIndex],
    GapFillExercise(:final List<String> acceptedAnswers) =>
      acceptedAnswers.first,
    SentenceBuilderExercise(:final String targetSentence) => targetSentence,
    PronunciationExercise(:final String targetPhrase) => targetPhrase,
  };
}

