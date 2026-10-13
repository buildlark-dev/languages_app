/// Reserva volátil en Android, iOS, Windows, macOS y Linux.
library;

import 'package:drift/native.dart';

import 'app_database.dart';

/// Base en memoria. Lo que se guarde se pierde al cerrar la app, y la interfaz
/// lo avisa (FR-043).
AppDatabase openMemoryDatabase() =>
    AppDatabase.withExecutor(NativeDatabase.memory());
