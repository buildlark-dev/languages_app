/// El resultado de una lección completada.
library;

import 'package:flutter/material.dart';

import '../../engine/scoring.dart';

class LessonResultView extends StatelessWidget {
  const LessonResultView({
    required this.result,
    required this.onRetry,
    required this.onClose,
    super.key,
  });

  final ScoreResult result;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              result.passed ? Icons.check_circle : Icons.replay_circle_filled,
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
                  ? 'Lección aprobada'
                  : 'Te falta poco. Necesitas 70 % para aprobarla.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (result.unavailable > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                '${result.unavailable} ejercicio(s) no se pudieron intentar y no '
                'cuentan en la nota.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 32),
            if (!result.passed)
              FilledButton(
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onClose, child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}
