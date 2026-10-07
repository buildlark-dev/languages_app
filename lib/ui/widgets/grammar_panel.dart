/// Explicación gramatical, con sus tablas de conjugación.
///
/// Es el contenido más exigente de la app en pantalla estrecha: las tablas de
/// conjugación no caben a 360 dp. Por eso la tabla va dentro de un
/// desplazamiento horizontal propio, en lugar de comprimir las columnas hasta
/// hacerlas ilegibles o desbordar (SC-010).
library;

import 'package:flutter/material.dart';

import '../../core/teaching_material.dart';
import 'simple_html_text.dart';

class GrammarPanel extends StatelessWidget {
  const GrammarPanel({required this.grammar, super.key});

  final GrammarExplanation grammar;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                WidgetSpan(
                  child: SimpleHtmlText(grammar.title),
                  alignment: PlaceholderAlignment.middle,
                ),
              ],
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(height: 24),
          _HorizontallyScrollableTables(html: grammar.bodyHtml),
        ],
      ),
    ),
  );
}

/// Renderiza el cuerpo dejando que las tablas se desplacen en horizontal.
class _HorizontallyScrollableTables extends StatelessWidget {
  const _HorizontallyScrollableTables({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = _splitAroundTables(html);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < parts.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 12),
          if (parts[i].startsWith('<table>'))
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SimpleHtmlText(parts[i]),
            )
          else
            SimpleHtmlText(parts[i]),
        ],
      ],
    );
  }
}

final RegExp _tableBlock = RegExp(r'<table>.*?</table>', dotAll: true);

/// Parte el HTML en tramos, separando cada tabla de lo que la rodea.
List<String> _splitAroundTables(String html) {
  final List<String> parts = <String>[];
  int cursor = 0;

  for (final RegExpMatch match in _tableBlock.allMatches(html)) {
    final String before = html.substring(cursor, match.start);
    if (before.trim().isNotEmpty) parts.add(before);
    parts.add(match.group(0)!);
    cursor = match.end;
  }

  final String rest = html.substring(cursor);
  if (rest.trim().isNotEmpty) parts.add(rest);

  return parts.isEmpty ? <String>[html] : parts;
}
