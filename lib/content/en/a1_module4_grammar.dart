/// A1 · Módulo 4 — gramática, ejemplos y lectura.
library;

import '../../core/teaching_material.dart';

const GrammarExplanation a1Module4Grammar = GrammarExplanation(
  title: '<i>Like + -ing</i>, <i>can</i> y pronombres objeto',
  bodyHtml:
      '<p>Después de <code>like, love, hate, enjoy, don\'t mind</code>, el '
      'segundo verbo va en <b>-ing</b>: <code>I like cooking</code>. Es un '
      'error muy común decir <s>I like cook</s>.</p>'
      '<p><code>can</code> expresa habilidad o permiso. Nunca lleva <i>to</i> '
      'ni <i>-s</i>: <code>She can drive</code>, <code>Can you swim?</code>, '
      '<code>They can\'t come</code>.</p>'
      '<table>'
      '<tr><th>Sujeto</th><th>Objeto</th></tr>'
      '<tr><td>I / you / he / she / it / we / they</td>'
      '<td>me / you / him / her / it / us / them</td></tr>'
      '</table>'
      '<p>El pronombre objeto va después del verbo o de una preposición: '
      '<code>I love it</code>, <code>She works with them</code>.</p>'
      '<p>Para preguntar gustos: '
      '<code>What kind of food do you like?</code> Para responder con '
      'intensidad: <code>I really like…</code> / '
      '<code>I don\'t like it much</code>.</p>',
);

const List<BilingualExample> a1Module4Examples = <BilingualExample>[
  BilingualExample(
    target: 'I love cooking, but I hate washing up.',
    spanish: 'Me encanta cocinar, pero odio lavar los platos.',
  ),
  BilingualExample(
    target: 'She can drive, but she can\'t swim.',
    spanish: 'Ella sabe conducir, pero no sabe nadar.',
  ),
  BilingualExample(
    target: 'Do you like spicy food? — I really like it.',
    spanish: '¿Te gusta la comida picante? — Me gusta mucho.',
  ),
  BilingualExample(
    target: 'We don\'t mind waiting for them.',
    spanish: 'No nos importa esperarlos.',
  ),
  BilingualExample(
    target: 'My brother can draw very well.',
    spanish: 'Mi hermano sabe dibujar muy bien.',
  ),
];

const ReadingPassage a1Module4Reading = ReadingPassage(
  id: 'A1M4R',
  title: 'Sunday lunch',
  paragraphs: <String>[
    'On Sundays we cook together. I love making rice and beans, and my sister '
        'likes grilling chicken. She can cook very well, but she hates washing '
        'up, so I do it.',
    'Our neighbour Elena eats with us. She can\'t eat cheese, so we never put '
        'it on the table. She really likes spicy food; we don\'t like it much, '
        'so there is always a bottle of hot sauce next to her plate.',
    'After lunch my sister draws and I swim at the park pool. I can\'t draw at '
        'all, and she doesn\'t like swimming, so we don\'t do these things '
        'together.',
  ],
);
