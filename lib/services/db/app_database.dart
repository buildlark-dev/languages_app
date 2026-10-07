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
  AppDatabase() : super(driftDatabase(name: 'languages_app'));

  /// Base con un ejecutor dado. La usan las pruebas con una base en memoria.
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => appSchemaVersion;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);
}
