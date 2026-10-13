/// Presenta la alternativa accesible de un ejercicio oral, y explica por qué.
///
/// La usa tanto la escucha como la pronunciación, porque [OralExercise] expone su
/// alternativa bajo un nombre único. Un solo widget significa que la ruta sin
/// micrófono recibe el mismo cuidado que la ruta con micrófono, en lugar de ser un
/// apaño distinto en cada ejercicio.
///
/// Decir **por qué** aparece importa: sin el motivo, alguien cree que la app no
/// tiene audio, cuando lo que pasa es que su dispositivo no tiene la voz o negó el
/// permiso.
library;

import 'package:flutter/material.dart';

class AccessibleAlternative extends StatelessWidget {
  const AccessibleAlternative({
    required this.content,
    required this.title,
    this.reason,
    super.key,
  });

  /// El transcript o la frase a escribir.
  final String content;

  final String title;

  /// Por qué se está mostrando. Nulo si es una elección de la persona.
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.subtitles_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (reason != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              reason!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
