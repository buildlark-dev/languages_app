/// A1 · Módulo 2 — gramática, ejemplos y lectura.
library;

import '../../core/teaching_material.dart';

const GrammarExplanation a1Module2Grammar = GrammarExplanation(
  title: '<i>There is / there are</i>, plurales y lugar',
  bodyHtml:
      '<p>Para decir que algo <b>existe</b> en un lugar usamos '
      '<code>there is</code> (singular) y <code>there are</code> (plural). No '
      'lo confundas con <code>it is</code>, que describe algo ya '
      'mencionado.</p>'
      '<table>'
      '<tr><th>Uso</th><th>Ejemplo</th></tr>'
      '<tr><td>Singular</td><td>There is a park near my flat.</td></tr>'
      '<tr><td>Plural</td><td>There are two windows in the kitchen.</td></tr>'
      '<tr><td>Negativo</td>'
      '<td>There isn\'t a lift. / There aren\'t any chairs.</td></tr>'
      '<tr><td>Pregunta</td>'
      '<td>Is there a market here? / Are there any keys?</td></tr>'
      '</table>'
      '<p>Con plurales en preguntas y negaciones usamos <code>any</code>; en '
      'afirmativas, <code>some</code>.</p>'
      '<p>Preposiciones básicas de lugar: <code>in</code> (dentro), '
      '<code>on</code> (sobre una superficie), <code>under</code> (debajo), '
      '<code>next to</code> (al lado de), <code>between</code> (entre dos).</p>'
      '<p>Ojo con el plural: la mayoría añade <code>-s</code>, pero '
      '<code>-ch, -sh, -s, -x</code> añaden <code>-es</code> '
      '(<code>benches</code>), y <code>-y</code> tras consonante cambia a '
      '<code>-ies</code> (<code>library → libraries</code>).</p>',
);

const List<BilingualExample> a1Module2Examples = <BilingualExample>[
  BilingualExample(
    target: 'There is a market next to the library.',
    spanish: 'Hay un mercado al lado de la biblioteca.',
  ),
  BilingualExample(
    target: 'There are three chairs in the kitchen.',
    spanish: 'Hay tres sillas en la cocina.',
  ),
  BilingualExample(
    target: 'There aren\'t any keys on the table.',
    spanish: 'No hay llaves sobre la mesa.',
  ),
  BilingualExample(
    target: 'Is there a bus stop near the park?',
    spanish: '¿Hay una parada de bus cerca del parque?',
  ),
  BilingualExample(
    target: 'My bedroom is between the bathroom and the kitchen.',
    spanish: 'Mi dormitorio está entre el baño y la cocina.',
  ),
];

const ReadingPassage a1Module2Reading = ReadingPassage(
  id: 'A1M2R',
  title: 'My flat in Rionegro',
  paragraphs: <String>[
    'My flat is small but comfortable. There are two bedrooms, one bathroom '
        'and a kitchen with a big window. There isn\'t a dining room, so we '
        'eat in the kitchen.',
    'The fridge is next to the window and there are four chairs around the '
        'table. I always leave my keys on the fridge, because I forget them.',
    'My street is quiet. There is a park at the end, and there are two bus '
        'stops: one in front of the library and another next to the market. '
        'There aren\'t any supermarkets near here, but the market opens every '
        'day.',
  ],
);
