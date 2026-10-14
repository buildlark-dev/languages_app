/// Voz con clip propio primero y síntesis del sistema como respaldo.
///
/// ## Por qué el clip va primero
///
/// Porque la síntesis del sistema falló de tres formas distintas, y las tres
/// eran invisibles hasta que alguien tocaba un botón:
///
/// * en el navegador, `getVoices()` devuelve la lista vacía en la primera
///   consulta;
/// * en iOS la devuelve vacía hasta que **algo ha hablado**, de modo que
///   preguntar antes de hablar no podía responder nunca que sí;
/// * y cuando sí hay voces, la que el sistema elige por defecto es la del
///   idioma del documento —español— leyendo inglés: suena, así que ninguna
///   detección lo nota, y enseña una pronunciación equivocada.
///
/// Un archivo dentro de la app no tiene ninguno de esos problemas. Suena igual
/// en los tres destinos, no depende de nada instalado, y funciona sin conexión
/// de verdad y no «si el dispositivo tiene la voz».
///
/// ## Y por qué la síntesis sigue aquí
///
/// Porque el contenido nuevo no tiene clip hasta que alguien ejecuta el
/// generador. Cuando se añada A2, o una palabra a un módulo, la síntesis cubre
/// el hueco en lugar de dejar un botón mudo. El respaldo es la mitad que hace
/// aceptable la primera: sin él, olvidar regenerar el audio sería un fallo
/// silencioso más.
library;

import 'clip_key.dart';
import 'clip_player.dart';
import 'tts_service.dart';

class ClipBackedTtsService implements TtsService {
  ClipBackedTtsService({
    required TtsService voice,
    required ClipPlayer clips,
    required Map<String, String> catalog,
  }) : _voice = voice,
       _clips = clips,
       _catalog = catalog;

  final TtsService _voice;
  final ClipPlayer _clips;

  /// De clave de texto a ruta del clip. Lo genera `tool/generate_audio.ps1`.
  final Map<String, String> _catalog;

  @override
  TtsAvailability get availability => _voice.availability;

  @override
  Future<TtsAvailability> initialize(String languageTag) =>
      _voice.initialize(languageTag);

  @override
  Future<SpeakOutcome> speak(String text) async {
    final String? asset = _catalog[clipKey(text)];

    if (asset != null) {
      final ClipOutcome outcome = await _clips.play(asset);
      if (outcome.ok) return SpeakOutcome.spoken;
      // Si el clip existe y falla —un asset que no se empaquetó, un códec que
      // el navegador no acepta—, todavía queda la síntesis. Rendirse aquí
      // sería cambiar un fallo por otro.
    }

    return _voice.speak(text);
  }

  @override
  Future<void> stop() async {
    // Las dos: no se sabe cuál estaba sonando, y parar la que no suena no
    // cuesta nada. Dejar una viva es el fallo que ya se reportó una vez.
    await _clips.stop();
    await _voice.stop();
  }

  /// La velocidad solo afecta a la síntesis.
  ///
  /// Un clip grabado suena a la velocidad a la que se grabó, y cambiar eso
  /// exigiría procesar el audio en el dispositivo. Queda así, dicho en voz
  /// alta: el ajuste de Ajustes no mueve los clips.
  @override
  Future<void> setRate(double rate) => _voice.setRate(rate);
}
