/// Guarda dos decisiones que solo fallan al compilar para web.
///
/// Ambas se inspeccionan leyendo el código fuente, igual que la prueba de
/// arquitectura inspecciona los `import`. No es elegante, y es lo único que
/// funciona: las dos se manifiestan **solo** en el destino web, donde una prueba
/// de la VM de Dart no llega, y las dos fallan en silencio —la app arranca, se
/// ve bien, y no guarda nada—, que es la peor forma de fallar.
///
/// Las dos se descubrieron de verdad, verificando el build web antes de
/// desplegar, y por eso están aquí.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la base de producción pasa opciones web a driftDatabase', () {
    // `driftDatabase` **lanza** `ArgumentError` en web si falta `web:`. Como el
    // error ocurre al construir la base, `openAppDatabase` lo captura y cae a la
    // reserva volátil: la app web arrancaba, avisaba de que el progreso no se
    // guardaba, y efectivamente no lo guardaba.
    final String source = File(
      'lib/services/db/app_database.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('DriftWebOptions'),
      reason:
          'Sin DriftWebOptions, driftDatabase lanza en web y toda la app '
          'acaba sobre la base en memoria',
    );
    expect(source, contains('sqlite3Wasm'));
    expect(source, contains('driftWorker'));
  });

  test('la raíz de composición no importa drift/native', () {
    // `package:drift/native.dart` arrastra `dart:ffi`, que no existe en web. El
    // build falla con un error que apunta a sqlite3 y no a la línea culpable,
    // así que conviene atraparlo aquí. La reserva volátil llega por importación
    // condicional desde `memory_database.dart`.
    // Se buscan líneas de `import`, no la cadena suelta: el propio comentario
    // que explica el problema la menciona, y una prueba que falle por su propia
    // documentación es una prueba que acaba borrada.
    final List<String> imports = File('lib/main.dart')
        .readAsLinesSync()
        .where((String line) => line.trimLeft().startsWith('import '))
        .toList(growable: false);

    expect(
      imports.where((String line) => line.contains('drift/native.dart')),
      isEmpty,
      reason: 'dart:ffi no existe en web; usa memory_database.dart',
    );
  });

  test('los recursos de drift para web están en su sitio', () {
    // Sin estos dos archivos el navegador no puede abrir sqlite, y el síntoma
    // es el mismo: la app arranca y no guarda.
    expect(File('web/sqlite3.wasm').existsSync(), isTrue);
    expect(File('web/drift_worker.js').existsSync(), isTrue);
  });

  test('solo el destino nativo de la reserva importa drift/native', () {
    // La exportación condicional es lo que mantiene `dart:ffi` fuera del build
    // web. Si alguien colapsara los tres archivos en uno, el build volvería a
    // romperse.
    String importsOf(String path) => File(path)
        .readAsLinesSync()
        .where((String line) => line.trimLeft().startsWith('import '))
        .join('\n');

    final String native = importsOf(
      'lib/services/db/memory_database_native.dart',
    );
    final String web = importsOf('lib/services/db/memory_database_web.dart');

    expect(native, contains('drift/native.dart'));
    expect(web, isNot(contains('drift/native.dart')));
    expect(web, contains('drift/wasm.dart'));
  });
}
