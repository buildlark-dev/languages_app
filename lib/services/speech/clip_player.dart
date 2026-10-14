/// Contrato de reproducir un clip de audio del paquete.
///
/// Separado de [TtsService] a propósito: son dos cosas distintas que suenan
/// parecido. La síntesis **fabrica** la voz en el dispositivo y depende de que
/// haya un motor y una voz del idioma; esto solo **reproduce un archivo** que
/// ya viene dentro de la app, así que no puede fallar por falta de voz, ni
/// sonar con acento español, ni esperar a que el navegador publique su lista.
///
/// Esa independencia es el motivo de T196. Tres rondas de arreglos salieron de
/// que escuchar una palabra dependiera del motor del sistema.
library;

/// Qué pasó al intentar reproducir.
enum ClipOutcome {
  /// Está sonando.
  played,

  /// No hay clip para ese texto. No es un fallo: el contenido nuevo no tiene
  /// audio hasta que alguien ejecuta el generador.
  noClip,

  /// Hay clip y no se pudo reproducir.
  failed;

  bool get ok => this == ClipOutcome.played;
}

abstract interface class ClipPlayer {
  /// Reproduce el clip de [assetPath]. Nunca lanza.
  Future<ClipOutcome> play(String assetPath);

  /// Calla lo que esté sonando. Nunca lanza.
  Future<void> stop();
}
