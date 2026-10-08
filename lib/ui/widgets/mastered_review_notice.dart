/// Qué hacer cuando ya no queda contenido nuevo (FR-038).
///
/// Es el caso de quien nivela por encima de lo publicado: todos los niveles con
/// contenido quedan dominados el primer día, y el mapa queda lleno de insignias
/// y vacío de siguiente paso. Un mapa así se lee como «ya terminaste la app»,
/// y la persona no vuelve.
///
/// Por eso aquí hay una acción y no solo un aviso: repasar lo dominado es lo
/// único útil que se puede hacer hoy, y tiene que estar a un toque.
library;

import 'package:flutter/material.dart';

class MasteredReviewNotice extends StatelessWidget {
  const MasteredReviewNotice({
    required this.upcomingLevelId,
    required this.onReview,
    super.key,
  });

  /// El siguiente nivel anunciado, si hay alguno.
  final String? upcomingLevelId;

  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.replay_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ya dominas todo lo publicado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              upcomingLevelId == null
                  ? 'Mientras preparamos más contenido, repasar es lo que '
                        'evita perder lo que ya sabes.'
                  : 'Estamos preparando $upcomingLevelId. Mientras tanto, '
                        'repasar es lo que evita perder lo que ya sabes.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onReview,
              child: const Text('Repasar lo dominado'),
            ),
          ],
        ),
      ),
    );
  }
}
