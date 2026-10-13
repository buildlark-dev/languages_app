/// Ejercicio de rellenar huecos, con **un recuadro por palabra**.
///
/// El hueco viene marcado como `___` en la frase. Los recuadros van **debajo**
/// de ella y no incrustados: un campo en línea a 360 dp fuerza a la frase a
/// partirse en sitios arbitrarios y deja el campo con dos centímetros de ancho.
///
/// ## Por qué un recuadro por palabra
///
/// Un único campo libre no dice cuántas palabras faltan, así que ante
/// `There ___ a market` no se sabe si se espera `is` o `is there`. Los
/// recuadros lo muestran sin decir la respuesta.
///
/// El número sale de la **primera** variante aceptada, que es la canónica. Las
/// demás pueden tener otro número de palabras —`aren't` es una y `are not` son
/// dos—, y eso no las deja fuera: un recuadro admite texto con espacios, y lo
/// escrito se une con espacios antes de comparar, así que `are not` tecleado en
/// un solo recuadro sigue siendo correcto.
library;

import 'package:flutter/material.dart';

class GapFillField extends StatefulWidget {
  const GapFillField({
    required this.sentenceWithGap,
    required this.wordCount,
    required this.onChanged,
    required this.onSubmit,
    this.hint,
    this.enabled = true,
    super.key,
  });

  /// La frase con el hueco marcado como `___`.
  final String sentenceWithGap;

  /// Cuántos recuadros mostrar. Al menos uno.
  final int wordCount;

  /// Lo escrito en todos los recuadros, unido con espacios.
  final ValueChanged<String> onChanged;

  final VoidCallback onSubmit;

  /// Pista opcional sobre qué se practica.
  final String? hint;

  final bool enabled;

  @override
  State<GapFillField> createState() => _GapFillFieldState();
}

class _GapFillFieldState extends State<GapFillField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  int get _boxes => widget.wordCount < 1 ? 1 : widget.wordCount;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      _boxes,
      (_) => TextEditingController(),
    );
    _focusNodes = List<FocusNode>.generate(_boxes, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    for (final FocusNode f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  /// Une lo escrito y lo reporta.
  ///
  /// Los recuadros vacíos se descartan antes de unir: con dos recuadros y una
  /// respuesta de una palabra, dejar el segundo en blanco no debe producir un
  /// espacio final que haya que normalizar después.
  void _report() => widget.onChanged(
    _controllers
        .map((TextEditingController c) => c.text.trim())
        .where((String s) => s.isNotEmpty)
        .join(' '),
  );

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
        // En fila cuando caben y en varias líneas cuando no: a 360 dp con la
        // fuente ampliada, tres recuadros en una sola fila se quedan sin ancho.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (int i = 0; i < _boxes; i++)
              SizedBox(
                width: _boxes == 1 ? double.infinity : 140,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  enabled: widget.enabled,
                  autocorrect: false,
                  // Sin autocapitalización: se escriben formas como `'s` o
                  // `aren't`, y una mayúscula impuesta no penaliza —la
                  // comparación la normaliza— pero sí confunde sobre lo que se
                  // espera.
                  textCapitalization: TextCapitalization.none,
                  textInputAction: i == _boxes - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _boxes == 1
                        ? 'Tu respuesta'
                        : 'Palabra ${i + 1}',
                  ),
                  onChanged: (_) => _report(),
                  // Saltar sola al siguiente recuadro evita tener que tocar
                  // cada uno a mano en un teclado de móvil.
                  onSubmitted: (_) {
                    if (i == _boxes - 1) {
                      widget.onSubmit();
                    } else {
                      _focusNodes[i + 1].requestFocus();
                    }
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}
