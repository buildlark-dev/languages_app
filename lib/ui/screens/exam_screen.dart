/// Examen de módulo o de nivel.
///
/// Comparte el motor de ejercicios con la lección; lo único distinto es el umbral,
/// que viaja en [ActivityKind], y el mensaje del resultado, porque suspender un
/// examen de nivel no significa lo mismo que suspender una lección.
///
/// No hay material de estudio previo: un examen evalúa lo ya aprendido.
library;

import 'package:flutter/material.dart';

import '../../core/activity_score.dart';
import '../../core/exam.dart';
import '../../engine/scoring.dart';
import 'exercise_runner.dart';

/// Qué hacer con el resultado de un examen completado.
typedef ExamCompleted = Future<void> Function(Exam exam, ScoreResult result);

class ExamScreen extends StatelessWidget {
  const ExamScreen({
    required this.exam,
    required this.kind,
    required this.title,
    required this.onCompleted,
    super.key,
  });

  final Exam exam;
  final ActivityKind kind;
  final String title;
  final ExamCompleted onCompleted;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: ExerciseRunner(
        exercises: exam.exercises,
        kind: kind,
        onCompleted: (ScoreResult result) => onCompleted(exam, result),
        onFinishedBuilder: (ScoreResult result, VoidCallback onRetry) =>
            _ExamResultView(
              result: result,
              kind: kind,
              onRetry: onRetry,
              onClose: () => Navigator.of(context).maybePop(),
            ),
      ),
    ),
  );
}

class _ExamResultView extends StatelessWidget {
  const _ExamResultView({
    required this.result,
    required this.kind,
    required this.onRetry,
    required this.onClose,
  });

  final ScoreResult result;
  final ActivityKind kind;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isLevel = kind == ActivityKind.levelExam;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              result.passed
                  ? (isLevel ? Icons.workspace_premium : Icons.check_circle)
                  : Icons.replay_circle_filled,
              size: 72,
              color: result.passed ? colors.primary : colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              '${result.percentage} %',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              result.passed
                  ? (isLevel ? 'Nivel superado' : 'Módulo aprobado')
                  : 'Necesitas 80 % para aprobar el examen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!result.passed) ...<Widget>[
              const SizedBox(height: 8),
              // Reintentar un examen no tiene coste: el mejor puntaje es el que
              // cuenta (FR-027), así que decirlo quita el miedo a probar.
              Text(
                'Puedes reintentarlo. Se conserva tu mejor resultado.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 32),
            if (!result.passed)
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onClose, child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}
