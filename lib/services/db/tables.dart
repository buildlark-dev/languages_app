/// Esquema local v1: las siete tablas del progreso del estudiante.
///
/// Este es el almacén **autoritativo**. La nube sincroniza contra él, no al
/// contrario (D4 de research.md).
///
/// Dos decisiones de forma que importan más de lo que parecen:
///
/// * Los estados de nivel se guardan como entero, porque su valor numérico es el
///   orden de avance y así fusionar es un `MAX` literal.
/// * De cada actividad se guarda solo el **mejor** puntaje. Que un reintento
///   peor no pueda desaprobar algo ya aprobado no es una comprobación en el
///   código: es la forma del dato (FR-027).
library;

import 'package:drift/drift.dart';

/// Versión del esquema. Una sola fila, con `id` siempre 1.
///
/// Existe para que FR-044 sea verificable sin inferir la versión de la forma de
/// los datos.
@DataClassName('SchemaMetaRow')
class SchemaMeta extends Table {
  IntColumn get id => integer()();
  IntColumn get version => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get migratedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Perfil del estudiante en un curso.
@DataClassName('StudentProfileRow')
class StudentProfile extends Table {
  TextColumn get uid => text()();
  TextColumn get courseId => text()();
  TextColumn get currentLevelId => text()();
  IntColumn get xp => integer().withDefault(const Constant<int>(0))();
  IntColumn get streakCount => integer().withDefault(const Constant<int>(0))();
  DateTimeColumn get lastActivityDate => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{uid, courseId};
}

/// Estado de cada nivel con contenido.
///
/// Los niveles solo anunciados no aparecen: no tienen estado posible, que es la
/// razón estructural por la que no hay ruta para entrar en ellos (FR-038).
@DataClassName('LevelProgressRow')
class LevelProgress extends Table {
  TextColumn get uid => text()();
  TextColumn get courseId => text()();
  TextColumn get levelId => text()();

  /// 0 bloqueado · 1 desbloqueado · 2 dominado · 3 superado.
  IntColumn get state => integer()();

  @override
  Set<Column<Object>> get primaryKey =>
      <Column<Object>>{uid, courseId, levelId};
}

/// Mejor resultado de cada lección y de cada examen.
@DataClassName('ActivityResultRow')
class ActivityResults extends Table {
  TextColumn get uid => text()();
  TextColumn get courseId => text()();

  /// Identificador de la lección o del examen.
  TextColumn get activityId => text()();

  /// 0 lección · 1 examen de módulo · 2 examen de nivel.
  IntColumn get activityKind => integer()();

  /// Proporción de aciertos, de 0.0 a 1.0. Solo el mejor intento.
  RealColumn get bestScore => real()();

  IntColumn get attempts => integer().withDefault(const Constant<int>(1))();
  DateTimeColumn get lastAttemptAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey =>
      <Column<Object>>{uid, courseId, activityId};
}

/// Cola de repetición espaciada.
///
/// El índice sobre la fecha de vencimiento no es un lujo: sin él, "qué vence
/// hoy" recorre la tabla completa y la meta de 50 ms con 2.000 tarjetas no se
/// cumple.
@TableIndex(
  name: 'idx_review_due',
  columns: <Symbol>{#uid, #courseId, #dueDate},
)
@DataClassName('ReviewCardRow')
class ReviewCards extends Table {
  TextColumn get uid => text()();
  TextColumn get courseId => text()();
  TextColumn get moduleId => text()();
  TextColumn get term => text()();
  TextColumn get translation => text()();

  /// Índice en los intervalos 1·3·7·16·35·90, de 0 a 5.
  IntColumn get intervalStep => integer().withDefault(const Constant<int>(0))();

  DateTimeColumn get dueDate => dateTime()();
  IntColumn get lapses => integer().withDefault(const Constant<int>(0))();

  @override
  Set<Column<Object>> get primaryKey =>
      <Column<Object>>{uid, courseId, moduleId, term};
}

/// Resultado de la nivelación.
///
/// El nivel **asignado** no se guarda: se deriva del estimado contra el catálogo
/// vigente en cada arranque. Guardarlo obligaría a migrar la base cada vez que
/// se publique un nivel nuevo, y a que esa migración acertara con la intención
/// de cada estudiante.
@DataClassName('PlacementResultRow')
class PlacementResults extends Table {
  TextColumn get uid => text()();
  TextColumn get courseId => text()();

  /// Cualquier nivel MCER, incluso uno sin contenido construido.
  TextColumn get estimatedLevelId => text()();

  /// Lista separada por comas. Solo niveles con contenido.
  TextColumn get masteredLevelIds =>
      text().withDefault(const Constant<String>(''))();

  BoolColumn get skipped => boolean().withDefault(const Constant<bool>(false))();
  DateTimeColumn get takenAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{uid, courseId};
}

/// Relación de este dispositivo con la nube. Nunca viaja.
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get uid => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  BoolColumn get hasPendingChanges =>
      boolean().withDefault(const Constant<bool>(false))();
  TextColumn get lastError => text().nullable()();
  BoolColumn get storageDegraded =>
      boolean().withDefault(const Constant<bool>(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{uid};
}
