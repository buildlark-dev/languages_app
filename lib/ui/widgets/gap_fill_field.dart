/// Ejercicio de rellenar huecos.
///
/// El hueco viene marcado como `___` en la frase. El campo se presenta **debajo**
/// de la frase y no incrustado en ella: un campo en línea a 360 dp fuerza a la
/// frase a partirse en sitios arbitrarios y deja el campo con dos centímetros de
/// ancho.
library;

import 'package:flutter/material.dart';

class GapFillField extends StatefulWidget {
  const GapFillField({
    required this.sentenceWithGap,
    required this.onChanged,
    required this.onSubmit,
    this.hint,
    this.enabled = true,
    super.key,
  });

  /// La frase con el hueco marcado como `___`.
  final String sentenceWithGap;

  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  /// Pista opcional sobre qué se practica.
  final String? hint;

  final bool enabled;

  @override
  State<GapFillField> createState() => _GapFillFieldState();
}

class _GapFillFieldState extends State<GapFillField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // La frase se lee con el hueco visible. El lector de pantalla recibe
        // «espacio en blanco» en su lugar, porque tres guiones bajos seguidos se
        // leen como ruido.
        Semantics(
          label: widget.sentenceWithGap.replaceAll('___', 'espacio en blanco'),
          excludeSemantics: true,
          child: Text(widget.sentenceWithGap, style: text.titleMedium),
        ),
        if (widget.hint != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            widget.hint!,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          autocorrect: false,
          // Sin autocapitalización: el estudiante escribe formas como `'s` o
          // `aren't`, y una mayúscula impuesta no penaliza porque la comparación
          // la normaliza, pero sí confunde sobre lo que se espera.
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(labelText: 'Tu respuesta'),
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onSubmit(),
        ),
      ],
    );
  }
}
