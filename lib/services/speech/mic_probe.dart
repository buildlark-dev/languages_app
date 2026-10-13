/// Preguntar por el micrófono antes de intentar reconocer.
///
/// Existe por lo reportado en un iPhone con la PWA instalada: el ejercicio de
/// pronunciación no reconocía nada. La API de reconocimiento del navegador no
/// pide el permiso de forma fiable —en iOS, dentro de una app instalada,
/// `start()` puede terminar sin resultado y **sin diálogo**—, así que la
/// persona ni siquiera llegaba a tener la oportunidad de conceder nada.
///
/// `getUserMedia` sí lo pide, y además dice por qué falla. De ahí esta sonda:
/// se ejecuta al tocar «Hablar», dispara el diálogo del sistema donde haga
/// falta, y convierte el motivo real en algo que la interfaz pueda explicar.
///
/// En Android y escritorio no aporta nada —el plugin pide el permiso él
/// mismo—, así que allí responde «no aplica» y la ruta queda exactamente como
/// estaba.
library;

import 'stt_service.dart';

/// Lo que se averiguó antes de escuchar.
class MicProbe {
  const MicProbe(this.failure);

  /// Se puede escuchar, o no hay nada que esta sonda pueda decir.
  const MicProbe.ok() : failure = null;

  /// Por qué no se va a poder escuchar, si ya se sabe.
  ///
  /// Nulo **no** significa que vaya a funcionar: significa que esta sonda no
  /// tiene nada que objetar. El intento sigue mandando.
  final SttFailure? failure;
}
