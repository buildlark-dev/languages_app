/// Pantalla de progreso: avance del nivel, módulos superados y cola de repaso
/// (FR-033).
///
/// Es la única pantalla que junta las tres señales, y el orden en que aparecen
/// es una decisión: primero **lo que falta** —el anillo del nivel y los módulos—
/// y después racha y XP. Al revés, la pantalla de progreso se convierte en un
/// marcador, y un marcador no dice qué hacer a continuación.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/course.dart';
import '../../core/level.dart';
import '../../core/level_state.dart';
import '../../core/student_progress.dart';
import '../../engine/progression.dart';
import '../../engine/streak_tracker.dart';
import '../providers/clock_providers.dart';
import '../providers/content_providers.dart';
import '../providers/progress_controller.dart';
import '../providers/review_providers.dart';
import '../widgets/progress_ring.dart';
import '../widgets/streak_badge.dart';
import '../widgets/xp_badge.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Course? course = ref.watch(activeCourseProvider);
    final StudentProgress? progress = ref.watch(studentProgressProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Tu progreso')),
      body: SafeArea(
        child: course == null || progress == null
            ? const Center(child: CircularProgressIndicator())
            : _Body(
                course: course,
                progress: progress,
                today: ref.watch(clockProvider)(),
                dueToday: ref.watch(reviewSummaryProvider).value?.dueToday,
                reviewTotal: ref.watch(reviewSummaryProvider).value?.total,
              ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.course,
    required this.progress,
    required this.today,
    required this.dueToday,
    required this.reviewTotal,
  });

  final Course course;
  final StudentProgress progress;
  final DateTime today;

  /// Nulos mientras la cola se está leyendo. No se dibuja un cero provisional
  /// que cambie un instante después.
  final int? dueToday;
  final int? reviewTotal;

  @override
  Widget build(BuildContext context) {
    // El nivel que se está estudiando. Si el progreso apunta a uno que ya no
    // existe en el catálogo, se cae al primero en lugar de romper la pantalla.
    final Level level =
        course.levelById(progress.currentLevelId) ?? course.levels.first;
    final int passed = passedModuleCount(progress: progress, level: level);
    final int total = level.modules.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Center(
          child: ProgressRing(
            completion: levelCompletion(progress: progress, level: level),
            label: 'Avance de ${level.id}',
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            level.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 24),
        _Row(
          icon: Icons.check_circle_outline,
          title: 'Módulos superados',
          value: '$passed de $total',
        ),
        _Row(
          icon: Icons.schedule,
          title: 'Palabras en repaso',
          value: _reviewValue(),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: StreakBadge(
            streak: StreakPoint(
              date: progress.lastActivityDate,
              count: progress.streakCount,
            ),
            today: today,
          ),
        ),
        XpBadge(xp: progress.xp),
        const Divider(height: 32),
        Text('Niveles', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final Level each in course.levels)
          _LevelRow(level: each, state: progress.stateOf(each.id)),
        // Los anunciados aparecen aquí también: «el camino sigue» es información
        // distinta de «esto es todo lo que hay».
        for (final String upcoming in course.upcomingLevelIds)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '$upcoming · en preparación',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  String _reviewValue() {
    final int? due = dueToday;
    final int? all = reviewTotal;
    if (due == null || all == null) return '…';
    if (all == 0) return 'ninguna todavía';
    return due == 0 ? '$all · al día' : '$all · $due vencen hoy';
  }
}

/// Una cifra con su etiqueta.
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Semantics(
      label: '$title: $value',
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    ),
  );
}

/// Un nivel de la lista, con su estado.
///
/// Dice el estado y **no** el porcentaje: ese ya está en el anillo, y repetirlo
/// aquí obligaría a leer dos cifras iguales para entender que son la misma.
/// Igual con el nombre: el anillo lo lleva, así que la lista usa el
/// identificador, que además la deja alineada con las filas de los niveles
/// anunciados.
class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.level, required this.state});

  final Level level;
  final LevelState state;

  @override
  Widget build(BuildContext context) {
    final String label = switch (state) {
      LevelState.locked => 'Bloqueado',
      LevelState.unlocked => 'En curso',
      LevelState.mastered => 'Dominado',
      LevelState.passed => 'Superado',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(level.id)),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
