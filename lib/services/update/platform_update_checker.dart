/// El comprobador de versiones de esta plataforma.
///
/// Exportación condicional, el mismo mecanismo que `memory_database.dart`: el
/// archivo web usa `dart:js_interop`, que no existe en la VM de Dart ni en
/// Android, y basta con que `main.dart` lo importe para que el build nativo
/// falle. Cada destino compila solo su archivo.
library;

export 'platform_update_checker_stub.dart'
    if (dart.library.js_interop) 'platform_update_checker_web.dart';
