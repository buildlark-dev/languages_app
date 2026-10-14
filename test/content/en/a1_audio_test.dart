/// Que no falte ni sobre un clip de audio en A1.
///
/// Es la prueba que convierte «el audio está empaquetado» en algo comprobable.
/// Sin ella, añadir una palabra al contenido y olvidar regenerar el audio deja
/// un botón que cae a la síntesis sin que nadie se entere —y la síntesis es
/// justo de lo que T196 vino a no depender—.
///
/// Comprueba tres cosas, y las tres han fallado alguna vez en este proyecto en
/// alguna de sus formas: que el inventario y el manifiesto coinciden, que los
/// archivos existen de verdad en el disco, y que el manifiesto no arrastra
/// clips de contenido que ya se borró.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/content/en/a1_audio_manifest.dart';
import 'package:languages_app/content/en/english_course.dart';
import 'package:languages_app/services/speech/clip_key.dart';
import 'package:languages_app/services/speech/spoken_texts.dart';

void main() {
  const EnglishContentPack pack = EnglishContentPack();
  final List<String> spoken = spokenTextsOf(pack);

  test('el inventario no está vacío', () {
    // Una lista vacía haría pasar todo lo demás sin comprobar nada.
    expect(spoken.length, greaterThan(50));
  });

  test('cada texto hablado tiene su clip', () {
    final List<String> missing = spoken
        .where((String text) => !a1AudioClips.containsKey(clipKey(text)))
        .toList(growable: false);

    expect(
      missing,
      isEmpty,
      reason:
          'Sin clip, esos textos dependen de la voz del sistema. Ejecuta '
          'tool/generate_audio.ps1',
    );
  });

  test('cada clip del manifiesto existe en el disco', () {
    // El manifiesto puede quedar bien y el archivo no haberse generado: son
    // dos pasos distintos del mismo script.
    final List<String> absent = a1AudioClips.values
        .where((String path) => !File(path).existsSync())
        .toList(growable: false);

    expect(absent, isEmpty, reason: 'Faltan archivos de audio en el paquete');
  });

  test('el manifiesto no guarda clips de contenido que ya no existe', () {
    // Lo contrario del caso anterior: borrar una palabra del contenido y
    // dejar su audio ocupando espacio en cada instalación.
    final Set<String> wanted = spoken.map(clipKey).toSet();
    final Iterable<String> orphans = a1AudioClips.keys.where(
      (String key) => !wanted.contains(key),
    );

    expect(orphans, isEmpty, reason: 'Sobran clips: regenera el audio');
  });

  test('la lista que precarga el service worker tiene todos los clips', () {
    // Sin esta lista los clips solo se piden al tocar una palabra, así que no
    // entran en la caché y la primera lección sin conexión se queda sin audio
    // —medido: cero clips guardados tras una carga completa—. Que la lista se
    // desincronice del manifiesto reintroduce ese fallo en silencio.
    final List<String> served =
        (jsonDecode(File('web/audio_clips.json').readAsStringSync())
                as List<Object?>)
            .cast<String>();

    final Set<String> expected = a1AudioClips.values
        // Flutter sirve los assets bajo un segundo `assets/`, así que la ruta
        // del manifiesto no es la que pide el navegador.
        .map((String path) => 'assets/$path')
        .toSet();

    expect(served.toSet(), expected);
  });

  test('los clips declarados en pubspec cubren la carpeta del audio', () {
    // Un asset que no está declarado no viaja en el paquete, y el fallo solo
    // aparece en el dispositivo.
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/audio/en/'));
  });
}
