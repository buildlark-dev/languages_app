---

description: "Task list for the English A1 course core"
---

# Tasks: Núcleo del curso de inglés A1

**Input**: Design documents from `/specs/001-english-a1-core/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obligatorios, no opcionales.** El Principio V de la constitución exige pruebas
unitarias para toda la lógica del motor y al menos una prueba de widget por pantalla. Las
tareas de prueba están al mismo nivel que las de implementación y una fase no se cierra sin
ellas.

**Organization**: agrupadas por historia de usuario. Dentro de cada fase, el orden respeta el
grafo de dependencias del Principio II (`core` → `engine` → `services` → `ui`).

**Estrategia de entrega**: el responsable del proyecto descartó explícitamente una entrega
parcial. Los *checkpoints* de cada fase existen para **verificar**, no para publicar: nada se
despliega hasta que la Fase 11 esté completa.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: puede ejecutarse en paralelo (archivos distintos, sin dependencias pendientes)
- **[Story]**: a qué historia de usuario pertenece (US1 … US7)
- Toda tarea incluye su ruta de archivo exacta

## Path Conventions

Paquete Flutter único con capas internas, según `plan.md`: `lib/core/`, `lib/engine/`,
`lib/services/`, `lib/content/`, `lib/ui/`, y `test/` en espejo.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: dejar el proyecto compilando con todas las dependencias y la infraestructura
externa creada.

- [X] T001 Añadir dependencias a `pubspec.yaml`: `flutter_riverpod: ^3.4.3`, `drift: ^2.35.1`, `drift_flutter: ^0.3.1`, `firebase_core: ^4.15.0`, `firebase_auth: ^6.7.0`, `cloud_firestore: ^6.10.0`, `flutter_tts: ^4.2.5`, `speech_to_text: ^7.5.0`, `intl`, `flutter_localizations`; y en `dev_dependencies`: `drift_dev`, `build_runner`
- [X] T002 Crear `l10n.yaml` en la raíz con `arb-dir: lib/app/l10n`, `template-arb-file: app_es.arb`, `output-localization-file: app_localizations.dart`
- [X] T003 [P] Crear el árbol de carpetas vacío de `lib/core/`, `lib/engine/`, `lib/services/{db,auth,sync,speech,backup,settings}/`, `lib/content/en/`, `lib/ui/{providers,screens,widgets}/` y su espejo en `test/`
- [X] T004 [P] Revisar `analysis_options.yaml` y activar `prefer_const_constructors`, `require_trailing_commas` y `avoid_print`
- [X] T005 Crear el proyecto de Firebase y habilitar **Authentication** con proveedor de correo y contraseña, y **Cloud Firestore**
- [X] T006 Ejecutar `flutterfire configure`, que genera `lib/firebase_options.dart` y `android/app/google-services.json`; **versionar ambos** (son configuración pública de cliente, ver D12 de research.md)
- [X] T007 [P] Crear `firestore.rules` con las reglas exactas de `contracts/firestore.md`: acceso solo a `users/{uid}/courses/{courseId}` cuando `request.auth.uid == uid`, y denegación por defecto en `/{document=**}`
- [X] T008 [P] Crear `firebase.json` con Hosting apuntando a `build/web` y reescritura SPA de `**` hacia `/index.html`
- [X] T009 [P] Descargar `sqlite3.wasm` y `drift_worker.js` de la versión de Drift correspondiente a `^2.35.1` y colocarlos en `web/`
- [X] T010 Verificar que `flutter pub get`, `flutter analyze` y `flutter test` terminan sin errores sobre el proyecto vacío

**Checkpoint**: proyecto compilando con todas las dependencias e infraestructura creada.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: contratos, almacén y contenido que **todas** las historias necesitan.

**⚠️ CRITICAL**: ninguna historia puede empezar hasta cerrar esta fase.

### Core: contratos y modelos puros (sin un solo import de Flutter)

- [X] T011 [P] Crear `lib/core/clock.dart` con el tipo `Clock` (función que devuelve `DateTime`) y una implementación `systemClock`. El motor **nunca** llama a `DateTime.now()` (D9 de research.md)
- [X] T012 [P] Crear `lib/core/thresholds.dart` con `lessonPassThreshold = 0.70`, `examPassThreshold = 0.80` y `srsIntervals = [1, 3, 7, 16, 35, 90]` (días)
- [X] T013 [P] Crear `lib/core/level_state.dart` con el enum `LevelState` y **valor entero explícito**: `locked = 0`, `unlocked = 1`, `mastered = 2`, `passed = 3`. El orden numérico es el orden de avance y habilita la fusión por máximo
- [X] T014 [P] Crear `lib/core/vocabulary_item.dart` con `term`, `translation`, `hint` (nullable) y `spokenForm` (nullable)
- [X] T015 [P] Crear `lib/core/exercise.dart` con la jerarquía sellada de 5 variantes: `MultipleChoiceExercise`, `SentenceBuilderExercise`, `GapFillExercise`, `ListeningExercise` y `PronunciationExercise`. `explanation` es **obligatorio en las cinco**. `ListeningExercise` declara `transcriptFallback` y `PronunciationExercise` declara `writtenFallback`, ambos como parámetros **`required`**: un ejercicio oral sin alternativa accesible no debe compilar
- [X] T016 [P] Crear `lib/core/exam.dart` con `id`, `scope` (enum `ExamScope`: `module`, `level`, `placement`), `exercises` y `passThreshold` leído de `thresholds.dart`
- [X] T017 [P] Crear `lib/core/lesson.dart` con `id`, `title`, `readingRef` (nullable) y `exercises`. Las preguntas de comprensión de la lectura van **aquí**, no en el módulo, porque son lo único calificable junto al resto de ejercicios (FR-013)
- [X] T018 [P] Crear `lib/core/module.dart` con `id`, `order`, `title`, `canDo`, `vocabulary`, `grammar`, `examples`, `reading` (**solo el texto del pasaje**), `lessons` y `moduleExam`
- [X] T019 [P] Crear `lib/core/level.dart` con `id` restringido al conjunto MCER (`A1`, `A2`, `B1`, `B2`, `C1`, `C2`), `name`, `description`, `modules` y `levelExam` obligatorio
- [X] T020 [P] Crear `lib/core/course.dart` con `id`, `name`, `studyLanguageTag`, `supportLanguageTag`, `levels` (niveles **con contenido**), `upcomingLevelIds` (niveles anunciados **sin** contenido) y `placementTest` (nullable)
- [X] T021 [P] Crear `lib/core/review_card.dart` con clave compuesta `moduleId` + `term`, más `translation`, `intervalStep` (0 a 5), `dueDate` y `lapses`
- [X] T022 [P] Crear `lib/core/placement_result.dart` con `estimatedLevelId` (cualquier nivel MCER), `assignedLevelId` (**derivado**, no fuente de verdad), `masteredLevelIds`, `skipped` y `takenAt`
- [X] T023 [P] Crear `lib/core/sync_state.dart` con `lastSyncedAt` (nullable), `hasPendingChanges`, `lastError` (nullable) y `storageDegraded`
- [X] T024 Crear `lib/core/student_progress.dart` con `uid`, `courseId`, `schemaVersion`, `currentLevelId`, `xp`, `streakCount`, `lastActivityDate`, `levelStates`, `lessonResults`, `examResults`, `placement` y `syncState` (depende de T013, T021, T022, T023)
- [X] T025 Crear `lib/core/content_pack.dart` con el contrato que todo idioma implementa: `courseId`, `course` y `placementTest` (depende de T020)

### La regla de capas, verificada

- [X] T026 Crear `test/architecture/layer_dependencies_test.dart` que recorra todos los `.dart` de `lib/` e inspeccione sus `import`, exigiendo el grafo del **Principio II v1.1.0**: `core` no importa ninguna otra capa ni Flutter; `engine` no importa `ui`, `services`, `content` ni Flutter; `services` no importa `ui` ni `content`; `content` importa solo `core`; `ui` no importa `content`; y **solo `lib/main.dart`** importa `lib/content/catalog.dart`

### Almacén local

- [X] T027 Crear `lib/services/db/tables.dart` con las 7 tablas de `contracts/local-schema.md`: `schema_meta`, `student_profile`, `level_progress`, `activity_results`, `review_cards`, `placement_results` y `sync_meta`, con sus claves primarias compuestas exactas
- [X] T028 Añadir a `lib/services/db/tables.dart` el índice `idx_review_due` sobre `review_cards(uid, course_id, due_date)`. Sin él, "qué vence hoy" degrada a recorrido completo de tabla
- [X] T029 Crear `lib/services/db/app_database.dart` con `schemaVersion = 1` y la apertura por plataforma mediante `driftDatabase()` de `drift_flutter` (depende de T027)
- [X] T030 Crear `lib/services/db/migrations.dart` con el `MigrationStrategy`, que escribe `schema_meta` al crear y actualiza `migrated_at` en cada migración aplicada
- [X] T031 Ejecutar `dart run build_runner build --delete-conflicting-outputs` y confirmar que el código generado de Drift compila
- [X] T032 [P] Crear `lib/services/db/progress_dao.dart` con lectura y escritura de `student_profile`, `level_progress`, `activity_results` y `placement_results`, **siempre en transacción** según la tabla de `contracts/local-schema.md`
- [X] T033 [P] Crear `lib/services/db/review_dao.dart` con `dueToday()` apoyado en `idx_review_due`, `seed()` y `upsert()`
- [X] T034 Añadir a `lib/services/db/app_database.dart` la degradación a almacén en memoria cuando abrir o escribir falle, marcando `sync_meta.storage_degraded` (FR-043)
- [X] T035 [P] Crear `test/services/db/app_database_test.dart` con base en memoria, verificando persistencia de cada tabla y la degradación de T034
- [X] T036 [P] Crear `test/services/db/migrations_test.dart` que ejercite el camino v1 → v1 y verifique que **ningún dato de progreso se pierde**. Deja montada y probada la infraestructura de migración antes de que exista una v2 que la necesite
- [X] T037 [P] Crear `test/services/db/review_dao_test.dart` verificando que `dueToday()` devuelve solo lo vencido y que rinde por debajo de 50 ms con 2.000 tarjetas

### Motor compartido

- [X] T038 [P] Crear `lib/engine/answer_matcher.dart` que acepte **todas** las variantes declaradas de un hueco, ignorando mayúsculas y espacios sobrantes (FR-026)
- [X] T039 [P] Crear `test/engine/answer_matcher_test.dart` cubriendo variantes múltiples (`is` y `'s`), diferencias de mayúsculas, espacios al borde e interiores
- [X] T040 Crear `lib/engine/scoring.dart` que califique una lista de respuestas y resuelva aprobado contra `thresholds.dart` (depende de T012, T038)
- [X] T041 [P] Crear `test/engine/scoring_test.dart` con los casos frontera exactos: 69 %, 70 %, 79 % y 80 %
- [X] T042 Crear `lib/engine/lesson_session.dart` con el estado de una lección en curso: ejercicio actual, respuestas dadas, reintentos. Una sesión interrumpida se trata como **no presentada**, nunca como fallada
- [X] T043 [P] Crear `test/engine/lesson_session_test.dart` incluyendo el abandono a mitad de lección

### Contenido de inglés A1

- [X] T044 [P] Crear `lib/content/en/a1_module1_identity.dart`: módulo `A1M1`, `order: 1`, "Identidad y saludos", con `canDo`, 12 ítems de vocabulario, gramática de `to be` y pronombres, 5 ejemplos bilingües, lectura "A new neighbour", y lecciones con opción múltiple, construir frases, huecos, **al menos un ejercicio de escucha y uno de pronunciación**. Fuente: `Study/ruta-de-ingles.html`
- [X] T045 [P] Crear `lib/content/en/a1_module2_home_city.dart`: módulo `A1M2`, `order: 2`, "Mi casa y mi ciudad", mismos mínimos
- [X] T046 [P] Crear `lib/content/en/a1_module3_routines.dart`: módulo `A1M3`, `order: 3`, "Rutinas y horarios", mismos mínimos
- [X] T047 [P] Crear `lib/content/en/a1_module4_likes.dart`: módulo `A1M4`, `order: 4`, "Gustos y capacidades", mismos mínimos
- [X] T048 Si cualquier archivo de T044 a T047 supera 300 líneas, dividirlo por tipo de material en `a1_moduleN_vocabulary.dart`, `a1_moduleN_grammar.dart` y `a1_moduleN_exercises.dart`, dejando corto el archivo que ensambla (Principio II; regla en `contracts/content-pack.md`)
- [X] T049 [P] Crear `lib/content/en/a1_level_exam.dart` con el examen de nivel de A1: mínimo 10 ejercicios, umbral 0.80
- [X] T050 [P] Crear `lib/content/en/placement_test_en.dart` donde **cada ejercicio declara el nivel MCER que discrimina**, cubriendo A1 a C1. Puede incluir niveles sin contenido: la prueba estima el nivel real de la persona, no el nivel al que la app puede llevarla
- [X] T051 Crear `lib/content/en/english_course.dart` que implemente `ContentPack` con `levels: [A1]` y `upcomingLevelIds: ['A2', 'B1', 'B2', 'C1', 'C2']` (depende de T044 a T050)
- [X] T052 Crear `lib/content/catalog.dart` con la lista de paquetes disponibles. Es el **único** archivo que importa contenido concreto, y solo `main.dart` lo importa a él
- [X] T053 Crear `test/content/en/a1_integrity_test.dart` verificando las **22 invariantes** de `contracts/content-pack.md`: ids únicos, `order` consecutivo, mínimos de vocabulario y ejercicios, `canDo` no vacío, `explanation` no vacía en todo ejercicio, al menos un ejercicio de escucha y uno de pronunciación por módulo, alternativa accesible declarada en todos los orales, `answerIndex` en rango, y `upcomingLevelIds` posteriores a `levels` y sin intersección

### Armazón de la app

- [X] T054 [P] Crear `lib/app/theme.dart` con `ColorScheme.fromSeed` en modo claro y oscuro, contraste de texto conforme a WCAG AA y objetivos táctiles mínimos de 48 dp
- [X] T055 [P] Crear `lib/app/l10n/app_es.arb` con las cadenas de interfaz en español, **separadas del contenido didáctico** (Principio I)
- [X] T056 Crear `lib/app/app.dart` con el `MaterialApp`, el tema de T054 y la localización de T055
- [X] T057 Crear `lib/main.dart` que inicialice Firebase con `firebase_options.dart`, construya el catálogo de T052, inyecte las implementaciones concretas de los servicios y lance `runApp`
- [X] T058 [P] Crear `lib/services/settings/settings_store.dart` con `themeMode`, `speechRate` y `lastCourseId`, local y **no sincronizado**

**Checkpoint**: contratos, almacén, contenido y armazón listos. `flutter analyze` y
`flutter test` en verde. Las historias pueden empezar.

---

## Phase 3: User Story 1 - Cuenta, sesión y recuperación en otro dispositivo (Priority: P1)

**Goal**: la persona crea su cuenta, entra, y su progreso la sigue a cualquier dispositivo.

**Independent Test**: crear cuenta, registrar actividad, entrar con la misma cuenta en un
segundo destino y comprobar que el estado coincide sin recargar.

### Tests for User Story 1 ⚠️

> Escribir estas pruebas **antes** de la implementación y comprobar que fallan.

- [X] T059 [P] [US1] Crear `test/fakes/fake_auth_service.dart` capaz de devolver **cada uno** de los 8 errores tipados de `contracts/services.md`
- [X] T060 [P] [US1] Crear `test/fakes/fake_sync_service.dart` capaz de simular fallo de red, documento remoto ausente y emisiones de `remoteChanges`
- [X] T061 [P] [US1] Crear `test/engine/progress_merger_test.dart` verificando **conmutatividad**, **asociatividad** e **idempotencia** sobre permutaciones de estados divergentes, y la invariante central: *ningún número del resultado es menor ni ningún conjunto más pequeño que en cualquiera de las entradas*
- [X] T062 [P] [US1] Añadir a `test/engine/progress_merger_test.dart` el caso de la **racha caducada**: racha 7 con última actividad el lunes fusionada con racha 1 del jueves debe dar racha 1, no 7

### Implementation for User Story 1

- [X] T063 [US1] Crear `lib/engine/progress_merger.dart` con la fusión monotónica de `data-model.md`: máximo para puntajes, XP y estados de nivel; unión para conjuntos; `intervalStep` máximo y `dueDate` **más próxima** por tarjeta; `placement` el de `takenAt` más reciente
- [X] T064 [US1] Añadir a `lib/engine/progress_merger.dart` la fusión de la racha **junto a su fecha**, como máximo lexicográfico del par `(lastActivityDate, streakCount)`: gana el dispositivo que estudió más recientemente, así que una racha caducada no revive (FR-032). Sustituye al «recálculo tras fusionar» del plan original, que no conserva la asociatividad
- [X] T065 [P] [US1] Crear `lib/services/auth/auth_service.dart` con el contrato: `currentUser`, `authStateChanges`, `signUp`, `signIn`, `sendPasswordReset`, `signOut`, y el enum de errores tipados `invalidEmail`, `weakPassword`, `emailAlreadyInUse`, `wrongCredentials`, `userNotFound`, `tooManyAttempts`, `noConnection`, `unknown`
- [X] T066 [US1] Crear `lib/services/auth/firebase_auth_service.dart` que traduzca **toda** excepción de Firebase a un error tipado. Ninguna excepción cruda cruza el contrato
- [X] T067 [P] [US1] Crear `lib/services/sync/sync_service.dart` con el contrato: `pull`, `pushMerged`, `remoteChanges` y `syncStatus`. **No** expone ninguna operación de reemplazo directo
- [X] T068 [US1] Crear `lib/services/sync/firestore_sync_service.dart` con `pushMerged` dentro de una **transacción** de Firestore que lea el documento remoto, lo fusione con `progress_merger` y escriba el resultado (depende de T063, T067)
- [X] T069 [US1] Desactivar la persistencia local de Firestore en la inicialización de `lib/main.dart`, para no tener dos cachés compitiendo con Drift
- [X] T070 [US1] Implementar `remoteChanges` en `lib/services/sync/firestore_sync_service.dart` como suscripción en vivo al documento; cada emisión se fusiona con la **misma** `progress_merger` y se escribe en Drift. Es lo que hace cumplible SC-004 sin recargar
- [X] T071 [US1] Crear `lib/services/sync/sync_scheduler.dart` que empuje al iniciar sesión, al terminar lección o examen, al terminar repaso, al recuperar conexión y al pasar a segundo plano, sin bloquear nunca la interfaz
- [X] T072 [P] [US1] Crear `lib/ui/providers/auth_providers.dart` exponiendo el estado de sesión
- [X] T073 [P] [US1] Crear `lib/ui/providers/progress_providers.dart` exponiendo progreso y estado de sincronización
- [X] T074 [P] [US1] Crear `lib/ui/screens/sign_up_screen.dart` con correo y contraseña **únicamente**; sin nombre, fecha de nacimiento, teléfono ni ubicación (FR-006)
- [X] T075 [P] [US1] Crear `lib/ui/screens/sign_in_screen.dart` que conserve lo escrito al fallar y ofrezca reintentar
- [X] T076 [P] [US1] Crear `lib/ui/screens/password_reset_screen.dart`
- [X] T077 [US1] Crear `lib/app/auth_gate.dart` que decida entre flujo de acceso y de estudio según `authStateChanges`
- [X] T078 [P] [US1] Crear `lib/ui/widgets/sync_banner.dart` que muestre cambios pendientes y el último error de sincronización
- [X] T079 [P] [US1] Crear `lib/ui/widgets/offline_notice.dart` que avise cuando el almacenamiento esté degradado o falte conexión en el primer arranque
- [X] T080 [US1] Añadir al cierre de sesión la advertencia de qué progreso quedaría sin respaldar y la confirmación explícita (FR-005)
- [X] T081 [P] [US1] Crear `test/ui/screens/sign_in_screen_test.dart` y `test/ui/screens/sign_up_screen_test.dart` cubriendo los 8 errores tipados, incluido `noConnection` del primer arranque
- [X] T082 [P] [US1] Crear `test/services/sync/firestore_sync_service_test.dart` verificando que `pushMerged` nunca sobrescribe y que una emisión ya fusionada no tiene efecto
- [X] T083 [US1] Verificar `firestore.rules` con el emulador de Firestore: una sesión autenticada **no** puede leer el documento de otro `uid`, y una petición sin sesión es rechazada

**Checkpoint**: cuenta funcional y progreso sincronizado entre dos destinos sin recargar.

---

## Phase 4: User Story 2 - Completar una lección y conservar el progreso (Priority: P1)

**Goal**: la persona completa una lección y su resultado sobrevive al cierre de la app.

**Independent Test**: completar una lección, cerrar la app por completo, reabrir y comprobar
que sigue aprobada con el mismo XP.

### Tests for User Story 2 ⚠️

- [X] T084 [P] [US2] Crear `test/engine/xp_calculator_test.dart`

### Implementation for User Story 2

- [X] T085 [US2] Crear `lib/engine/xp_calculator.dart` con el XP por actividad completada
- [X] T086 [P] [US2] Crear `lib/ui/providers/content_providers.dart` que exponga el curso activo **a través del contrato**, sin importar `lib/content/` desde `ui`
- [X] T087 [P] [US2] Crear `lib/ui/widgets/vocabulary_card.dart` con término, traducción y ayuda visual
- [X] T088 [P] [US2] Crear `lib/ui/widgets/grammar_panel.dart` que renderice la explicación en español, incluidas tablas de conjugación, legible a 360 dp
- [X] T089 [P] [US2] Crear `lib/ui/widgets/bilingual_example_tile.dart`
- [X] T090 [P] [US2] Crear `lib/ui/widgets/reading_passage.dart` con el texto del pasaje
- [X] T091 [P] [US2] Crear `lib/ui/widgets/multiple_choice_question.dart`
- [X] T092 [P] [US2] Crear `lib/ui/widgets/sentence_builder.dart` que arme la frase a partir de fichas
- [X] T093 [P] [US2] Crear `lib/ui/widgets/gap_fill_field.dart` que califique con `answer_matcher`
- [X] T094 [P] [US2] Crear `lib/ui/widgets/feedback_panel.dart` que muestre **por qué** la respuesta correcta lo es, no solo cuál era (FR-025)
- [X] T095 [US2] Crear `lib/ui/screens/lesson_screen.dart` que recorra vocabulario, gramática, ejemplos, lectura y ejercicios, y presente el resultado con su XP
- [X] T096 [US2] Escribir el resultado de la lección en **una sola transacción** que toque `activity_results`, `student_profile` y `review_cards`: un corte no puede dejar XP sumado sin lección aprobada
- [X] T097 [US2] Conservar únicamente el **mejor** puntaje por actividad, de modo que un reintento peor no pueda desaprobar lo ya aprobado (FR-027)
- [X] T098 [P] [US2] Crear `test/ui/screens/lesson_screen_test.dart` cubriendo aprobado con 70 %, suspendido con 69 % y abandono a mitad
- [X] T099 [P] [US2] Crear pruebas de widget en `test/ui/widgets/` para `sentence_builder`, `gap_fill_field` y `feedback_panel`

**Checkpoint**: una lección completa y calificable, con su progreso persistido.

---

## Phase 5: User Story 3 - Avanzar por los módulos y superar el nivel (Priority: P1)

**Goal**: módulos que se desbloquean en orden y un examen de nivel que decide el paso.

**Independent Test**: recorrer A1 de principio a fin verificando que las puertas de módulo y
de nivel se abren y cierran según el umbral del 80 %.

### Tests for User Story 3 ⚠️

- [X] T100 [P] [US3] Crear `test/engine/progression_test.dart` recorriendo la **matriz completa** de transiciones de `LevelState` y rechazando toda transición descendente, además de verificar que ningún nivel de `upcomingLevelIds` puede alcanzar `unlocked` por ninguna vía

### Implementation for User Story 3

- [X] T101 [US3] Crear `lib/engine/progression.dart` con el desbloqueo de módulo y de nivel, y las cinco transiciones válidas de `data-model.md`. Los niveles sin contenido **no tienen estado**: no son `Level` y no aparecen en `levelStates`
- [X] T102 [P] [US3] Crear `lib/ui/widgets/level_card.dart`
- [X] T103 [P] [US3] Crear `lib/ui/widgets/module_tile.dart`
- [X] T104 [P] [US3] Crear `lib/ui/widgets/locked_notice.dart` que explique **qué falta** para desbloquear, no solo que está bloqueado
- [X] T105 [P] [US3] Crear `lib/ui/widgets/upcoming_level_notice.dart` que dibuje los niveles de `upcomingLevelIds` como "próximo · en preparación", **sin ruta de entrada** (FR-038)
- [X] T106 [US3] Crear `lib/ui/screens/level_map_screen.dart` con los niveles con contenido y los anunciados (depende de T102, T105)
- [X] T107 [US3] Crear `lib/ui/screens/module_screen.dart` con el objetivo "puedo hacer X" visible antes de empezar (FR-011)
- [X] T108 [US3] Crear `lib/ui/screens/exam_screen.dart` para exámenes de módulo y de nivel, con umbral 0.80
- [X] T109 [US3] Al aprobar el examen de nivel, desbloquear el siguiente nivel **con contenido** si existe, en la misma transacción
- [X] T110 [P] [US3] Crear `test/ui/screens/level_map_screen_test.dart` verificando que un nivel anunciado no abre nada al tocarlo
- [X] T111 [P] [US3] Crear `test/ui/screens/module_screen_test.dart` y `test/ui/screens/exam_screen_test.dart`

**Checkpoint**: la ruta de A1 es recorrible de principio a fin con sus puertas funcionando.

---

## Phase 6: User Story 4 - Escuchar y pronunciar en inglés (Priority: P2)

**Goal**: las cuatro destrezas, con alternativa accesible que permite aprobar sin micrófono.

**Independent Test**: reproducir audio de un módulo, calificar una frase dicha, y recorrer la
ruta alternativa con el micrófono denegado.

### Tests for User Story 4 ⚠️

- [X] T112 [P] [US4] Crear `test/fakes/fake_tts_service.dart` capaz de devolver cada valor de `TtsAvailability`: `available`, `languageMissing`, `engineMissing`, `unsupportedPlatform`
- [X] T113 [P] [US4] Crear `test/fakes/fake_stt_service.dart` capaz de devolver cada valor de `SttAvailability` y cada variante de `SttOutcome`. La ruta alternativa es un requisito verificable, no un caso excepcional
- [X] T114 [P] [US4] Crear `test/engine/pronunciation_matcher_test.dart` con diferencias de mayúsculas, puntuación, espacios y palabras sobrantes

### Implementation for User Story 4

- [X] T115 [US4] Crear `lib/engine/pronunciation_matcher.dart` que compare el texto reconocido con la frase objetivo normalizando a minúsculas, quitando puntuación y colapsando espacios. **No** puntúa acento ni entonación
- [X] T116 [P] [US4] Crear `lib/services/speech/tts_service.dart` con el contrato `initialize`, `speak`, `stop`, `setRate` y el enum `TtsAvailability`
- [X] T117 [US4] Crear `lib/services/speech/flutter_tts_service.dart` cuyo `initialize` consulte `getLanguages` y **no asuma** que existe la voz en inglés; `speak` es no-op silencioso si no está disponible
- [X] T118 [P] [US4] Crear `lib/services/speech/stt_service.dart` con el contrato `checkAvailability`, `requestPermission`, `listenOnce`, `cancel`, y los tipos `SttAvailability` y `SttOutcome`
- [X] T119 [P] [US4] Crear `lib/services/speech/speech_availability.dart` que resuelva qué ruta usar antes de pedir permisos
- [X] T120 [US4] Crear `lib/services/speech/speech_to_text_service.dart` con la **degradación en tres pasos**: `SpeechListenOptions(onDevice: true)` primero; si la sesión falla y hay red, el reconocedor del sistema; si no hay ninguno, `failedUseAlternative`. El paso 3 no es un error
- [X] T121 [P] [US4] Crear `lib/ui/providers/speech_providers.dart`
- [X] T122 [P] [US4] Crear `lib/ui/widgets/accessible_alternative.dart` reutilizable por los dos tipos de ejercicio oral
- [X] T123 [US4] Crear `lib/ui/widgets/listening_exercise.dart` con audio repetible y `transcriptFallback` cuando no haya voz disponible
- [X] T124 [US4] Crear `lib/ui/widgets/pronunciation_exercise.dart` que muestre **qué se entendió y qué se esperaba** al fallar, y permita reintentar (FR-017)
- [X] T125 [US4] Pedir el permiso de micrófono **solo** cuando la persona vaya a usarlo, explicando antes para qué sirve; nunca al arrancar la app (FR-018)
- [X] T126 [US4] Garantizar que `failedUseAlternative` y `noSpeechDetected` **no** cuentan como respuesta incorrecta, y que tras varios intentos se puede continuar (FR-020)
- [X] T127 [US4] Añadir el botón de escucha a `vocabulary_card.dart` y `bilingual_example_tile.dart`
- [X] T128 [P] [US4] Crear `test/ui/widgets/pronunciation_exercise_test.dart` verificando que la lección **se aprueba** con el micrófono denegado usando la alternativa
- [X] T129 [P] [US4] Crear `test/ui/widgets/listening_exercise_test.dart` con `languageMissing`, comprobando que se presenta el transcript y no un control de audio mudo

**Checkpoint**: las cuatro destrezas operativas, aprobables sin micrófono y sin altavoz.

---

## Phase 7: User Story 5 - Repasar vocabulario con repetición espaciada (Priority: P2)

**Goal**: el vocabulario visto vuelve con intervalos crecientes.

**Independent Test**: completar una lección para sembrar la cola, repasar, y verificar que la
próxima fecha cambia según la calificación.

### Tests for User Story 5 ⚠️

- [X] T130 [P] [US5] Crear `test/engine/srs_scheduler_test.dart` usando el reloj inyectado para recorrer 90 días: avance de intervalo, salto doble al recordar con facilidad, reinicio a 1 día al fallar, y tope en el último intervalo

### Implementation for User Story 5

- [X] T131 [US5] Crear `lib/engine/srs_scheduler.dart` con `IV = [1,3,7,16,35,90]`: recordada con esfuerzo `step+1`; con facilidad `step+2` con tope en 5; no recordada `step = 0`, `due = hoy + 1`, `lapses++`
- [X] T132 [US5] Sembrar la cola de repaso con el vocabulario del módulo al empezarlo (FR-028)
- [X] T133 [P] [US5] Crear `lib/ui/providers/review_providers.dart` con el conteo de vencidas hoy
- [X] T134 [US5] Crear `lib/ui/screens/review_screen.dart` con la sesión de repaso y sus tres calificaciones
- [X] T135 [US5] Mostrar en la pantalla principal cuántas palabras vencen hoy, e indicar **explícitamente** cuando no hay ninguna, en lugar de abrir una sesión vacía (FR-030)
- [X] T136 [P] [US5] Crear `test/ui/screens/review_screen_test.dart` incluyendo el estado "al día"

**Checkpoint**: la cola de repaso funciona y se consolida el vocabulario.

---

## Phase 8: User Story 6 - Ubicarse con la nivelación y saltar lo dominado (Priority: P2)

**Goal**: quien ya sabe inglés no repite lo que domina.

**Independent Test**: presentar la prueba con distintos patrones y verificar nivel estimado,
nivel asignado, niveles marcados como dominados y su accesibilidad para repaso.

### Tests for User Story 6 ⚠️

- [X] T137 [P] [US6] Crear `test/engine/placement_evaluator_test.dart` verificando que el **nivel estimado** puede ser cualquier nivel MCER, que el **asignado** se limita al nivel con contenido más alto que no lo supere, y que los niveles con contenido por debajo del estimado quedan `mastered`

### Implementation for User Story 6

- [X] T138 [US6] Crear `lib/engine/placement_evaluator.dart` que calcule el nivel estimado a partir de los niveles que discrimina cada ejercicio, y **derive** el asignado contra el catálogo vigente. El asignado no se almacena como verdad independiente
- [X] T139 [US6] Crear `lib/ui/screens/placement_screen.dart` que permita **omitir** la prueba para empezar en A1 (FR-034)
- [X] T140 [US6] Informar el nivel estimado real al terminar, sin rebajarlo ni ocultarlo, y explicar la diferencia cuando supere al asignado (FR-035, FR-036)
- [X] T141 [US6] Marcar como `mastered` los niveles con contenido por debajo del estimado, dejarlos abiertos para repaso, y garantizar que repasarlos **no** altera la marca ni el nivel estimado (FR-037)
- [X] T142 [US6] Ofrecer repasar lo dominado cuando no quede contenido nuevo, en lugar de dejar una pantalla vacía (FR-038)
- [X] T143 [US6] No volver a ofrecer la nivelación de forma intrusiva a quien ya tiene progreso
- [X] T144 [P] [US6] Crear `test/ui/screens/placement_screen_test.dart` incluyendo omitir la prueba y el caso de estimado por encima del contenido disponible

**Checkpoint**: la nivelación ubica correctamente y nunca deja a nadie sin nada que hacer.

---

## Phase 9: User Story 7 - Racha diaria y progreso acumulado (Priority: P3)

**Goal**: el motor de hábito y la señal de avance.

**Independent Test**: registrar actividad en días distintos y verificar el contador de racha y
el porcentaje de avance.

### Tests for User Story 7 ⚠️

- [X] T145 [P] [US7] Crear `test/engine/streak_tracker_test.dart` con el reloj inyectado: primera actividad da 1, día consecutivo da N+1, dos días sin actividad reinicia a 1, dos lecciones el mismo día **no** incrementan dos veces, y cambio de mes

### Implementation for User Story 7

- [X] T146 [US7] Crear `lib/engine/streak_tracker.dart` con el incremento diario único, el reinicio por día perdido y la **fusión del par `(fecha, racha)`** que consume `progress_merger` (T064). Enmendado respecto al plan original: el «recálculo tras fusión» rompe la asociatividad, y el contraejemplo queda escrito en el archivo y verificado en su prueba
- [X] T147 [P] [US7] Crear `lib/ui/widgets/streak_badge.dart`
- [X] T148 [P] [US7] Crear `lib/ui/widgets/xp_badge.dart`
- [X] T149 [P] [US7] Crear `lib/ui/widgets/progress_ring.dart`
- [X] T150 [US7] Crear `lib/ui/screens/progress_screen.dart` con el porcentaje del nivel aprobado, los módulos superados y el tamaño de la cola de repaso (FR-033)
- [X] T151 [P] [US7] Crear `test/ui/screens/progress_screen_test.dart`

**Checkpoint**: todas las historias de usuario operativas.

---

## Phase 10: Respaldo y ajustes (Cross-Cutting)

**Purpose**: FR-045 y FR-046, obligación del Principio IV de la constitución.

> **Nota de trazabilidad**: estos dos requisitos **no pertenecen a ninguna historia de
> usuario** de `spec.md`. Se implementan aquí como funcionalidad transversal. Conviene
> decidir si merecen su propia historia.

- [X] T152 [P] Crear `lib/services/backup/backup_document.dart` con `backupVersion`, `appVersion`, `courseId`, `exportedAt` y `progress`, serializado con **la misma forma** que el documento remoto
- [X] T153 [P] Crear `lib/services/backup/backup_service.dart` con el contrato `export`, `serialize`, `parse`, `import`, `wipe`, y el tipo `BackupParseResult` con `valid`, `unsupportedVersion`, `malformed` y `wrongCourse`
- [X] T154 Crear `lib/services/backup/json_backup_service.dart` cuyo `import` **fusiona** con `progress_merger`, nunca reemplaza: un respaldo viejo no puede hacer retroceder a quien ya avanzó más
- [X] T155 Validar el archivo **antes** de aplicar nada: una versión no soportada o un archivo corrupto se rechazan con mensaje claro y **sin tocar** el progreso existente
- [X] T156 [P] Crear `lib/ui/providers/backup_providers.dart`
- [X] T157 [P] Crear `lib/ui/widgets/destructive_confirm_dialog.dart` que advierta que la operación es irreversible y mencione el respaldo como única vuelta atrás
- [X] T158 Crear `lib/ui/screens/settings_screen.dart` con tema, velocidad de voz, y las tres acciones de respaldo —exportar, importar, borrar— con la destructiva visualmente diferenciada
- [X] T159 [P] Crear `test/services/backup/json_backup_service_test.dart` con ida y vuelta, versión no soportada, archivo corrupto, y el caso clave: **importar un respaldo viejo no pierde el progreso posterior**
- [X] T160 [P] Crear `test/ui/screens/settings_screen_test.dart` verificando que borrar exige confirmación explícita

---

## Phase 11: Verificación integral y despliegue

**Purpose**: demostrar los 12 criterios de éxito. Nada se publica antes de esta fase.

- [X] T161 Ejecutar `flutter analyze` y confirmar cero errores y cero advertencias nuevas
- [X] T162 Ejecutar `flutter test` y confirmar la suite completa en verde
- [ ] T163 **SC-001** · Cronometrar en emulador limpio: crear cuenta y llegar al primer ejercicio en menos de 3 minutos
- [ ] T164 **SC-002** · Aprobar una lección, cerrar la app, `adb reboot`, reabrir y comparar XP, racha y lecciones aprobadas
- [ ] T165 **SC-003** · Recorrer una lección completa en modo avión, **incluido el audio**, tras haber iniciado sesión una vez. Ninguna pantalla en blanco ni espera indefinida
- [ ] T166 **SC-004** · Dos destinos abiertos en primer plano con la misma cuenta: aprobar una lección en el emulador y comprobar que aparece en Chrome en menos de 30 s **sin recargar ni reiniciar**
- [ ] T167 **SC-005** · Avanzar **distinto** en los dos destinos en modo avión, restaurar la conexión en ambos y verificar que se conserva lo mejor de cada uno
- [ ] T168 **SC-006** · Cronometrar cada lección de A1 y confirmar que cae entre 5 y 10 minutos
- [X] T169 **SC-007** · Responder mal a propósito en cada tipo de ejercicio y comprobar que la explicación dice por qué
- [ ] T170 **SC-008** · Revocar el permiso de micrófono y silenciar el dispositivo; recorrer y **aprobar** una lección completa con las alternativas accesibles
- [X] T171 **SC-009** · Intentar todas las rutas de acceso a un nivel bloqueado y a un nivel anunciado; ninguna debe abrir
- [ ] T172 **SC-010** · `adb shell wm size 360x800` y `font_scale 1.3`; recorrer **todas** las pantallas con atención a la gramática larga y las tablas; restaurar al terminar
- [X] T173 **SC-011** · Crear un curso de prueba de un módulo, registrarlo, comprobar que es recorrible, y verificar con `git status --short lib/core lib/engine lib/services lib/ui` que la salida está **vacía**; descartar el curso al terminar
- [X] T174 **SC-012** · Cubierto por `streak_tracker_test.dart`; confirmar que la prueba recorre la semana completa con el reloj inyectado
- [ ] T175 **FR-047 a FR-049** · Activar TalkBack y recorrer una lección **solo escuchando**; verificar etiquetas semánticas en todo control, objetivos táctiles de 48 dp y contraste WCAG AA en claro **y** oscuro
- [X] T176 **FR-045 y FR-046** · Exportar, seguir avanzando, importar el respaldo viejo y confirmar que no se pierde nada; importar un archivo corrupto; borrar con confirmación
- [ ] T177 Verificar persistencia en navegador: aprobar una lección, recargar con F5 y comprobar que el progreso sigue. Confirma que `sqlite3.wasm` y `drift_worker.js` están bien instalados
- [X] T178 Ejecutar `flutter build web --release` y `firebase deploy --only hosting`
- [ ] T179 Añadir el dominio personalizado `languages.buildlark.com` en la consola de Firebase Hosting y configurar los registros DNS que entregue
- [ ] T180 Verificar la app publicada en `languages.buildlark.com`: registro, lección completa y persistencia tras recargar

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: sin dependencias
- **Phase 2 Foundational**: depende de Phase 1 — **bloquea todas las historias**
- **Phase 3 a 9 (historias)**: dependen de Phase 2
- **Phase 10 Respaldo**: depende de T063 (`progress_merger`), porque importar fusiona
- **Phase 11 Verificación**: depende de **todo** lo anterior

### Dependencias entre historias

- **US1** (P1) · independiente tras Phase 2. Aporta `progress_merger`, del que dependen Phase 10 y US7
- **US2** (P1) · independiente tras Phase 2
- **US3** (P1) · independiente; consume el contenido de Phase 2
- **US4** (P2) · independiente; añade los botones de escucha a widgets de US2 (T127)
- **US5** (P2) · necesita vocabulario visto, que siembra US2
- **US6** (P2) · independiente; determina el estado inicial de la ruta de US3
- **US7** (P3) · consume la fusión de racha de US1 (T064)

### Dentro de cada historia

Las pruebas se escriben **antes** y deben fallar. Después: `core` → `engine` → `services` →
`ui`, nunca al revés. El Principio II lo verifica T026.

### Parallel Opportunities

- T003, T004, T007, T008, T009 en Phase 1
- T011 a T023 en Phase 2: trece archivos de `core` sin dependencias entre sí
- T044 a T047: los cuatro módulos de contenido, en paralelo
- T059, T060, T061, T062: dobles y pruebas de fusión
- T087 a T094: ocho widgets de contenido, en paralelo
- T147, T148, T149: las tres insignias de progreso

---

## Parallel Example: Phase 2, contratos de `core`

```bash
Task: "Crear lib/core/clock.dart con el tipo Clock"
Task: "Crear lib/core/thresholds.dart con 0.70, 0.80 y los intervalos"
Task: "Crear lib/core/level_state.dart con el enum de valor entero explícito"
Task: "Crear lib/core/vocabulary_item.dart"
Task: "Crear lib/core/exercise.dart con las 5 variantes"
```

## Parallel Example: Phase 2, contenido de A1

```bash
Task: "Crear lib/content/en/a1_module1_identity.dart"
Task: "Crear lib/content/en/a1_module2_home_city.dart"
Task: "Crear lib/content/en/a1_module3_routines.dart"
Task: "Crear lib/content/en/a1_module4_likes.dart"
```

---

## Implementation Strategy

### Entrega única, sin publicación parcial

Decisión explícita del responsable del proyecto: no se publica nada a medias, hay paciencia
para construir la funcionalidad completa.

1. Phase 1 y 2 completas — cimientos, almacén y contenido
2. Phase 3 a 9 — las siete historias
3. Phase 10 — respaldo y ajustes
4. Phase 11 — los 12 criterios de éxito verificados y el despliegue

Los *checkpoints* al final de cada fase sirven para **verificar y corregir temprano**, no para
publicar. Detenerse en uno es válido para revisar; desplegar desde uno, no.

### Orden recomendado si hay una sola persona

El del documento. Phase 2 es la más larga y la más aburrida, y es también la que decide si el
resto sale bien: `core` mal modelado se paga en las siete historias.

### Si hay varias personas

Tras Phase 2, las historias se reparten. US1 conviene que la tome quien vaya a sostener la
sincronización, porque `progress_merger` lo consumen Phase 10 y US7.

---

## Notes

- **180 tareas.** Las pruebas no son opcionales: el Principio V las exige y las fases no se
  cierran sin ellas
- `[P]` significa archivos distintos sin dependencias pendientes
- Commit por tarea o por grupo lógico, y explicación en español de cada entrega (Principio VI)
- **FR-045 y FR-046 no tienen historia de usuario** en `spec.md`; se implementan en Phase 10
  como transversal. Vale decidir si merecen una historia propia
- De la deuda reconocida en `plan.md` sigue vigente una sola cosa: el reconocimiento de habla
  sin conexión es mejor esfuerzo. El identificador de la app ya es `com.buildlark.languages`
  ([issue #1](https://github.com/buildlark-dev/languages_app/issues/1), cerrado)

---

## Phase 12: Convergence

Hallazgos de `/speckit-converge` del 8 de octubre de 2026. Todos son **piezas
sin cablear**, no piezas sin construir: los servicios, los contratos y sus
pruebas existen y funcionan: lo que falta es que alguien los llame. Es el patrón
que deja una suite en verde con la app incumpliendo el requisito.

- [X] T181 Llamar a `SpeechAvailabilityController.prepare(course.studyLanguageTag)` al abrir un curso. Hoy `prepare()` no tiene ni una llamada en `lib/`, así que la disponibilidad se queda en `none()`, `ListenButton` no se dibuja en ninguna parte y todo ejercicio de escucha y de pronunciación cae a su alternativa escrita: la app no reproduce audio nunca per FR-014, FR-015, FR-016 (missing) — **CRITICAL**
- [X] T182 Ofrecer la nivelación **al elegir el idioma**, no detrás. `PlacementOfferCard` solo se dibuja con un curso ya seleccionado, y `_openCourse` selecciona y navega en el mismo toque, así que quien entra por primera vez no la ve a menos que retroceda per FR-034 (missing)
- [X] T183 Traer el progreso remoto al iniciar sesión y adoptarlo, con `SyncService.pull` o un `pushMerged` inicial. Hoy `pull()` no tiene ninguna llamada, así que una instalación nueva que inicia sesión muestra el progreso vacío hasta que una actividad dispara la fusión per FR-040, FR-041, US1 (missing)
- [X] T184 Suscribirse a `SyncService.remoteChanges` mientras la app está en primer plano y encaminar cada emisión por `SyncScheduler.applyRemote`. Ninguno de los dos tiene llamadas, así que el criterio «aparece en el otro dispositivo en menos de 30 s sin recargar» no tiene mecanismo que lo cumpla per SC-004 (missing)
- [X] T185 Impedir que guardar el progreso revierta la cola de repaso. `ProgressDao.save` reescribe `progress.reviewCards` desde la instantánea cargada al arrancar, así que calificar una tarjeta por `ReviewDao` y terminar después cualquier lección devuelve esa tarjeta a su intervalo anterior. Decidir una sola fuente de verdad para la cola y añadir una prueba con la base real que califique, guarde el progreso y compruebe que el intervalo sobrevive per FR-029, FR-042 (contradicts)
- [X] T186 Disparar los `SyncTrigger` que faltan: `signIn` al entrar, `connectivityRestored` al recuperar la red y `appBackgrounded` al pasar a segundo plano. Hoy solo se dispara `activityFinished`, así que un empujón que falla sin red no se reintenta hasta la siguiente actividad per FR-041 (partial)

---

## Phase 13: Convergence

Segunda pasada de `/speckit-converge`, 8 de octubre de 2026. Los seis hallazgos
de la Fase 12 están cerrados. Queda uno, y es **una regresión que introdujo
T183**: justamente por eso se vuelve a pasar converge después de implementar.

- [X] T187 Hacer que borrar el progreso permanezca. Hoy se deshace solo: la invalidación reconstruye el progreso, `_syncOnEntry` pide la sincronización de entrada y `pushMerged` lo fusiona con el documento de la nube, que sigue entero. Comprobado con una sonda sobre los proveedores reales: 777 XP, `null` en disco justo tras borrar, y 777 XP de nuevo dos turnos después, con la pantalla ya diciendo «Tu progreso de este idioma se borró». Decidir primero el alcance —si el borrado es solo de este dispositivo o también de la nube—, porque de eso depende el arreglo y también el texto, que hoy promete algo que no pasa. Añadir una prueba que borre, deje correr la sincronización y compruebe que el progreso sigue vacío per FR-046 (contradicts)

---

## Phase 14: Convergence

Tercera pasada, 8 de octubre de 2026. T187 cerró el borrado que se deshacía
solo en el propio dispositivo. Queda el alcance que su texto declara, que la
arquitectura no sostiene.

- [X] T188 Resolver el alcance real del borrado. El diálogo dice «En este dispositivo, en los demás y en la nube», y eso no se cumple: comprobado con una sonda de dos dispositivos sobre una nube compartida —A borra, la nube queda vacía, B sincroniza y la nube vuelve a tener los 777 XP—. La causa es de fondo: la fusión monotónica no puede distinguir «esto se borró» de «esto le falta al otro dispositivo», así que cualquier copia local sobreviviente restaura lo borrado, y basta con que la otra app se abra. Dos salidas, y la elección es de producto: **(a)** ajustar el texto a lo que ocurre —este dispositivo y la nube, advirtiendo que otro dispositivo abierto puede volver a subir lo suyo—, que es un cambio de minutos y deja de mentir; o **(b)** añadir una marca de borrado con fecha al documento remoto que los demás dispositivos respeten vaciándose, lo que cumple la promesa pero introduce la primera operación no monotónica del modelo y obliga a revisar las tres propiedades de la fusión. Recomendada la (a) mientras la app sea de un solo usuario sin soporte: prometer menos y cumplirlo es mejor que un mecanismo de reinicio que puede borrar de más. Añadir en cualquier caso una prueba de dos dispositivos que fije el comportamiento elegido per FR-046 (contradicts)

---

## Phase 15: Convergence

Cuarta pasada, 8 de octubre de 2026. T188 cerrado. Los dos hallazgos que quedan
son del almacén de preferencias, y comparten causa: es el **único** de los ocho
contratos de servicio cuyo proveedor no lanza al no sobrescribirse, así que su
ausencia nunca se hizo notar.

- [X] T189 Dar a `SettingsStore` una implementación que persista y cablearla en `main.dart`. Hoy la única que existe es `InMemorySettingsStore`, documentada como «la que usan las pruebas», y `settingsStoreProvider` no se sobrescribe: el tema y la velocidad de voz se reinician en cada arranque, así que elegir modo oscuro no sirve de nada más allá de la sesión. Hacer además que el proveedor lance si falta, como los otros ocho, que es justo lo que habría destapado esto antes. El almacenamiento puede ser una tabla de drift —coherente con la decisión de plan.md de no usar `shared_preferences`, aunque aquel rechazo era por el progreso y no por las preferencias— o la dependencia nueva, si se prefiere no versionar un esquema por dos ajustes; decidirlo al implementar. Añadir prueba de ida y vuelta per FR-048, plan: preferencias del dispositivo (partial)
- [X] T190 Resolver `lastCourseId`. El contrato lo declara «para volver a él al abrir la app» y no hay ni una lectura ni una escritura en todo `lib/`. Con un solo idioma no se nota, con tres sí. Decidir entre escribirlo al elegir curso y leerlo al arrancar, o retirarlo del contrato: una capacidad declarada que nadie usa es una promesa que alguien dará por cierta per `settings_store.dart` (missing)
