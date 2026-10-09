/// Contrato de síntesis de voz.
///
/// Obligación central: **nunca lanza y nunca asume**. `initialize` consulta qué
/// voces hay de verdad y lo informa, y `speak` dice qué pasó al intentarlo.
///
/// Lo segundo es una corrección de lo primero. Durante un tiempo esta cabecera
/// decía que la interfaz debía presentar el transcript «en lugar de un botón de
/// audio que no suena», y el razonamiento era bueno: un botón que no hace nada
/// hace que la persona lo toque tres veces y concluya que la app está rota.
///
/// La consecuencia fue peor que el problema. `initialize` se equivoca sola —en
/// el navegador la lista de voces llega **vacía** en la primera consulta— y
/// entonces no se dibujaba ningún botón en ninguna parte: la función
/// desaparecía entera, sin aviso y sin forma de averiguar por qué.
///
/// **La regla vigente: el control existe siempre y el intento decide.** Por eso
/// `speak` devuelve un resultado en lugar de callar; quien llama puede decir
/// qué pasó, y decirlo sin exigir que nadie configure su aparato.
library;

/// Qué se pudo preparar.
enum TtsAvailability {
  /// Hay motor y hay voz del idioma pedido.
  available,

  /// El motor existe pero no tiene voz de ese idioma instalada.
  languageMissing,

  /// El dispositivo no tiene motor de síntesis.
  engineMissing,

  /// La plataforma no soporta síntesis.
  unsupportedPlatform;

  bool get canSpeak => this == TtsAvailability.available;
}

/// Qué pasó al intentar hablar.
enum SpeakOutcome {
  /// Está sonando.
  spoken,

  /// No hay voz instalada para el idioma, o no hay motor.
  noVoice,

  /// El motor falló por otro motivo.
  failed;

  bool get ok => this == SpeakOutcome.spoken;
}

abstract interface class TtsService {
  /// Prepara la voz del idioma dado. Nunca lanza.
  Future<TtsAvailability> initialize(String languageTag);

  /// Lo último que devolvió [initialize].
  TtsAvailability get availability;

  /// Lee el texto, y **dice qué pasó**. Nunca lanza.
  ///
  /// Quien llama es un botón: necesita saber si sonó para poder explicarlo, y
  /// no puede permitirse una excepción a mitad de una lección.
  Future<SpeakOutcome> speak(String text);

  Future<void> stop();

  /// Velocidad de lectura, de 0.0 a 1.0.
  Future<void> setRate(double rate);
}
