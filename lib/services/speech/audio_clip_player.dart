/// Reproduce los clips con `audioplayers`.
///
/// La dependencia hace falta porque Flutter no reproduce audio por sí solo, y
/// se justifica en D5 de research.md junto con la decisión de empaquetar los
/// clips. Se eligió `audioplayers` por soportar las tres plataformas que
/// importan aquí —Android, web y iOS— con la misma API.
///
/// Un solo reproductor reutilizado, no uno por clip: así una palabra nueva
/// corta la anterior en lugar de solaparse con ella, que es el fallo que se
/// reportó con la síntesis («se quedan reproduciendo cuando uno cambia de
/// ejercicio»).
library;

import 'package:audioplayers/audioplayers.dart';

import 'clip_player.dart';

class AudioClipPlayer implements ClipPlayer {
  AudioClipPlayer(this._player);

  final AudioPlayer _player;

  @override
  Future<ClipOutcome> play(String assetPath) async {
    try {
      // `AssetSource` cuelga de `assets/` por convención del paquete, así que
      // la ruta del manifiesto —que empieza por `assets/`— se recorta aquí. El
      // manifiesto guarda la ruta completa porque es la que verifica la prueba
      // de integridad contra el disco.
      final String source = assetPath.startsWith('assets/')
          ? assetPath.substring('assets/'.length)
          : assetPath;

      await _player.stop();
      await _player.play(AssetSource(source));
      return ClipOutcome.played;
    } catch (_) {
      // Quien llama es un botón: no puede recibir una excepción a mitad de una
      // lección. Se informa y la interfaz decide qué decir.
      return ClipOutcome.failed;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Nada que hacer si ni parar funciona.
    }
  }
}
