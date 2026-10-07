/// Construir una frase con fichas desordenadas.
///
/// Las fichas se tocan para añadirlas y se vuelven a tocar en la respuesta para
/// quitarlas. Se eligió tocar en lugar de arrastrar a propósito: arrastrar es
/// incómodo con una mano, imposible con un lector de pantalla y poco fiable con
/// dedos grandes en pantallas de 360 dp.
///
/// Una palabra repetida en la frase objetivo aparece dos veces como ficha, así que
/// las fichas se identifican por **posición** y no por texto; si no, quitar una
/// quitaría también su gemela.
library;

import 'package:flutter/material.dart';

class SentenceBuilder extends StatelessWidget {
  const SentenceBuilder({
    required this.tokens,
    required this.chosenIndices,
    required this.onToggle,
    this.enabled = true,
    super.key,
  });

  /// Las fichas disponibles, en el orden en que se presentan.
  final List<String> tokens;

  /// Índices de [tokens] ya colocados, en el orden elegido.
  final List<int> chosenIndices;

  /// Añade o quita la ficha de ese índice.
  final ValueChanged<int> onToggle;

  final bool enabled;

  /// La frase montada hasta ahora.
  String get sentence =>
      chosenIndices.map((int i) => tokens[i]).join(' ');

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<int> available = <int>[
      for (int i = 0; i < tokens.length; i++)
        if (!chosenIndices.contains(i)) i,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Zona de respuesta. Alto mínimo para que no salte el diseño al colocar
        // la primera ficha.
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(12),
            color: colors.surfaceContainerHighest,
          ),
          child: chosenIndices.isEmpty
              ? Text(
                  'Toca las palabras para armar la frase',
                  style: TextStyle(color: colors.onSurfaceVariant),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final int index in chosenIndices)
                      _Chip(
                        label: tokens[index],
                        onPressed: enabled ? () => onToggle(index) : null,
                        semanticHint: 'Quitar',
                        filled: true,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final int index in available)
              _Chip(
                label: tokens[index],
                onPressed: enabled ? () => onToggle(index) : null,
                semanticHint: 'Añadir',
                filled: false,
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onPressed,
    required this.semanticHint,
    required this.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final String semanticHint;
  final bool filled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    // El lector de pantalla anuncia «Añadir casa» o «Quitar casa», que es lo que
    // hace usable el ejercicio sin ver la pantalla.
    label: '$semanticHint $label',
    excludeSemantics: true,
    child: filled
        ? FilledButton.tonal(
            onPressed: onPressed,
            style: _style,
            child: Text(label),
          )
        : OutlinedButton(onPressed: onPressed, style: _style, child: Text(label)),
  );

  static final ButtonStyle _style = OutlinedButton.styleFrom(
    // Alto mínimo táctil sin forzar el ancho: las fichas son de una palabra.
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 16),
  );
}
