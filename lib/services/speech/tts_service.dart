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

abstract interface class TtsService {
  /// Prepara la voz del idioma dado. Nunca lanza.
  Future<TtsAvailability> initialize(String languageTag);

  /// Lo último que devolvió [initialize].
  TtsAvailability get availability;

  /// Lee el texto. **No-op silencioso** si no está disponible.
  ///
  /// Silencioso y no excepción porque quien llama es un widget: obligar a cada
  /// botón de audio a envolver la llamada en `try` repartiría la misma
  /// comprobación por toda la interfaz.
  Future<void> speak(String text);

  Future<void> stop();

  /// Velocidad de lectura, de 0.0 a 1.0.
  Future<void> setRate(double rate);
}
