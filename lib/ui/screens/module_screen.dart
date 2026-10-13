/// Mapa de módulos de un nivel, con su examen de nivel al final.
///
/// Además es el punto donde **empieza** un módulo, y por eso siembra aquí su
/// vocabulario en la cola de repaso (FR-028). La siembra ocurre al entrar y no
/// al aprobar: una palabra empieza a olvidarse el día en que se estudia, no el
/// día en que se examina. Es idempotente, así que entrar y salir diez veces del
/// mismo módulo no reinicia nada.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/course.dart';
import '../../core/activity_score.dart';
import '../../core/exam.dart';
import '../../core/level.dart';
import '../../core/module.dart';
import '../../core/student_progress.dart';
import '../../engine/progression.dart';
import '../providers/review_providers.dart';
import '../widgets/exam_result_label.dart';
import '../widgets/module_tile.dart';

class ModuleScreen extends ConsumerWidget {
  const ModuleScreen({
    required this.course,
    required this.level,
    required this.progress,
    required this.onOpenModule,
    required this.onOpenLevelExam,
    super.key,
  });

  final Course course;
  final Level level;
  final StudentProgress progress;
  final ValueChanged<Module> onOpenModule;
  final ValueChanged<Exam> onOpenLevelExam;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool examReady = isLevelExamAvailable(
      progress: progress,
      level: level,
    );
    final bool examPassed = progress.hasPassed(level.levelExam.id);
    final int passed = passedModuleCount(progress: progress, level: level);

    return Scaffold(
      appBar: AppBar(title: Text(level.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              level.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            for (final Module module in level.modules)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ModuleTile(
                  module: module,
                  availability: moduleAvailability(
                    course: course,
                    progress: progress,
                    module: module,
                  ),
                  lockReason: lockReasonFor(
                    course: course,
                    progress: progress,
                    module: module,
                  ),
                  // El módulo bloqueado no llega aquí: `ModuleTile` anula su
                  // propio `onTap`, así que no se siembra lo que no se abre.
                  onTap: () => _startModule(ref, module),
                ),
              ),
            const SizedBox(height: 16),
            _LevelExamCard(
              level: level,
              available: examReady,
              passed: examPassed,
              score: progress.activityScores[level.levelExam.id],
              passedModules: passed,
              onOpen: () => onOpenLevelExam(level.levelExam),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre el módulo y siembra su vocabulario en la cola de repaso.
  ///
  /// La navegación no espera a la siembra. Son dos razones: entrar en un módulo
  /// no debe quedarse esperando una escritura en disco, y si la siembra falla el
  /// estudiante igual puede estudiar —perdería el repaso espaciado de esas
  /// palabras, no la lección—. El aviso de almacenamiento degradado ya cubre el
  /// caso en que la base entera no funciona (FR-043).
  void _startModule(WidgetRef ref, Module module) {
    unawaited(ref.read(reviewSummaryProvider.notifier).seedModule(module));
    onOpenModule(module);
  }
}

/// El examen que decide el paso de nivel.
class _LevelExamCard extends StatelessWidget {
  const _LevelExamCard({
    required this.level,
    required this.available,
    required this.passed,
    required this.score,
    required this.passedModules,
    required this.onOpen,
  });

  final Level level;
  final bool available;
  final bool passed;

  /// El mejor intento, para poder decir con qué nota se superó el nivel.
  final ActivityScore? score;

  final int passedModules;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int total = level.modules.length;

    return Card(
      color: available && !passed ? colors.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  passed
                      ? Icons.workspace_premium
                      : (available
                            ? Icons.emoji_events_outlined
                            : Icons.lock_outline),
                  color: available || passed
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Examen de ${level.id}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // El mensaje dice exactamente qué falta, no solo que está bloqueado.
            Text(
              passed
                  ? '${passedExamLabel(score)} Ya superaste el nivel.'
                  : available
                  ? 'Necesitas 80 % para superar el nivel.'
                  : 'Aprueba los $total módulos para presentarlo. '
                        'Llevas $passedModules.',
            ),
            if (available && !passed) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onOpen,
                child: const Text('Presentar el examen'),
              ),
            ],
            if (passed) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onOpen,
                child: const Text('Repetir el examen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
