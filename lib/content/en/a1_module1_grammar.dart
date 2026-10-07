/// A1 · Módulo 1 — gramática, ejemplos y lectura.
///
/// Material de **estudio**: no se puntúa. Las preguntas de comprensión de la
/// lectura sí se puntúan, y por eso viven como ejercicios de la lección, en
/// `a1_module1_exercises.dart` (FR-013).
library;

import '../../core/teaching_material.dart';

const GrammarExplanation a1Module1Grammar = GrammarExplanation(
  title: 'El verbo <i>to be</i> y los pronombres',
  bodyHtml:
      '<p>En inglés <b>siempre</b> aparece el sujeto: no existe «soy '
      'colombiano» sin el <code>I</code>. El verbo <code>be</code> cambia '
      'según la persona y tiene tres formas en presente: '
      '<code>am / is / are</code>.</p>'
      '<table>'
      '<tr><th>Sujeto</th><th>Afirmativo</th><th>Contracción</th>'
      '<th>Negativo</th></tr>'
      '<tr><td>I</td><td>I am</td><td>I\'m</td><td>I\'m not</td></tr>'
      '<tr><td>you / we / they</td><td>you are</td><td>you\'re</td>'
      '<td>you aren\'t</td></tr>'
      '<tr><td>he / she / it</td><td>she is</td><td>she\'s</td>'
      '<td>she isn\'t</td></tr>'
      '</table>'
      '<p>Para preguntar, el verbo se pone <b>delante</b> del sujeto: '
      '<code>Are you from Medellín?</code> · <code>Is she a doctor?</code></p>'
      '<p>Ojo con dos calcos frecuentes del español: la edad se dice con '
      '<i>be</i>, no con «tener» (<code>I am 34</code>, no '
      '<s>I have 34</s>), y las profesiones llevan artículo '
      '(<code>He is a teacher</code>, no <s>He is teacher</s>).</p>',
);

const List<BilingualExample> a1Module1Examples = <BilingualExample>[
  BilingualExample(
    target: 'My name is Camila and I\'m from Rionegro.',
    spanish: 'Me llamo Camila y soy de Rionegro.',
  ),
  BilingualExample(
    target: 'She isn\'t a student; she\'s a nurse.',
    spanish: 'Ella no es estudiante; es enfermera.',
  ),
  BilingualExample(
    target: 'Are you Ana\'s neighbour?',
    spanish: '¿Eres tú el vecino de Ana?',
  ),
  BilingualExample(
    target: 'We\'re twenty-two years old.',
    spanish: 'Tenemos veintidós años.',
  ),
  BilingualExample(
    target: 'How do you spell your surname?',
    spanish: '¿Cómo se deletrea tu apellido?',
  ),
];

const ReadingPassage a1Module1Reading = ReadingPassage(
  id: 'A1M1R',
  title: 'A new neighbour',
  paragraphs: <String>[
    'Good morning. My name is Elena Ruiz. I\'m from Bogotá, but now I live '
        'in Rionegro with my sister. Our flat is number 4B, next to the lift.',
    'I\'m thirty-one years old and I\'m a nurse at the hospital in the '
        'centre. My sister isn\'t a nurse. She\'s an English teacher, and her '
        'students are teenagers.',
    'We aren\'t very good at cooking, so we know all the restaurants in the '
        'neighbourhood. Are you free on Saturday? Coffee at our place, maybe?',
  ],
);
