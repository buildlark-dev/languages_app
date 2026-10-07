/// Doble de [SttService] capaz de simular **cada** estado de disponibilidad y
/// **cada** variante de resultado.
///
/// El contrato de servicios lo exige explícitamente: la ruta alternativa es un
/// requisito verificable (SC-008), no un caso excepcional, así que tiene que poder
/// probarse igual de bien que el camino con micrófono.
library;

import 'package:languages_app/services/speech/stt_service.dart';

class FakeSttService implements SttService {
  FakeSttService({
    this.availability = SttAvailability.onDeviceReady,
    this.outcome = const SttNoSpeech(),
    this.grantPermission = true,
  });

  /// Lo que devolverá [checkAvailability].
  SttAvailability availability;

  /// Lo que devolverá [listenOnce].
  SttOutcome outcome;

  /// Si [requestPermission] concede.
  bool grantPermission;

  /// Cuántas veces se pidió el permiso.
  ///
  /// Sirve para comprobar FR-018: no se pide al arrancar, solo al ir a usar el
  /// micrófono.
  int permissionRequests = 0;

  int listenCalls = 0;
  int cancelCalls = 0;

  @override
  Future<SttAvailability> checkAvailability() async => availability;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (!grantPermission) availability = SttAvailability.permissionDenied;
    return grantPermission;
  }

  @override
  Future<SttOutcome> listenOnce(String languageTag) async {
    listenCalls++;
    return outcome;
  }

  @override
  Future<void> cancel() async => cancelCalls++;
}
