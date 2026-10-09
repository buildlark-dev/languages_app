/// El texto de lectura de un módulo.
///
/// Solo el texto: sus preguntas de comprensión son ejercicios de la lección, y se
/// presentan con los demás (FR-013). Separarlos permite que el pasaje quede
/// visible mientras se responde.
library;

import 'package:flutter/material.dart';

import '../../core/teaching_material.dart';
import 'listen_button.dart';

class ReadingPassageView extends StatelessWidget {
  const ReadingPassageView({required this.passage, super.key});

  final ReadingPassage passage;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(passage.title, style: text.titleMedium)),
                // La lectura entera, de un toque: oírla mientras se sigue con
                // la vista es la forma de que el texto escrito y el sonido se
                // asocien, que es media comprensión auditiva.
                ListenButton(
                  text: passage.paragraphs.join(' '),
                  semanticLabel: 'Escuchar la lectura',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Los párrafos vienen ya separados en el contenido, así que no hay
            // que adivinar dónde cortar: se renderizan con el espaciado que
            // hace legible un texto a 360 dp.
            for (int i = 0; i < passage.paragraphs.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 12),
              Text(passage.paragraphs[i], style: text.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}
