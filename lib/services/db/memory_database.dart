/// La base de reserva volátil, elegida por plataforma.
///
/// Existe porque `main.dart` no puede importar `package:drift/native.dart`: eso
/// arrastra `dart:ffi`, que **no existe en web**, y el build web falla al
/// compilar con un error que apunta a sqlite3 y no a la línea culpable.
///
/// La exportación condicional es el mecanismo estándar de Dart para esto: cada
/// destino compila solo su archivo, y el otro no se analiza siquiera. El archivo
/// por defecto lanza, porque llegar a él significaría una plataforma sin ninguna
/// de las dos bibliotecas.
library;

export 'memory_database_stub.dart'
    if (dart.library.ffi) 'memory_database_native.dart'
    if (dart.library.js_interop) 'memory_database_web.dart';
