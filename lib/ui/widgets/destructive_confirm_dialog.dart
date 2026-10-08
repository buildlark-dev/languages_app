/// Confirmación de una acción irreversible (FR-046).
///
/// Tres decisiones, todas dirigidas al mismo problema: que nadie pulse «sí» por
/// inercia.
///
/// * **Dice qué se pierde**, con nombre y cantidad si quien llama la sabe. «Vas
///   a borrar tu progreso» pesa menos que «vas a borrar 4 módulos aprobados y
///   120 palabras en repaso».
/// * **Nombra el respaldo como única vuelta atrás.** Si la persona no tiene uno,
///   este es el momento de enterarse, no después.
/// * **El botón destructivo no es el predeterminado** y va en color de error.
///   Cancelar queda a la derecha, donde cae el pulgar.
library;

import 'package:flutter/material.dart';

class DestructiveConfirmDialog extends StatelessWidget {
  const DestructiveConfirmDialog({
    required this.title,
    required this.consequence,
    required this.confirmLabel,
    this.inventory,
    super.key,
  });

  final String title;

  /// Qué ocurre, en una frase.
  final String consequence;

  /// Qué se pierde exactamente, si se puede enumerar.
  final String? inventory;

  final String confirmLabel;

  /// Abre el diálogo y devuelve true solo si se confirmó.
  ///
  /// Un cierre por el botón de atrás o por tocar fuera devuelve nulo, que se
  /// trata como «no». Es la única interpretación segura: quien se sale sin
  /// responder no ha dicho que sí.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String consequence,
    required String confirmLabel,
    String? inventory,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => DestructiveConfirmDialog(
          title: title,
          consequence: consequence,
          confirmLabel: confirmLabel,
          inventory: inventory,
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_outlined, color: colors.error),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(consequence),
          if (inventory != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              inventory!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Esto no se puede deshacer. La única forma de recuperarlo es un '
            'respaldo exportado antes.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: colors.error),
          child: Text(confirmLabel),
        ),
        // Predeterminado y a la derecha: si alguien pulsa sin leer, no pasa
        // nada.
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
