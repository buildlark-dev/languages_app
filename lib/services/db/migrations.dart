/// Política de migración del esquema local.
///
/// Obligación del Principio IV: **ningún cambio de esquema puede borrar o
/// invalidar progreso existente.**
///
/// Las reglas, para quien añada una versión 2:
///
/// 1. Subir [appSchemaVersion] y añadir un `from(n).to(n+1)` aquí.
/// 2. Preferir cambios **aditivos**: columna con valor por defecto, tabla nueva,
///    índice nuevo. Renombrar o eliminar exige copiar los datos a la forma nueva
///    dentro de la misma transacción.
/// 3. Escribir una prueba que parta de una base poblada en la versión anterior y
///    verifique que ningún puntaje, XP, racha ni tarjeta se perdió.
///
/// La versión 1 nace con el mecanismo ya montado y probado, aunque no haya nada
/// que convertir todavía. El momento de construir el rescate no es cuando ya hay
/// progreso de estudiantes en juego.
library;

import 'package:drift/drift.dart';

import 'app_database.dart';

MigrationStrategy buildMigrationStrategy(AppDatabase db) => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
    await db
        .into(db.schemaMeta)
        .insert(
          SchemaMetaRow(
            id: 1,
            version: appSchemaVersion,
            createdAt: DateTime.now(),
          ),
        );
  },
  onUpgrade: (Migrator m, int from, int to) async {
    // No hay pasos todavía: v1 es la primera versión. Cuando exista v2, el
    // recorrido va aquí, paso a paso y siempre aditivo.
    //
    // La escritura de la versión alcanzada queda fuera del bucle a propósito:
    // así un paso que falle a medias no deja registrada una versión que no se
    // completó.
    await db
        .update(db.schemaMeta)
        .write(
          SchemaMetaRow(
            id: 1,
            version: to,
            createdAt: DateTime.now(),
            migratedAt: DateTime.now(),
          ),
        );
  },
  beforeOpen: (OpeningDetails details) async {
    // Las claves foráneas no se usan todavía, pero activarlas desde el principio
    // evita que una versión futura las añada y descubra datos ya inconsistentes.
    await db.customStatement('PRAGMA foreign_keys = ON');
  },
);
