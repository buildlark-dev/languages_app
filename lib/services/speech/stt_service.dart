/// Contrato de reconocimiento de habla.
///
/// Es el servicio con la degradación más delicada del proyecto, y la razón está en
/// D6 de research.md: **el reconocimiento en el dispositivo no se puede
/// garantizar**. La opción `onDevice` existe y Android la respeta, pero la sesión
/// *falla* si no está disponible, y en la práctica el dispositivo necesita el
/// paquete de idioma offline instalado. En web, la API del navegador manda el
/// audio a un servicio remoto y exige conexión.
///
/// Eso choca con FR-039 ("completar lecciones sin conexión"), porque un ejercicio
/// de pronunciación es parte de una lección. La resolución: la **alternativa
/// accesible** que FR-019 ya exige para quien no puede usar micrófono cumple
/// simultáneamente como ruta sin conexión.
library;

/// Qué se puede hacer con el micrófono en este dispositivo.
enum SttAvailability {
  /// Reconocimiento local disponible: funciona sin conexión.
  onDeviceReady,

  /// Solo con red, a través del servicio del sistema.
  networkOnly,

  /// La persona negó el permiso.
  permissionDenied,

  /// No hay micrófono.
  noMicrophone,

  /// La plataforma no soporta reconocimiento.
  unsupportedPlatform;

  /// Si vale la pena ofrecer el micrófono.
  bool get canListen =>
      this == SttAvailability.onDeviceReady ||
      this == SttAvailability.networkOnly;
}

/// Resultado de escuchar una vez.
sealed class SttOutcome {
  const SttOutcome();
}

/// Se entendió algo.
final class SttRecognized extends SttOutcome {
  const SttRecognized(this.text);
  final String text;
}

/// El micrófono funcionó pero no se detectó habla.
///
/// **No es un fallo de contenido** (FR-020): no se oyó nada, no es que se dijera
/// mal.
final class SttNoSpeech extends SttOutcome {
  const SttNoSpeech();
}

/// No se pudo escuchar. La interfaz debe ofrecer la alternativa.
///
/// Tampoco es un fallo de contenido: es el camino válido que SC-008 exige que
/// exista siempre.
final class SttUseAlternative extends SttOutcome {
  const SttUseAlternative(this.reason);
  final SttAvailability reason;
}

abstract interface class SttService {
  /// Qué se puede hacer, **sin pedir permiso todavía**.
  ///
  /// Separado de [requestPermission] porque FR-018 exige pedir el micrófono solo
  /// cuando la persona va a usarlo, y explicando para qué. Preguntarlo al arrancar
  /// es la forma más rápida de que lo nieguen.
  Future<SttAvailability> checkAvailability();

  /// Pide el permiso. Se invoca solo al ir a usar el micrófono.
  Future<bool> requestPermission();

  /// Escucha una vez y devuelve lo que pasó. Nunca lanza.
  Future<SttOutcome> listenOnce(String languageTag);

  Future<void> cancel();
}
