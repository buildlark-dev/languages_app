/// Anillo de avance con su cifra en el centro.
///
/// Dos cosas que no son adorno:
///
/// * **El porcentaje va escrito**, no solo dibujado. Un arco relleno a dos
///   tercios no se lee: se estima. Y para quien usa lector de pantalla, un arco
///   sin número no existe.
/// * **El texto no escala con la fuente del sistema** hasta deformar el anillo.
///   A 130 % de tamaño de letra, «100 %» dentro de un círculo de 96 dp se
///   desborda; el `FittedBox` lo encoge en lugar de romper el diseño (FR-047).
library;

import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.completion,
    required this.label,
    this.size = 96,
    super.key,
  });

  /// Proporción completada, de 0 a 1. Se recorta por si llega fuera de rango.
  final double completion;

  /// Qué mide el anillo. Lo lee el lector de pantalla junto al porcentaje.
  final String label;

  final double size;

  @override
  Widget build(BuildContext context) {
    final double value = completion.clamp(0.0, 1.0);
    final int percent = (value * 100).round();

    return Semantics(
      label: '$label: $percent por ciento',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size / 5),
              child: FittedBox(
                child: Text(
                  '$percent %',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
