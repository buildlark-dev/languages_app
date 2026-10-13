/// Recorrido de una lección: estudiar y después responder.
///
/// El material de estudio va primero y **no se puntúa** (FR-013): se consulta. Los
/// ejercicios los recorre [ExerciseRunner], que comparte mecánica con el examen
/// de módulo y el de nivel, porque la única diferencia entre ellos es el umbral y
/// ese viaja en [ActivityKind].
library;

import 'package:flutter/material.dart';

import '../../core/activity_score.dart';
import '../../core/lesson.dart';
import '../../core/module.dart';
import '../../engine/scoring.dart';
import 'exercise_runner.dart';
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
  final LessonCompleted onCompleted;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _studying = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.lesson.title)),
    body: SafeArea(
      child: _studying
          ? LessonStudyView(
              module: widget.module,
              lesson: widget.lesson,
              onStart: () => setState(() => _studying = false),
            )
          : ExerciseRunner(
              exercises: widget.lesson.exercises,
              kind: ActivityKind.lesson,
              supportingPassage: widget.lesson.readingRef == null
                  ? null
                  : widget.module.reading,
              onCompleted: (ScoreResult result) =>
                  widget.onCompleted(widget.lesson, result),
              onFinishedBuilder: (ScoreResult result, VoidCallback onRetry) =>
                  LessonResultView(
                    result: result,
                    onRetry: onRetry,
                    onClose: () => Navigator.of(context).maybePop(),
                  ),
            ),
    ),
  );
}
