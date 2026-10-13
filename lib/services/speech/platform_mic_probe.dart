/// La sonda de micrófono de esta plataforma.
///
/// Exportación condicional, el mismo mecanismo que usan la base de reserva y el
/// comprobador de versiones: el archivo web usa `dart:js_interop`, que no
/// existe en la VM de Dart ni en Android.
library;

export 'platform_mic_probe_stub.dart'
    if (dart.library.js_interop) 'platform_mic_probe_web.dart';
