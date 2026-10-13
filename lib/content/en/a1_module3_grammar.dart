/// A1 · Módulo 3 — gramática, ejemplos y lectura.
library;

import '../../core/teaching_material.dart';

const GrammarExplanation a1Module3Grammar = GrammarExplanation(
  title: 'Presente simple y frecuencia',
  bodyHtml:
      '<p>El presente simple sirve para <b>rutinas y hechos permanentes</b>. La '
      'única complicación real es la <b>-s</b> de la tercera persona: '
      '<code>he works</code>, <code>she studies</code>, '
      '<code>it finishes</code>.</p>'
      '<table>'
      '<tr><th></th><th>Afirmativo</th><th>Negativo</th><th>Pregunta</th></tr>'
      '<tr><td>I / you / we / they</td><td>work</td><td>don\'t work</td>'
      '<td>Do you work?</td></tr>'
      '<tr><td>he / she / it</td><td>works</td><td>doesn\'t work</td>'
      '<td>Does he work?</td></tr>'
      '</table>'
      '<p><b>Regla de oro:</b> cuando aparece <code>does</code> o '
      '<code>doesn\'t</code>, el verbo principal <b>pierde</b> la -s → '
      '<code>She doesn\'t work</code> (no <s>doesn\'t works</s>).</p>'
      '<p>Los adverbios de frecuencia (<code>always, usually, often, '
      'sometimes, hardly ever, never</code>) van <b>antes</b> del verbo '
      'principal pero <b>después</b> de <i>be</i>: '
      '<code>I always wake up at six</code> · '
      '<code>She is never late</code>.</p>'
      '<p>Para la hora se usa <code>at</code>: <code>at seven o\'clock</code>, '
      '<code>at half past six</code>, <code>at a quarter to eight</code>.</p>',
);

const List<BilingualExample> a1Module3Examples = <BilingualExample>[
  BilingualExample(
    target: 'I always wake up at six o\'clock.',
    spanish: 'Siempre me despierto a las seis.',
  ),
  BilingualExample(
    target: 'She studies English in the evening.',
    spanish: 'Ella estudia inglés por la tarde.',
  ),
  BilingualExample(
    target: 'He doesn\'t cook dinner on Fridays.',
    spanish: 'Él no hace la cena los viernes.',
  ),
  BilingualExample(
    target: 'Do you usually have breakfast at home?',
    spanish: '¿Normalmente desayunas en casa?',
  ),
  BilingualExample(
    target: 'My sister is never late for work.',
    spanish: 'Mi hermana nunca llega tarde al trabajo.',
  ),
];

const ReadingPassage a1Module3Reading = ReadingPassage(
  id: 'A1M3R',
  title: 'A normal Tuesday',
  paragraphs: <String>[
    'I wake up at half past five, before my alarm. I always have breakfast '
        'with my sister, usually coffee and arepas, and we leave home at seven.',
    'I work at the hospital from eight to four. My sister doesn\'t work in the '
        'morning: she teaches English in the afternoon, so she studies and '
        'prepares her classes until twelve.',
    'I get home at five and I cook dinner, because my sister finishes at '
        'eight. We never watch television after ten. I go to bed at eleven, '
        'but she usually goes to bed later.',
  ],
);
