/// Ejercicio de opción múltiple.
///
/// Las opciones son botones de 48 dp de alto en lugar de `RadioListTile` para
/// cumplir el área táctil del Principio VII sin depender de la densidad visual, y
/// se marcan con semántica de selección para que el lector de pantalla anuncie
/// cuál está elegida.
library;

import 'package:flutter/material.dart';

class MultipleChoiceQuestion extends StatelessWidget {
  const MultipleChoiceQuestion({
    required this.prompt,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    this.enabled = true,
    this.correctIndex,
    super.key,
  });

  final String prompt;
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  /// False cuando ya se respondió: evita cambiar la respuesta tras ver la
  /// corrección.
  final bool enabled;

  /// Una vez corregido, cuál era la correcta. Nulo mientras se responde.
  final int? correctIndex;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(prompt, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        for (int i = 0; i < options.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          _Option(
            label: options[i],
            selected: selectedIndex == i,
            // Tras corregir: verde la correcta, rojo la elegida si falló.
            state: correctIndex == null
                ? _OptionState.neutral
                : i == correctIndex
                ? _OptionState.correct
                : (selectedIndex == i
                      ? _OptionState.wrong
                      : _OptionState.neutral),
            onPressed: enabled ? () => onSelect(i) : null,
            colors: colors,
          ),
        ],
      ],
    );
  }
}

enum _OptionState { neutral, correct, wrong }

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.state,
    required this.onPressed,
    required this.colors,
  });

  final String label;
  final bool selected;
  final _OptionState state;
  final VoidCallback? onPressed;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color? background) = switch (state) {
      _OptionState.correct => (colors.primary, colors.primaryContainer),
      _OptionState.wrong => (colors.error, colors.errorContainer),
      _OptionState.neutral => (
        selected ? colors.primary : colors.outlineVariant,
        selected ? colors.surfaceContainerHighest : null,
      ),
    };

    return Semantics(
      selected: selected,
      button: true,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: background,
          side: BorderSide(color: border, width: selected ? 2 : 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, textAlign: TextAlign.left)),
            if (state == _OptionState.correct)
              Icon(Icons.check, color: colors.primary, size: 20),
            if (state == _OptionState.wrong)
              Icon(Icons.close, color: colors.error, size: 20),
          ],
        ),
      ),
    );
  }
}
