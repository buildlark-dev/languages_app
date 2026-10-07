/// Retroalimentación tras responder.
///
/// Su razón de existir es FR-025: muestra **por qué** la respuesta correcta lo es,
/// no solo cuál era. Un panel que dijera «Incorrecto. La respuesta era *is*» no
/// enseña nada; el motivo sí.
///
/// Por eso la explicación ocupa el espacio principal y el veredicto va reducido a
/// una línea con su icono.
library;

import 'package:flutter/material.dart';

import 'simple_html_text.dart';

class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    required this.correct,
    required this.explanation,
    this.expectedAnswer,
    super.key,
  });

  final bool correct;

  /// Por qué la correcta lo es. Admite el marcado del contenido.
  final String explanation;

  /// La respuesta esperada, cuando ayuda mostrarla junto al motivo.
  final String? expectedAnswer;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = correct
        ? colors.primaryContainer
        : colors.errorContainer;
    final Color foreground = correct
        ? colors.onPrimaryContainer
        : colors.onErrorContainer;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  correct ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: foreground,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  correct ? 'Correcto' : 'Incorrecto',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ),
            if (!correct && expectedAnswer != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Se esperaba: $expectedAnswer',
                style: TextStyle(color: foreground),
              ),
            ],
            const SizedBox(height: 12),
            // La explicación, que es lo que de verdad enseña.
            DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: SimpleHtmlText(explanation),
            ),
          ],
        ),
      ),
    );
  }
}
