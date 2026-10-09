/// Contrato de reconocimiento de habla.
///
/// Es el servicio con la degradación más delicada del proyecto, y la razón está en
/// D6 de research.md: **el reconocimiento en el dispositivo no se puede
/// garantizar**. La opción `onDevice` existe y Android la respeta, pero la sesión
/// *falla* si no está disponible, y en la práctica el dispositivo necesita el
/// paquete de idioma offline instalado. En web la opción no existe siquiera: el
/// plugin ni lee el parámetro, y la API del navegador manda el audio a un
/// servicio remoto.
///
/// Eso choca con FR-039 ("completar lecciones sin conexión"), porque un ejercicio
/// de pronunciación es parte de una lección. La resolución: la **alternativa
/// accesible** que FR-019 ya exige para quien no puede usar micrófono cumple
/// simultáneamente como ruta sin conexión.
///
/// ## Dos preguntas distintas, y confundirlas costó caro
///
/// [SttAvailability] responde «¿qué se puede hacer con el micrófono de este
/// aparato?», y se consulta **sin pedir permiso**. [SttFailure] responde «¿por
/// qué no salió **este** intento?», y solo existe después de intentarlo.
///
/// Antes eran lo mismo, y el resultado fue que un fallo puntual —el navegador
/// que lanza al consultar un permiso que nadie ha concedido todavía— quedaba
/// registrado como «esta plataforma no soporta reconocimiento» y apagaba el
/// micrófono en toda la app. Un intento fallido no es una propiedad del
/// dispositivo.
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

/// Por qué no se pudo escuchar **este** intento.
///
/// Cada valor sale de un código que la plataforma informa de verdad, no de una
/// suposición. Que exista esta lista es la corrección de un fallo medible: el
/// servicio pasaba `onError: (_) {}`, así que tiraba el diagnóstico y esperaba
/// a que venciera su propio reloj —seis segundos más dos de pausa, y otra vez
/// para el segundo paso—. En el navegador el permiso denegado se informa en
/// milisegundos; la app tardaba dieciséis segundos en caer a la alternativa
/// escrita y no decía ni una palabra del micrófono.
enum SttFailure {
  /// Falta el permiso del micrófono, o está bloqueado para este sitio.
  permissionDenied,

  /// El reconocedor necesita conexión y no la hay.
  needsNetwork,

  /// El reconocedor no tiene ese idioma.
  languageUnsupported,

  /// No hay reconocedor utilizable en esta plataforma o aparato.
  noRecognizer,

  /// Hay reconocedor pero no se pudo capturar audio.
  noMicrophone,

  /// Falló por un motivo que la plataforma no explica.
  unknown;

  /// Si reintentar con el reconocedor del sistema puede cambiar algo.
  ///
  /// Reintentar un permiso denegado solo gasta el tiempo de quien espera.
  bool get worthRetryingOverNetwork =>
      this == SttFailure.noRecognizer || this == SttFailure.unknown;
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

/// No se pudo escuchar. La interfaz debe ofrecer la alternativa **y decir por qué**.
///
/// Tampoco es un fallo de contenido: es el camino válido que SC-008 exige que
/// exista siempre. Lo que sí es obligatorio es explicarlo, porque FR-017 y
/// FR-018 piden que la persona sepa qué pasó con su micrófono.
final class SttUseAlternative extends SttOutcome {
  const SttUseAlternative(this.failure);
  final SttFailure failure;
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
