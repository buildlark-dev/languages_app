/// Reserva para una plataforma sin `dart:ffi` ni `dart:js_interop`.
///
/// No debería alcanzarse nunca. Lanza en lugar de devolver algo inservible: un
/// almacén que acepta escrituras y las pierde en silencio es peor que un error
/// en el arranque, porque el estudiante no se entera hasta que su avance ya no
/// está.
library;

import 'app_database.dart';

AppDatabase openMemoryDatabase() => throw UnsupportedError(
  'Esta plataforma no ofrece ninguna base de reserva en memoria',
);
