/// Tarjeta de un ítem de vocabulario.
library;

import 'package:flutter/material.dart';

import '../../core/vocabulary_item.dart';

class VocabularyCard extends StatelessWidget {
  const VocabularyCard({required this.item, this.trailing, super.key});

  final VocabularyItem item;

  /// Acción opcional al final, como el botón de escuchar.
  ///
  /// Se recibe desde fuera en lugar de construirlo aquí para que esta tarjeta no
  /// dependa del servicio de voz: así se puede probar sin micrófono ni altavoz.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            if (item.hint != null) ...<Widget>[
              // La ayuda visual es decorativa: se excluye del lector de pantalla
              // para que no lea el nombre del emoji entre el término y su
              // traducción.
              ExcludeSemantics(
                child: Text(item.hint!, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.term,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(item.translation, style: text.bodyMedium),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
