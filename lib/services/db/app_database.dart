/// La base de datos local. Fuente de verdad del progreso.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'migrations.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Versión del esquema persistido.
///
/// Toda subida obliga a un paso en [buildMigrationStrategy] y a una prueba que
/// demuestre que no se perdió progreso (Principio IV).
const int appSchemaVersion = 1;

@DriftDatabase(
  tables: <Type>[
    SchemaMeta,
    StudentProfile,
    LevelProgress,
    ActivityResults,
    ReviewCards,
    PlacementResults,
    SyncMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Base de producción, abierta según la plataforma.
  ///
  /// `web` es **obligatorio** aunque parezca específico de un destino: sin él,
  /// `driftDatabase` lanza `ArgumentError` al compilar a web, y como el error
  /// ocurre al construir la base, `openAppDatabase` lo captura y cae a la
  /// reserva volátil. El resultado era una app web que arrancaba bien, avisaba
  /// de que el progreso no se guardaba, y efectivamente no lo guardaba. En
  /// Android y escritorio este parámetro se ignora.
  ///
  /// Las dos rutas son relativas al directorio publicado, donde `web/` deja
  /// `sqlite3.wasm` y `drift_worker.js`.
  AppDatabase()
    : super(
        driftDatabase(
          name: 'languages_app',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  /// Base con un ejecutor dado. La usan las pruebas con una base en memoria.
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => appSchemaVersion;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);
}
