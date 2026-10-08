/// Reserva volátil en el navegador.
///
/// Se construye con `DatabaseConnection.delayed` porque abrir sqlite sobre
/// WebAssembly es asíncrono —hay que descargar `sqlite3.wasm`— y quien llama
/// necesita una base de forma sincrónica. La conexión diferida resuelve esa
/// diferencia: la base existe de inmediato y la primera consulta espera a que
/// termine de abrirse.
///
/// Drift elige por su cuenta el mejor almacenamiento que el navegador ofrezca y
/// cae a memoria cuando no hay ninguno, así que esta reserva es de verdad la
/// segunda oportunidad: puede acabar siendo persistente si lo que falló en el
/// primer intento fue transitorio.
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'app_database.dart';

AppDatabase openMemoryDatabase() => AppDatabase.withExecutor(
  DatabaseConnection.delayed(
    Future<DatabaseConnection>(() async {
      final WasmDatabaseResult result = await WasmDatabase.open(
        databaseName: 'languages_app_fallback',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    }),
  ),
);
