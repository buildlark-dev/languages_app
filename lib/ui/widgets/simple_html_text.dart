/// Renderizador del subconjunto de HTML que usa el contenido didáctico.
///
/// Soporta **solo** estas etiquetas, que son las que las explicaciones
/// gramaticales necesitan de verdad:
///
/// * bloques: `<p>`, `<table>` con `<tr>`, `<th>`, `<td>`
/// * en línea: `<b>`, `<i>`, `<code>`, `<s>`
///
/// Se escribe a mano en lugar de añadir un paquete de HTML completo porque el
/// contenido no viene de fuera: lo escribimos nosotros, así que acotarlo es
/// posible y preferible. Un renderizador de 200 líneas que soporta nueve
/// etiquetas es más fácil de razonar que una dependencia que soporta
/// doscientas, y la invariante del contrato de contenido verifica que nadie use
/// una etiqueta no soportada.
///
/// `<s>` importa pedagógicamente: es como se muestran las formas **incorrectas**
/// tachadas, y renderizarlo mal convertiría un contraejemplo en un ejemplo.
library;

import 'package:flutter/material.dart';

/// Las etiquetas que este renderizador entiende.
const Set<String> supportedHtmlTags = <String>{
  'p',
  'table',
  'tr',
  'th',
  'td',
  'b',
  'i',
  'code',
  's',
};

class SimpleHtmlText extends StatelessWidget {
  const SimpleHtmlText(this.html, {super.key});

  final String html;

  @override
  Widget build(BuildContext context) {
    final List<Widget> blocks = _parseBlocks(html, context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < blocks.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 12),
          blocks[i],
        ],
      ],
    );
  }
}

final RegExp _blockPattern = RegExp(
  r'<p>(.*?)</p>|<table>(.*?)</table>',
  dotAll: true,
);

List<Widget> _parseBlocks(String html, BuildContext context) {
  final List<Widget> result = <Widget>[];

  for (final RegExpMatch match in _blockPattern.allMatches(html)) {
    final String? paragraph = match.group(1);
    final String? table = match.group(2);

    if (paragraph != null) {
      result.add(
        Text.rich(
          TextSpan(children: _parseInline(paragraph, context)),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    } else if (table != null) {
      result.add(_buildTable(table, context));
    }
  }

  // Si el cuerpo no trae ninguna etiqueta de bloque, se muestra tal cual en lugar
  // de quedarse en blanco: perder la explicación es peor que mostrarla sin
  // formato.
  if (result.isEmpty && html.trim().isNotEmpty) {
    result.add(
      Text.rich(
        TextSpan(children: _parseInline(html, context)),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  return result;
}

final RegExp _rowPattern = RegExp(r'<tr>(.*?)</tr>', dotAll: true);
final RegExp _cellPattern = RegExp(
  r'<(th|td)>(.*?)</(?:th|td)>',
  dotAll: true,
);

Widget _buildTable(String tableHtml, BuildContext context) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  final List<TableRow> rows = <TableRow>[];

  for (final RegExpMatch rowMatch in _rowPattern.allMatches(tableHtml)) {
    final String rowHtml = rowMatch.group(1)!;
    final List<Widget> cells = <Widget>[];
    bool isHeader = false;

    for (final RegExpMatch cellMatch in _cellPattern.allMatches(rowHtml)) {
      final bool header = cellMatch.group(1) == 'th';
      isHeader = isHeader || header;
      cells.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text.rich(
            TextSpan(children: _parseInline(cellMatch.group(2)!, context)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: header ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    if (cells.isEmpty) continue;
    rows.add(
      TableRow(
        decoration: isHeader
            ? BoxDecoration(color: colors.surfaceContainerHighest)
            : null,
        children: cells,
      ),
    );
  }

  if (rows.isEmpty) return const SizedBox.shrink();

  // Las filas pueden traer distinto número de celdas si el contenido tiene un
  // error; Table lo rechaza, así que se igualan añadiendo celdas vacías.
  final int columns = rows
      .map((TableRow r) => r.children.length)
      .reduce((int a, int b) => a > b ? a : b);
  final List<TableRow> normalized = rows.map((TableRow row) {
    if (row.children.length == columns) return row;
    return TableRow(
      decoration: row.decoration,
      children: <Widget>[
        ...row.children,
        for (int i = row.children.length; i < columns; i++)
          const SizedBox.shrink(),
      ],
    );
  }).toList(growable: false);

  return Table(
    border: TableBorder.all(color: colors.outlineVariant),
    defaultColumnWidth: const IntrinsicColumnWidth(),
    children: normalized,
  );
}

final RegExp _inlinePattern = RegExp(r'</?(b|i|code|s)>');

/// Convierte el HTML en línea en una lista de tramos con estilo.
///
/// Usa una pila de etiquetas abiertas, de modo que `<b>texto <i>mixto</i></b>`
/// aplica ambos estilos al tramo interior.
List<InlineSpan> _parseInline(String html, BuildContext context) {
  final List<InlineSpan> spans = <InlineSpan>[];
  final List<String> openTags = <String>[];
  int cursor = 0;

  void addText(String raw) {
    if (raw.isEmpty) return;
    spans.add(TextSpan(text: _unescape(raw), style: _styleFor(openTags, context)));
  }

  for (final RegExpMatch match in _inlinePattern.allMatches(html)) {
    addText(html.substring(cursor, match.start));
    final String tag = match.group(1)!;
    if (match.group(0)!.startsWith('</')) {
      openTags.remove(tag);
    } else {
      openTags.add(tag);
    }
    cursor = match.end;
  }
  addText(html.substring(cursor));

  return spans;
}

TextStyle? _styleFor(List<String> tags, BuildContext context) {
  if (tags.isEmpty) return null;
  return TextStyle(
    fontWeight: tags.contains('b') ? FontWeight.bold : null,
    fontStyle: tags.contains('i') ? FontStyle.italic : null,
    // El tachado marca las formas incorrectas: sin él, un contraejemplo se lee
    // como un ejemplo.
    decoration: tags.contains('s') ? TextDecoration.lineThrough : null,
    fontFamily: tags.contains('code') ? 'monospace' : null,
    backgroundColor: tags.contains('code')
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : null,
  );
}

String _unescape(String raw) => raw
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    // El ampersand va al final para no deshacer las sustituciones anteriores.
    .replaceAll('&amp;', '&');
