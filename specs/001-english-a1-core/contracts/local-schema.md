# Contract — Esquema local v1 y política de migración

**Feature**: `001-english-a1-core` | **Date**: 2026-10-06

Almacén: SQLite vía Drift. Es la **fuente de verdad** del progreso. Declarado en
`lib/services/db/tables.dart`, versionado en `lib/services/db/app_database.dart`.

**Versión del esquema: 1.**

---

## Tablas

### `schema_meta`

Una sola fila. Existe para que FR-044 sea verificable sin inferir la versión de la forma
de los datos.

| Columna | Tipo | Nota |
|---|---|---|
| `id` | `INTEGER` PK | siempre 1 |
| `version` | `INTEGER` | 1 en esta entrega |
| `created_at` | `DATETIME` | |
| `migrated_at` | `DATETIME?` | última migración aplicada |

### `student_profile`

| Columna | Tipo | Nota |
|---|---|---|
| `uid` | `TEXT` | parte de la PK |
| `course_id` | `TEXT` | parte de la PK |
| `current_level_id` | `TEXT` | |
| `xp` | `INTEGER` | ≥ 0 |
| `streak_count` | `INTEGER` | ≥ 0 |
| `last_activity_date` | `DATE?` | null si nunca estudió |

PK: (`uid`, `course_id`). Un estudiante puede tener progreso en varios cursos; en esta
entrega solo existe `en`, pero el esquema no lo impide.

### `level_progress`

| Columna | Tipo | Nota |
|---|---|---|
| `uid` | `TEXT` | PK |
| `course_id` | `TEXT` | PK |
| `level_id` | `TEXT` | PK |
| `state` | `INTEGER` | 0 locked · 1 unlocked · 2 mastered · 3 passed |

El estado se guarda como entero **a propósito**: su valor numérico es el orden de avance,
así que la fusión es un `MAX` literal, en Dart y en SQL.

### `activity_results`

| Columna | Tipo | Nota |
|---|---|---|
| `uid` | `TEXT` | PK |
| `course_id` | `TEXT` | PK |
| `activity_id` | `TEXT` | PK. id de lección o de examen |
| `activity_kind` | `INTEGER` | 0 lección · 1 examen de módulo · 2 examen de nivel |
| `best_score` | `REAL` | 0.0 a 1.0 |
| `attempts` | `INTEGER` | ≥ 1 |
| `last_attempt_at` | `DATETIME` | |

Guardar solo el **mejor** puntaje es lo que hace imposible que un reintento peor
desapruebe un módulo ya aprobado (FR-027). No es una comprobación en el código de la
interfaz: es la forma del dato.

### `review_cards`

| Columna | Tipo | Nota |
|---|---|---|
| `uid` | `TEXT` | PK |
| `course_id` | `TEXT` | PK |
| `module_id` | `TEXT` | PK |
| `term` | `TEXT` | PK |
| `translation` | `TEXT` | |
| `interval_step` | `INTEGER` | 0 a 5, índice en `[1,3,7,16,35,90]` |
| `due_date` | `DATE` | |
| `lapses` | `INTEGER` | ≥ 0 |

**Índice obligatorio**: `idx_review_due` sobre (`uid`, `course_id`, `due_date`). Sin él,
"qué vence hoy" recorre la tabla completa y la meta de 50 ms con 2.000 tarjetas no se
cumple.

### `placement_results`

| Columna | Tipo | Nota |
|---|---|---|
| `uid` | `TEXT` | PK |
| `course_id` | `TEXT` | PK |
| `estimated_level_id` | `TEXT` | cualquier nivel MCER, incluso sin contenido |
| `mastered_level_ids` | `TEXT` | lista separada por comas, solo niveles con contenido |
| `skipped` | `BOOLEAN` | true si omitió la prueba |
| `taken_at` | `DATETIME` | |

El **nivel asignado no se almacena**: se deriva del estimado contra el catálogo vigente en
cada arranque. Guardarlo obligaría a una migración cada vez que se publique un nivel nuevo,
y a que esa migración acertara con la intención de cada estudiante. Derivarlo lo hace
automático: el día que exista A2, quien tenga `estimated_level_id = 'B1'` empieza a estudiar
ahí sin que nadie toque la base.

### `sync_meta`

| Columna | Tipo | Nota |
|---|---|---|
| `uid` | `TEXT` | PK |
| `last_synced_at` | `DATETIME?` | |
| `has_pending_changes` | `BOOLEAN` | |
| `last_error` | `TEXT?` | |
| `storage_degraded` | `BOOLEAN` | |

Local por definición: describe la relación de *este* dispositivo con la nube y nunca viaja.

---

## Transacciones obligatorias

Aprobar una actividad toca hasta tres tablas. Todas las escrituras de una misma acción van
en **una** transacción, porque un corte a mitad dejaría estados imposibles:

| Acción | Tablas | Qué se evitaría sin transacción |
|---|---|---|
| Aprobar lección | `activity_results`, `student_profile`, `review_cards` | XP sumado sin lección aprobada |
| Aprobar examen de módulo | `activity_results`, `student_profile`, `level_progress` | módulo aprobado sin desbloquear el siguiente |
| Aprobar examen de nivel | `activity_results`, `level_progress` (el nivel superado y el siguiente **con contenido**, si existe) | nivel superado sin desbloquear el siguiente |
| Aplicar nivelación | `placement_results`, `level_progress` (varias), `student_profile` | niveles marcados a medias |
| Sincronizar | todas | mitad del progreso fusionado y mitad no |

---

## Política de migración

Obligación del Principio IV: **ningún cambio de esquema puede borrar o invalidar progreso
existente.**

Reglas:

1. Toda versión nueva incrementa `schemaVersion` en `app_database.dart` y añade un paso en
   `migrations.dart`.
2. Las migraciones son **aditivas por defecto**: añadir columna con valor por defecto,
   añadir tabla, añadir índice. Renombrar o eliminar exige copiar los datos a la forma
   nueva dentro de la misma transacción.
3. Toda migración tiene una prueba en `test/services/db/migrations_test.dart` que parte de
   una base poblada en la versión anterior y verifica que, tras migrar, **ningún dato de
   progreso se perdió**: mismos puntajes, mismo XP, misma racha, mismas tarjetas.
4. `schema_meta.migrated_at` se actualiza en cada migración aplicada.

**Decisión de arranque**: v1 nace con la prueba de migración ya escrita, ejercitando el
camino v1 → v1. No prueba una conversión real, pero deja montada y verificada la
infraestructura de migración **antes** de que exista una v2 que la necesite. El momento de
construir el mecanismo de rescate no es cuando ya hay progreso de estudiantes en juego.

---

## Degradación del almacenamiento

Si abrir o escribir la base falla —disco lleno, permisos, corrupción— el almacén cae a una
implementación en memoria y marca `sync_meta.storage_degraded`. La interfaz muestra
`offline_notice` con un mensaje explícito de que el avance de esta sesión no se está
guardando (FR-043, FR-023).

Nunca se falla en silencio y nunca se cierra la app: la persona puede seguir estudiando,
sabiendo en qué condición está.

---

## Web

Drift en web necesita, dentro de `web/`:

- `sqlite3.wasm`
- `drift_worker.js`

Ambos se descargan de las versiones publicadas de Drift que correspondan a la versión del
paquete. Queda como tarea de configuración explícita, verificada por una prueba manual de
persistencia en navegador documentada en [quickstart.md](../quickstart.md).
