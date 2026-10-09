/// Contrato de síntesis de voz.
///
/// Obligación central: **nunca lanza y nunca asume**. `initialize` consulta qué
/// voces hay de verdad y lo informa; si falta la del idioma estudiado, la interfaz
/// presenta el transcript en lugar de un botón de audio que no suena.
///
/// Un botón que no hace nada es peor que no tener botón: la persona lo toca
/// varias veces, concluye que la app está rota y no se enteró de que el problema
/// era su dispositivo.
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
  /// Devolver el resultado en lugar de callar es una corrección. Antes era un
  /// no-op silencioso y la interfaz escondía el botón cuando [availability]
  /// decía que no había voz; el problema es que esa detección falla sola en
  /// web —el navegador devuelve la lista de voces **vacía** en la primera
  /// consulta, hasta que termina de cargarlas—, y entonces el botón no se
  /// dibujaba en ninguna parte y la función desaparecía sin dejar rastro ni
  /// explicación.
  ///
  /// La regla nueva: el control existe siempre y el intento decide. Si no se
  /// puede hablar, quien llama lo sabe y puede decir por qué.
  Future<SpeakOutcome> speak(String text);

  Future<void> stop();

  /// Velocidad de lectura, de 0.0 a 1.0.
  Future<void> setRate(double rate);
}
