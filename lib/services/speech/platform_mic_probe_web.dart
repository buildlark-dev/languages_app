/// Sonda de micrófono en el navegador.
///
/// La parte de JavaScript vive en `web/index.html`, junto a las otras dos
/// piezas que el navegador obliga a tener fuera del paquete de Dart. Aquí solo
/// queda traducir su respuesta a algo que la interfaz sepa explicar.
///
/// Si `appMic` no existe —una versión vieja del HTML servida desde la caché—,
/// la respuesta es «no hay nada que objetar» y el intento decide, que es la
/// regla de toda la app: ninguna detección puede apagar una función.
library;

import 'dart:js_interop';

import 'mic_probe.dart';
import 'stt_service.dart';

@JS('appMic')
external JSObject? get _appMic;

@JS('appMic.probe')
external JSPromise<JSString> _probe();

Future<MicProbe> probeMicrophone() async {
  if (_appMic == null) return const MicProbe.ok();

  try {
    final String reason = (await _probe().toDart).toDart;

    return switch (reason) {
      '' => const MicProbe.ok(),
      'not-allowed' => const MicProbe(SttFailure.permissionDenied),
      'no-microphone' => const MicProbe(SttFailure.noMicrophone),
      'no-recognizer' => const MicProbe(SttFailure.noRecognizer),
      _ => const MicProbe(SttFailure.unknown),
    };
  } catch (_) {
    // Que la sonda falle no es una respuesta sobre el micrófono.
    return const MicProbe.ok();
  }
}
