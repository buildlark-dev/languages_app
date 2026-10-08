/// Ofrece la nivelación, y solo a quien corresponde (T143).
///
/// Decide por sí misma si aparecer, consultando `shouldOfferPlacement`. Que la
/// decisión esté aquí y no en quien la coloca es lo que impide que una pantalla
/// nueva la muestre por descuido a alguien que lleva tres módulos hechos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/course.dart';
import '../../core/student_progress.dart';
import '../../engine/placement_evaluator.dart';
import '../providers/content_providers.dart';
import '../providers/progress_controller.dart';

class PlacementOfferCard extends ConsumerWidget {
  const PlacementOfferCard({required this.onOpenPlacement, super.key});

  final VoidCallback onOpenPlacement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Course? course = ref.watch(activeCourseProvider);
    final StudentProgress? progress = ref.watch(studentProgressProvider).value;

    if (course == null || progress == null) return const SizedBox.shrink();
    if (!shouldOfferPlacement(course: course, progress: progress)) {
      return const SizedBox.shrink();
    }

    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.timeline_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¿Empiezas de cero?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Si ya sabes algo, una prueba corta evita que repitas lo que '
              'tienes dominado. Puedes saltarla y empezar por el principio.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onOpenPlacement,
              child: const Text('Ver mi nivel'),
            ),
          ],
        ),
      ),
    );
  }
}
