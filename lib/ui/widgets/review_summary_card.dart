/// Cuántas palabras vencen hoy, en la pantalla principal (FR-030).
///
/// Los tres estados se dicen con palabras distintas y **solo uno ofrece entrar**:
///
/// * Hay vencidas → el número y el botón.
/// * Cero vencidas con cola existente → «estás al día», sin botón.
/// * Cola vacía → se explica que el repaso aparece al empezar un módulo.
///
/// El segundo es el que FR-030 exige explícitamente. Dejar el botón activo con
/// cero vencidas abriría una sesión de cero tarjetas, y un recorrido vacío se
/// lee como un error de la app, no como una buena noticia.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../providers/review_providers.dart';

class ReviewSummaryCard extends ConsumerWidget {
  const ReviewSummaryCard({required this.onOpenReview, super.key});

  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ReviewSummary? summary = ref.watch(reviewSummaryProvider).value;

    // Mientras carga no se dice nada: un «0 palabras» que cambia a «7» un
    // instante después es peor que un hueco.
    if (summary == null) return const SizedBox.shrink();

    final bool hasDue = summary.dueToday > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  hasDue ? Icons.schedule : Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summary.isEmpty
                        ? 'Todavía no hay repaso'
                        : l10n.reviewDueCount(summary.dueToday),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_detailFor(summary)),
            if (hasDue) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onOpenReview,
                child: const Text('Repasar ahora'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _detailFor(ReviewSummary summary) {
    if (summary.isEmpty) {
      return 'Las palabras que estudies entrarán aquí para que no se te '
          'olviden.';
    }
    if (summary.isUpToDate) {
      return 'Ya repasaste todo lo que vencía. Tienes ${summary.total} '
          '${summary.total == 1 ? 'palabra' : 'palabras'} en seguimiento.';
    }
    return 'Repasar lo que vence hoy toma pocos minutos y es lo que evita '
        'olvidar lo ya estudiado.';
  }
}
