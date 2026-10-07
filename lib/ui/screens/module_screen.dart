/// Mapa de módulos de un nivel, con su examen de nivel al final.
library;

import 'package:flutter/material.dart';

import '../../core/course.dart';
import '../../core/exam.dart';
import '../../core/level.dart';
import '../../core/module.dart';
import '../../core/student_progress.dart';
import '../../engine/progression.dart';
import '../widgets/module_tile.dart';

class ModuleScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
            Text(level.description, style: Theme.of(context).textTheme.bodyLarge),
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
                  onTap: () => onOpenModule(module),
                ),
              ),
            const SizedBox(height: 16),
            _LevelExamCard(
              level: level,
              available: examReady,
              passed: examPassed,
              passedModules: passed,
              onOpen: () => onOpenLevelExam(level.levelExam),
            ),
          ],
        ),
      ),
    );
  }
}

/// El examen que decide el paso de nivel.
class _LevelExamCard extends StatelessWidget {
  const _LevelExamCard({
    required this.level,
    required this.available,
    required this.passed,
    required this.passedModules,
    required this.onOpen,
  });

  final Level level;
  final bool available;
  final bool passed;
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
                      : (available ? Icons.emoji_events_outlined : Icons.lock_outline),
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
                  ? 'Aprobado. Ya superaste el nivel.'
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
