# Implementation Plan: Núcleo del curso de inglés A1

**Branch**: `001-english-a1-core` | **Date**: 2026-10-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-english-a1-core/spec.md`

## Summary

Entregar el nivel A1 de inglés completo y usable de una sola vez: cuenta de usuario con
sincronización en la nube, motor de aprendizaje agnóstico del idioma, cuatro módulos de
contenido en inglés, las cuatro destrezas (incluida pronunciación con micrófono y su
alternativa accesible obligatoria), repetición espaciada, XP y racha, y nivelación con
salto de niveles. El responsable del proyecto descartó explícitamente una entrega
incremental: no hay orden de rescate por fases, el diseño se hace para el conjunto.

Los niveles sin contenido construido (A2 en adelante) existen únicamente como aviso de
interfaz, por decisión del responsable del proyecto: se anuncian como "próximo · en
preparación" y no son accesibles por ninguna ruta.

El eje técnico son tres decisiones, detalladas en [research.md](./research.md):

1. **El almacén local es la fuente de verdad** (Drift), y la nube sincroniza mediante una
   **fusión monotónica** (máximos y uniones). La resolución por *última escritura gana* de
   Firestore borraría progreso en silencio, lo que FR-042 prohíbe.
2. **La alternativa accesible de los ejercicios orales es también la ruta sin conexión**.
   El reconocimiento de habla en el dispositivo no se puede garantizar, así que la
   degradación en tres pasos termina siempre en un camino completable sin red.
3. **El contenido es código Dart tipado**, no assets. Un módulo mal formado no compila, en
   lugar de fallar en el teléfono del estudiante.

## Technical Context

**Language/Version**: Dart 3.12.2 · Flutter 3.44.2 (stable), ambos verificados en la
máquina de desarrollo.

**Primary Dependencies**: `flutter_riverpod` ^3.4.3 (estado e inyección) · `drift`
^2.35.1 con `drift_flutter` ^0.3.1 (almacén local versionado) · `firebase_core` ^4.15.0,
`firebase_auth` ^6.7.0, `cloud_firestore` ^6.10.0 (cuenta y sincronización) ·
`flutter_tts` ^4.2.5 (voz sin conexión) · `speech_to_text` ^7.5.0 (pronunciación) ·
`flutter_localizations` + `intl` (interfaz en español). Desarrollo: `drift_dev`,
`build_runner`.

**Storage**: SQLite local vía Drift como fuente de verdad, con esquema versionado (v1) y
migraciones obligatorias. Cloud Firestore como destino de sincronización, con su
persistencia local **desactivada** para no tener dos cachés en competencia. El contenido
didáctico no se almacena: es código compilado.

**Testing**: `flutter_test` para unitarias y de widget, con dobles escritos a mano de los
contratos de servicio y base Drift en memoria. Reloj inyectado para poder recorrer noventa
días de repetición espaciada en milisegundos. Verificación manual en emulador Pixel 7.

**Target Platform**: Android (primaria, verificación visual en emulador Pixel 7) y Web
(primaria, despliegue en Firebase Hosting hacia `languages.buildlark.com`). iOS, Windows,
macOS y Linux se mantienen compilables sin verificación visual.

**Project Type**: Aplicación móvil y web de un solo paquete Flutter, con separación
interna en capas (`core`, `engine`, `services`, `content`, `ui`).

**Performance Goals**: sincronización reflejada en el segundo dispositivo en menos de 30 s
(SC-004) es el único objetivo exigido por la especificación. Los demás son **metas internas
de ingeniería**, no criterios de aceptación, y no bloquean la entrega: 60 fps en el recorrido
de lecciones en un Pixel 7 emulado · arranque hasta pantalla utilizable en menos de 2 s con
sesión ya iniciada · consulta de la cola de repaso en menos de 50 ms con 2.000 tarjetas (es
lo que justifica el índice `idx_review_due`).

**Constraints**: funcionamiento sin conexión tras el primer inicio de sesión (FR-039) ·
audio disponible sin conexión (FR-014) · ninguna pérdida de progreso en ninguna
permutación de sincronización (FR-042, SC-005) · toda pantalla usable desde 360 dp con
fuente del sistema al 130 % (SC-010) · todo ejercicio oral aprobable con micrófono
denegado y sonido apagado (SC-008) · ningún archivo de producción por encima de ~300
líneas (Principio II).

**Scale/Scope**: 1 curso (inglés), 1 nivel (A1), 4 módulos, ~48 ítems de vocabulario,
~12 pantallas, ~20 widgets de contenido, 5 tipos de ejercicio. Volumen esperado de datos
por estudiante: decenas de filas de progreso y unos cientos de tarjetas de repaso.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principio | Puerta | Estado tras diseño | Cómo se sostiene |
|---|---|---|---|
| **I. Contenido desacoplado del motor** | El motor no importa contenido; añadir un idioma no toca el motor | ✅ PASA | `lib/engine/` y `lib/ui/` dependen solo de los contratos de `lib/core/`. El único archivo que importa `lib/content/catalog.dart` es `lib/main.dart`, la raíz de composición. SC-011 lo verifica añadiendo un curso de prueba |
| **II. Un archivo, una responsabilidad** | Ningún archivo de producción > ~300 líneas; dependencias en un sentido | ✅ PASA | Árbol de 80 archivos con una responsabilidad cada uno; cada módulo de A1 en su propio archivo. El sentido `ui → engine → core ← content` se verifica con una prueba que inspecciona los `import` |
| **III. Rigor pedagógico verificable** | Niveles MCER, objetivos "puedo hacer X", cuatro destrezas, umbrales 70/80 | ✅ PASA | Umbrales centralizados en `core/thresholds.dart`; las cuatro destrezas cubiertas por los cinco tipos de ejercicio; contenido derivado de `Study/ruta-de-ingles.html` |
| **IV. El progreso del estudiante es sagrado** | Offline, escritura atómica, esquema versionado con migración, **respaldo exportable e importable**, sin fallo silencioso | ✅ PASA | Drift con esquema v1 y política de migración escrita; fusión monotónica que no puede perder avance; `services/backup/` con exportación, importación que fusiona y borrado confirmado; `sync_banner` y `offline_notice` hacen visible cualquier degradación |
| **V. Sin prueba no está terminado** | `analyze` limpio, unitarias del motor, widget por pantalla, emulador | ✅ PASA | Cada archivo de `engine/` tiene su espejo en `test/engine/`; cada pantalla su prueba de widget; quickstart documenta la verificación manual en emulador |
| **VI. Código didáctico y socializado** | Explicación en español de cada entrega; código en inglés | ✅ PASA | Compromiso de ejecución, no de estructura. Las decisiones no triviales quedan en `research.md` |
| **VII. Móvil primero y accesible** | 360 dp, 48 dp táctil, WCAG AA, etiquetas semánticas, audio no obligatorio, claro y oscuro | ✅ PASA | `app/theme.dart` con `ColorScheme` claro y oscuro; alternativa accesible como campo obligatorio del contrato de ejercicio oral, no como añadido opcional |

### Puertas con observación

**Principio VII, el audio no puede ser requisito.** Esta es la puerta que más fácilmente se
incumpliría en la implementación. Para que no dependa de la disciplina, la alternativa
accesible es un **campo obligatorio del tipo de ejercicio oral** en `core/exercise.dart`:
un ejercicio de escucha o pronunciación sin alternativa declarada **no compila**. SC-008
lo verifica a nivel de comportamiento.

**Principio IV, migraciones.** El esquema v1 nace con la tabla de versión y una prueba de
migración que corre desde v1 hacia sí misma, de modo que la infraestructura de migración
exista y esté probada *antes* de que haya una v2 que la necesite.

**Principio II, la capa que la constitución no nombra.** El principio fija
`ui → engine → core` y `content → core`, pero no ubica `services`. Este plan declara la regla
que falta (ver Structure Decision) para que la prueba de arquitectura pueda aplicarla. No es
un incumplimiento, sino un hueco del enunciado: conviene enmendar el Principio II para
incorporarla.

## Project Structure

### Documentation (this feature)

```text
specs/001-english-a1-core/
├── spec.md              # Especificación (/speckit-specify)
├── plan.md              # Este archivo (/speckit-plan)
├── research.md          # Fase 0: 12 decisiones técnicas con alternativas
├── data-model.md        # Fase 1: entidades, esquema v1, reglas de fusión
├── quickstart.md        # Fase 1: cómo ejecutar y validar los 12 criterios de éxito
├── contracts/           # Fase 1
│   ├── content-pack.md  #   qué debe exponer un paquete de idioma
│   ├── services.md      #   auth, sync, voz: contratos y degradación
│   ├── local-schema.md  #   esquema Drift v1 y política de migración
│   └── firestore.md     #   forma del documento, fusión y reglas de seguridad
├── checklists/
│   └── requirements.md  # Validación de la especificación (15/15)
└── tasks.md             # Fase 2 (/speckit-tasks — NO lo crea /speckit-plan)
```

### Source Code (repository root)

```text
lib/
├── main.dart                          # raíz de composición: Firebase, catálogo, runApp
├── firebase_options.dart              # generado por flutterfire configure; versionado
├── app/
│   ├── app.dart                       # MaterialApp, tema, localización
│   ├── theme.dart                     # ColorScheme claro y oscuro, tokens
│   ├── auth_gate.dart                 # decide entre flujo de acceso y de estudio
│   └── l10n/                          # cadenas de interfaz en español (ARB)
├── core/                              # contratos y modelos puros: sin Flutter, sin Firebase
│   ├── clock.dart                     # reloj inyectado (testabilidad de fechas)
│   ├── thresholds.dart                # 70 %, 80 %, intervalos 1·3·7·16·35·90
│   ├── course.dart
│   ├── level.dart
│   ├── level_state.dart               # bloqueado · desbloqueado · superado · dominado
│   ├── module.dart
│   ├── lesson.dart
│   ├── vocabulary_item.dart
│   ├── exercise.dart                  # 5 tipos; alternativa accesible obligatoria en los orales
│   ├── exam.dart
│   ├── review_card.dart
│   ├── student_progress.dart
│   ├── placement_result.dart
│   ├── sync_state.dart
│   └── content_pack.dart              # contrato que todo idioma debe implementar
├── engine/                            # lógica de aprendizaje: no conoce ningún idioma
│   ├── scoring.dart                   # calificación de lección y examen
│   ├── progression.dart               # desbloqueo de módulo y de nivel
│   ├── srs_scheduler.dart             # programación de la cola de repaso
│   ├── streak_tracker.dart            # racha diaria
│   ├── xp_calculator.dart
│   ├── placement_evaluator.dart       # nivel asignado y marcado de dominados
│   ├── answer_matcher.dart            # variantes, mayúsculas, espacios
│   ├── pronunciation_matcher.dart     # comparación normalizada con la frase objetivo
│   ├── lesson_session.dart            # estado de una lección en curso
│   └── progress_merger.dart           # fusión monotónica (FR-042)
├── services/
│   ├── db/
│   │   ├── app_database.dart          # Drift: declaración y versión del esquema
│   │   ├── tables.dart
│   │   ├── migrations.dart
│   │   ├── progress_dao.dart
│   │   └── review_dao.dart
│   ├── auth/
│   │   ├── auth_service.dart          # contrato
│   │   └── firebase_auth_service.dart
│   ├── sync/
│   │   ├── sync_service.dart          # contrato
│   │   ├── firestore_sync_service.dart# transacción leer-fusionar-escribir
│   │   └── sync_scheduler.dart        # reintento al recuperar conexión
│   ├── speech/
│   │   ├── tts_service.dart           # contrato
│   │   ├── flutter_tts_service.dart
│   │   ├── stt_service.dart           # contrato
│   │   ├── speech_to_text_service.dart# degradación en tres pasos
│   │   └── speech_availability.dart   # qué hay y qué no, para decidir la ruta
│   ├── backup/
│   │   ├── backup_service.dart        # contrato
│   │   ├── json_backup_service.dart   # exportar, importar (fusionando), borrar
│   │   └── backup_document.dart       # formato con versión
│   └── settings/
│       └── settings_store.dart        # tema, velocidad de voz
├── content/
│   ├── catalog.dart                   # registro de cursos; solo main.dart lo importa
│   └── en/
│       ├── english_course.dart
│       ├── level_a1.dart
│       ├── a1_module1_identity.dart
│       ├── a1_module2_home_city.dart
│       ├── a1_module3_routines.dart
│       ├── a1_module4_likes.dart
│       ├── a1_level_exam.dart
│       └── placement_test_en.dart
└── ui/
    ├── providers/                     # Riverpod: única costura entre ui y las capas bajas
    │   ├── auth_providers.dart
    │   ├── progress_providers.dart
    │   ├── content_providers.dart
    │   ├── review_providers.dart
    │   ├── speech_providers.dart
    │   ├── backup_providers.dart
    │   └── settings_providers.dart
    ├── screens/
    │   ├── sign_in_screen.dart
    │   ├── sign_up_screen.dart
    │   ├── password_reset_screen.dart
    │   ├── course_catalog_screen.dart
    │   ├── placement_screen.dart
    │   ├── level_map_screen.dart
    │   ├── module_screen.dart
    │   ├── lesson_screen.dart
    │   ├── exam_screen.dart
    │   ├── review_screen.dart
    │   ├── progress_screen.dart
    │   └── settings_screen.dart
    └── widgets/
        ├── vocabulary_card.dart
        ├── grammar_panel.dart
        ├── bilingual_example_tile.dart
        ├── reading_passage.dart
        ├── multiple_choice_question.dart
        ├── sentence_builder.dart
        ├── gap_fill_field.dart
        ├── listening_exercise.dart
        ├── pronunciation_exercise.dart
        ├── accessible_alternative.dart
        ├── feedback_panel.dart
        ├── level_card.dart
        ├── module_tile.dart
        ├── locked_notice.dart
        ├── upcoming_level_notice.dart
        ├── destructive_confirm_dialog.dart
        ├── streak_badge.dart
        ├── xp_badge.dart
        ├── progress_ring.dart
        ├── sync_banner.dart
        └── offline_notice.dart

test/
├── core/
│   └── thresholds_test.dart
├── engine/                            # espejo exacto de lib/engine/
│   ├── scoring_test.dart
│   ├── progression_test.dart
│   ├── srs_scheduler_test.dart
│   ├── streak_tracker_test.dart
│   ├── xp_calculator_test.dart
│   ├── placement_evaluator_test.dart
│   ├── answer_matcher_test.dart
│   ├── pronunciation_matcher_test.dart
│   ├── lesson_session_test.dart
│   └── progress_merger_test.dart      # incluye permutaciones de sincronización
├── services/
│   ├── db/
│   │   ├── app_database_test.dart
│   │   ├── migrations_test.dart
│   │   └── review_dao_test.dart
│   ├── sync/
│   │   └── firestore_sync_service_test.dart
│   └── backup/
│       └── json_backup_service_test.dart   # ida y vuelta, versión y archivo corrupto
├── content/
│   └── en/
│       └── a1_integrity_test.dart     # todo módulo completo y bien formado
├── ui/
│   ├── screens/                       # una prueba de widget por pantalla
│   └── widgets/
├── architecture/
│   └── layer_dependencies_test.dart   # verifica el sentido de los imports
└── fakes/                             # dobles escritos a mano de los contratos

firebase.json                          # Hosting: build/web con reescritura SPA
firestore.rules                        # cada persona solo accede a su progreso
l10n.yaml                              # configuración de generación de cadenas ARB
web/                                   # + sqlite3.wasm y drift_worker.js (Drift en web)
android/app/google-services.json       # configuración pública de cliente; versionada
```

**Structure Decision**: un solo paquete Flutter con cinco capas internas, porque la
funcionalidad es una app cliente sin backend propio: Firebase cubre autenticación y
sincronización, así que no hay nada que separar en un proyecto aparte. Las capas son
`core` (contratos y modelos puros, sin un solo import de Flutter), `engine` (toda la
lógica de aprendizaje, agnóstica del idioma y de la plataforma), `services`
(implementaciones de infraestructura detrás de contratos), `content` (datos didácticos por
idioma) y `ui` (pantallas y widgets). El sentido de las dependencias,
`ui → engine → core ← content` con `services` implementando contratos de `core`, no es una
convención escrita: `test/architecture/layer_dependencies_test.dart` lo comprueba
inspeccionando los `import` de cada archivo, de modo que una violación rompe la suite.

**Dónde encaja `services`, que la constitución no especifica.** El Principio II fija
`ui → engine → core` y `content → core`, pero no ubica la capa de infraestructura. La regla
que adopta este plan, y que la prueba de arquitectura aplica:

```
ui  →  engine  →  core
ui  →  services →  engine  →  core
content →  core
```

Es decir, `services` implementa contratos de `core`, puede usar `engine` (el servicio de
sincronización llama a `progress_merger`), y **nunca** importa `ui` ni `content`. Sin esta
declaración la prueba de arquitectura no tendría regla que aplicar a un tercio del código.
Queda pendiente enmendar el Principio II para incorporarla; mientras eso no ocurra, el plan
es la fuente de la regla.

La costura entre `ui` y el resto son los proveedores de `ui/providers/`, y la costura entre
la app y el contenido concreto es `lib/main.dart`. Ese es el mecanismo por el que añadir
francés y portugués no toca el motor: un paquete de contenido nuevo se registra en el
catálogo, y nada más cambia.

## Orden de construcción

No es una entrega por fases —el responsable del proyecto pidió el conjunto completo— sino
el orden de dependencia técnica con el que `/speckit-tasks` debe descomponer el trabajo:

1. **Cimientos**: `core/` (contratos, umbrales, reloj) y la prueba de arquitectura. Nada
   más puede escribirse con sentido antes.
2. **Motor con sus pruebas**: `engine/` completo. Se puede desarrollar y probar sin
   interfaz, sin Firebase y sin contenido real.
3. **Almacén local**: esquema Drift v1, DAOs, migración y sus pruebas.
4. **Contenido de A1**: los cuatro módulos, el examen de nivel y la prueba de nivelación,
   con la prueba de integridad del contenido.
5. **Infraestructura**: Firebase (proyecto, Auth, Firestore, reglas), servicios de voz con
   su degradación.
6. **Sincronización**: fusión monotónica contra Firestore, con pruebas de permutación.
7. **Interfaz**: tema, proveedores, pantallas y widgets, con prueba de widget por pantalla.
8. **Verificación integral**: emulador Pixel 7, modo avión, micrófono denegado, 360 dp con
   fuente al 130 %, dos dispositivos con progreso divergente, y despliegue web.

## Complexity Tracking

La constitución pide preferir la biblioteca estándar de Flutter y justificar cada paquete
nuevo. Siete dependencias entran, y estas son las que requieren justificación explícita:

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `flutter_riverpod` en lugar de estado estándar | Seis ámbitos de estado compartido (sesión, progreso, cola de repaso, sincronización, lección en curso, tema) consumidos por doce pantallas; el motor debe ser probable sin `BuildContext` | `ChangeNotifier` + `InheritedNotifier` obliga a escribir a mano la inyección y la sustitución para pruebas, y acopla la lectura de estado al árbol de widgets. Sería reimplementar peor lo que ya existe |
| `drift` en lugar de `shared_preferences` | El Principio IV exige esquema versionado con migración, y la cola de repaso necesita consultar por fecha de vencimiento sin cargarla completa | `shared_preferences` no tiene esquema, migraciones ni consultas: FR-044 sería inimplementable y la cola obligaría a deserializar todo en cada arranque |
| Tres paquetes de Firebase | FR-001 a FR-005 exigen cuenta con restablecimiento de contraseña; FR-041 y FR-042 exigen sincronización entre dispositivos | Un backend propio obligaría a custodiar contraseñas y a construir infraestructura que Firebase ya da, en un proyecto que además ya despliega en Firebase Hosting |
| `cloud_firestore` **sin** su persistencia offline, más `progress_merger` propio | Su resolución por última escritura gana borraría progreso en silencio, lo que FR-042 prohíbe y SC-005 detectaría | Usar su caché como almacén único es más simple en código pero incorrecto en comportamiento: perder el avance de un estudiante no es un caso borde aceptable |
| `flutter_tts` + `speech_to_text`, con tres rutas de degradación | Decisión explícita del responsable del proyecto: las cuatro destrezas en A1 desde el día uno | Omitir las destrezas orales fue ofrecido y rechazado. Un modelo whisper en el dispositivo daría reconocimiento offline garantizado, pero con decenas o cientos de MB de modelo y sin soporte en web |

### Deuda reconocida, no oculta

- **El reconocimiento de habla sin conexión no está garantizado** (D6 de research.md). Se
  cumple FR-039 porque la alternativa accesible siempre permite completar la lección, pero
  quien esté sin red puede no poder practicar pronunciación por voz. Si las pruebas reales
  muestran que ocurre a menudo, la vía es `whisper_edge`, evaluada y aplazada, no
  descartada.
- **`com.example.languages_app` sigue siendo el identificador de la app**
  ([issue #1](https://github.com/buildlark-dev/languages_app/issues/1)). No bloquea esta
  funcionalidad ni el despliegue web, pero sí un release en Google Play.
- ~~El `.gitignore` excluye `google-services.json`~~ — **resuelto el 2026-10-06**: se
  eliminaron las líneas `google-services.json` y `GoogleService-Info.plist`. D12 de
  research.md explica por qué esa precaución estaba mal dirigida. Siguen ignorados los
  secretos reales (`*-service-account*.json`, `.env`).
- **La racha fusionada necesita recálculo, no solo máximo.** Es una excepción deliberada a la
  pureza de la fusión monotónica, documentada en data-model.md y en
  contracts/firestore.md. El coste es un paso extra en `streak_tracker`; el beneficio es no
  incumplir FR-031 de forma visible para el estudiante.
