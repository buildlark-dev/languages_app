/// Que el inglés no se lea con voz española.
///
/// La lista de voces de esta prueba es la que se midió de verdad en el
/// navegador de la app desplegada: cinco voces inglesas, ninguna marcada como
/// predeterminada, y la voz por defecto `es-ES Microsoft Helena` porque el
/// documento se declara `lang="es"`. Es el fallo más silencioso de los posibles:
/// **suena**, así que ninguna detección lo nota, y enseña una pronunciación
/// equivocada.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/services/speech/voice_pick.dart';

/// Lo que devolvió `speechSynthesis.getVoices()` en el navegador medido.
const List<Object?> _measuredVoices = <Object?>[
  <String, String>{'name': 'Microsoft Helena - Spanish (Spain)', 'locale': 'es-ES'},
  <String, String>{'name': 'Microsoft Richard - English (Canada)', 'locale': 'en-CA'},
  <String, String>{'name': 'Microsoft David - English (United States)', 'locale': 'en-US'},
  <String, String>{'name': 'Microsoft Zira - English (United States)', 'locale': 'en-US'},
];

void main() {
  test('se elige una voz inglesa y no la predeterminada del sistema', () {
    final VoiceChoice? choice = pickVoice(_measuredVoices, 'en-US');

    expect(choice, isNotNull);
    expect(choice!['locale'], 'en-US');
    expect(choice['name'], contains('English'));
  });

  test('la coincidencia exacta gana a la del mismo idioma', () {
    // `en-CA` aparece antes en la lista; `en-US` debe ganar igualmente, porque
    // el contenido está escrito y grabado como inglés de Estados Unidos.
    final VoiceChoice? choice = pickVoice(_measuredVoices, 'en-US');
    expect(choice!['locale'], 'en-US');
  });

  test('sin coincidencia exacta sirve cualquier voz del idioma', () {
    // Ser estricto aquí dejaría sin audio a mucha gente que sí tiene voz en
    // inglés, y para A1 un acento canadiense o británico sirve igual.
    final VoiceChoice? choice = pickVoice(<Object?>[
      <String, String>{'name': 'Daniel', 'locale': 'en-GB'},
    ], 'en-US');

    expect(choice!['locale'], 'en-GB');
  });

  test('las etiquetas con guion bajo cuentan igual', () {
    // Android informa `en_US` y el navegador `en-US`. Tratarlas como distintas
    // dejaría sin voz elegida a una de las dos plataformas.
    final VoiceChoice? choice = pickVoice(<Object?>[
      <String, String>{'name': 'Zira', 'locale': 'en_US'},
    ], 'en-US');

    expect(choice!['name'], 'Zira');
  });

  test('sin ninguna voz del idioma no se elige nada', () {
    // Devolver null es lo correcto: quien llama se queda con `setLanguage` o
    // avisa. Elegir una voz española para leer inglés sería el fallo original.
    expect(
      pickVoice(<Object?>[
        <String, String>{'name': 'Helena', 'locale': 'es-ES'},
      ], 'en-US'),
      isNull,
    );
    expect(pickVoice(<Object?>[], 'en-US'), isNull);
  });

  test('las entradas incompletas o de otro tipo se ignoran', () {
    // La lista llega del lado nativo sin tipar, y una entrada rara no debe
    // tirar la preparación de la voz entera.
    final VoiceChoice? choice = pickVoice(<Object?>[
      'basura',
      <String, String>{'name': '', 'locale': 'en-US'},
      <String, String>{'locale': 'en-US'},
      <String, String>{'name': 'Zira', 'locale': 'en-US'},
    ], 'en-US');

    expect(choice!['name'], 'Zira');
  });
}
