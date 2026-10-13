# Phase 1 — Data Model: Núcleo del curso de inglés A1

**Feature**: `001-english-a1-core` | **Date**: 2026-10-06

## Glosario

Tres términos que este documento introduce y que la especificación no usa. Se definen aquí
para que no haya deriva de vocabulario entre documentos:

| Término | Significado |
|---|---|
| **Actividad** | Cualquier cosa calificable: una lección, un examen de módulo o un examen de nivel. Existe porque los tres se guardan en la misma tabla con la misma regla de "mejor puntaje" |
| **Nivel estimado** | Lo que la nivelación calcula. Puede ser cualquier nivel MCER, incluso uno sin contenido |
| **Nivel asignado** | Dónde la persona estudia de verdad: el nivel con contenido más alto que no supera al estimado |

---

Dos familias de datos con ciclos de vida distintos:

- **Contenido** (inmutable, compilado): curso, nivel, módulo, lección, vocabulario,
  ejercicio, examen. Vive en `lib/content/<idioma>/` como objetos `const`. No se guarda ni
  se sincroniza nunca.
- **Progreso** (mutable, por estudiante): estado de nivel, resultados, tarjetas de repaso,
  XP, racha, nivelación. Vive en SQLite local y se sincroniza con Firestore.

La frontera importa: el contenido puede cambiar con una nueva versión de la app sin migrar
nada, y el progreso puede migrar sin tocar el contenido.

---

## 1. Entidades de contenido

### Course

| Campo | Tipo | Reglas |
|---|---|---|
| `id` | `String` | Único en el catálogo. Código ISO del idioma: `en`, `fr`, `pt` |
| `name` | `String` | Nombre en español. Ej.: "Inglés" |
| `studyLanguageTag` | `String` | Etiqueta BCP 47 para la voz. Ej.: `en-US` |
| `supportLanguageTag` | `String` | Idioma de apoyo. `es` en esta entrega |
| `levels` | `List<Level>` | Niveles **con contenido**. Orden MCER ascendente, sin huecos |
| `upcomingLevelIds` | `List<String>` | Niveles anunciados pero sin contenido. Solo aviso de interfaz |
| `placementTest` | `Exam?` | Opcional: un curso puede no tener nivelación |

**Validación**: `levels` no vacío; los `id` de nivel pertenecen al conjunto MCER y
aparecen en orden; ningún `id` de módulo repetido en todo el curso; `upcomingLevelIds` son
MCER válidos, posteriores al último de `levels` y sin intersección con él.

**Por qué `upcomingLevelIds` y no niveles vacíos** (FR-038): un `Level` sin módulos
violaría las invariantes del paquete de contenido, que exigen módulos con vocabulario,
lectura y examen. Declararlos como simples identificadores los mantiene fuera del modelo de
contenido, y la interfaz los dibuja como tarjetas "próximo · en preparación" sin ruta de
entrada. En esta entrega, el curso de inglés declara `levels: [A1]` y
`upcomingLevelIds: [A2, B1, B2, C1, C2]`.

### Level

| Campo | Tipo | Reglas |
|---|---|---|
| `id` | `String` | Uno de `A1`, `A2`, `B1`, `B2`, `C1`, `C2` |
| `name` | `String` | Ej.: "A1 · Fundamentos" |
| `description` | `String` | En español, qué habilita el nivel |
| `modules` | `List<Module>` | Orden ascendente por `order`, sin huecos |
| `levelExam` | `Exam` | Obligatorio: es la puerta al nivel siguiente |

### Module

| Campo | Tipo | Reglas |
|---|---|---|
| `id` | `String` | Ej.: `A1M1`. Único en el curso |
| `order` | `int` | Desde 1, consecutivo dentro del nivel |
| `title` | `String` | En español |
| `canDo` | `String` | Objetivo "puedo hacer X" (FR-011). No vacío |
| `vocabulary` | `List<VocabularyItem>` | Mínimo 8 ítems |
| `grammar` | `GrammarExplanation` | Explicación en español |
| `examples` | `List<BilingualExample>` | Mínimo 3 |
| `reading` | `ReadingPassage` | **Solo el texto.** Sus preguntas van como ejercicios de lección |
| `lessons` | `List<Lesson>` | Mínimo 1 |
| `moduleExam` | `Exam` | Obligatorio |

**Validación de integridad** (`test/content/en/a1_integrity_test.dart`): todo módulo
cumple los mínimos anteriores **y** contiene al menos un ejercicio de escucha y al menos
uno de pronunciación (FR-015, FR-016). Un módulo sin destrezas orales hace fallar la suite.

### Lesson

| Campo | Tipo | Reglas |
|---|---|---|
| `id` | `String` | Único en el curso |
| `title` | `String` | En español |
| `readingRef` | `String?` | Id del pasaje que la lección usa como apoyo, si aplica |
| `exercises` | `List<Exercise>` | Mínimo 5, para que el umbral del 70 % sea significativo |

**Qué se puntúa y qué no** (FR-013): la lección es **la única unidad calificable**. Las
preguntas de comprensión de la lectura son `Exercise` dentro de `exercises`, así que
cuentan para el umbral del 70 %. El vocabulario, la explicación gramatical y los ejemplos
bilingües son material de estudio y no se puntúan: se consultan, no se responden.

Esto resuelve una ambigüedad del diseño inicial, donde las preguntas de la lectura colgaban
del módulo y por tanto habrían quedado fuera de toda calificación.

### VocabularyItem

| Campo | Tipo | Reglas |
|---|---|---|
| `term` | `String` | En el idioma estudiado |
| `translation` | `String` | En español |
| `hint` | `String?` | Ayuda visual opcional (emoji) |
| `spokenForm` | `String?` | Texto a pronunciar si difiere de `term` |

La clave de una tarjeta de repaso es `moduleId` + `term`, lo que mantiene estable la
identidad aunque cambien la traducción o la ayuda.

### Exercise

Tipo suma con cinco variantes. El campo que vuelve estructural el Principio VII:

| Variante | Campos propios | Alternativa accesible |
|---|---|---|
| `MultipleChoiceExercise` | `prompt`, `options`, `answerIndex`, `explanation` | no aplica |
| `SentenceBuilderExercise` | `targetSentence`, `tokens`, `explanation` | no aplica |
| `GapFillExercise` | `sentenceWithGap`, `acceptedAnswers` (lista), `explanation` | no aplica |
| `ListeningExercise` | `spokenText`, `question`, `options`, `answerIndex`, `explanation` | **`transcriptFallback` obligatorio** |
| `PronunciationExercise` | `targetPhrase`, `translation`, `explanation` | **`writtenFallback` obligatorio** |

**Regla de diseño**: en las dos variantes orales el campo de alternativa es un parámetro
`required` del constructor. Un ejercicio oral sin alternativa **no compila**, de modo que
SC-008 no depende de que alguien se acuerde de añadirla.

`explanation` es obligatorio en las cinco variantes y debe decir *por qué* la respuesta
correcta lo es (FR-025), no solo cuál es.

### Exam

| Campo | Tipo | Reglas |
|---|---|---|
| `id` | `String` | Único en el curso |
| `scope` | `ExamScope` | `module`, `level` o `placement` |
| `exercises` | `List<Exercise>` | Mínimo 10 |
| `passThreshold` | `double` | Siempre `0.80` desde `core/thresholds.dart` |

En un examen de nivelación cada ejercicio lleva además el nivel MCER que discrimina, para
que `placement_evaluator` pueda asignar nivel.

---

## 2. Entidades de progreso

### StudentProgress (agregado raíz)

| Campo | Tipo | Regla de fusión |
|---|---|---|
| `uid` | `String` | clave, no se fusiona |
| `courseId` | `String` | clave, no se fusiona |
| `schemaVersion` | `int` | el mayor |
| `currentLevelId` | `String` | el nivel más avanzado |
| `xp` | `int` | **máximo** |
| `streakCount` | `int` | **par** `(lastActivityDate, streakCount)` (ver abajo) |
| `lastActivityDate` | `DateTime` | la más reciente |
| `levelStates` | `Map<String, LevelState>` | el estado más avanzado por nivel |
| `lessonResults` | `Map<String, double>` | **máximo** por lección |
| `examResults` | `Map<String, double>` | **máximo** por examen |
| `placement` | `PlacementResult?` | el no nulo; si ambos, el más reciente |
| `syncState` | `SyncState` | local, nunca se sincroniza |

### LevelState

Enumeración con **orden total de avance**, lo que permite fusionar tomando el máximo:

```
locked (0) < unlocked (1) < mastered (2) < passed (3)
```

- `locked`: el requisito previo no está cumplido.
- `unlocked`: accesible y en curso.
- `mastered`: marcado como dominado por la nivelación (FR-037). Abierto para repaso; el
  repaso **no** lo degrada ni lo asciende.
- `passed`: examen de nivel aprobado con ≥ 80 %.

**Transiciones válidas**

| Desde | Hacia | Disparador |
|---|---|---|
| `locked` | `unlocked` | el nivel anterior pasa a `passed` (FR-024) |
| `locked` | `mastered` | el nivel está por debajo del estimado por la nivelación (FR-037) |
| `locked` | `unlocked` | el nivel es el asignado por la nivelación (FR-036) |
| `unlocked` | `passed` | examen de nivel ≥ 80 % |
| `mastered` | `passed` | la persona repasa y aprueba el examen de nivel |

Prohibidas: cualquier transición descendente. `progression.dart` las rechaza y
`progression_test.dart` lo verifica con la matriz completa.

**Los niveles sin contenido no tienen estado** (FR-038). No son `Level`, así que no aparecen
en `levelStates` ni pueden alcanzar `unlocked` por ninguna vía. La interfaz los dibuja desde
`Course.upcomingLevelIds` como tarjetas "próximo · en preparación", sin ruta de entrada. Esa
es la razón estructural por la que no existe un camino para estudiar un nivel inexistente:
no hay dato que pudiera representarlo.

### ReviewCard

| Campo | Tipo | Regla de fusión |
|---|---|---|
| `moduleId` + `term` | `String` | clave compuesta |
| `translation` | `String` | el valor del contenido actual |
| `intervalStep` | `int` | **máximo** (índice en `[1,3,7,16,35,90]`) |
| `dueDate` | `DateTime` | **la más próxima** |
| `lapses` | `int` | máximo |

**Por qué la fecha más próxima y no la más lejana**: ante la duda, se repasa antes. Repasar
una palabra de más es un costo de treinta segundos; no repasar una que se estaba olvidando
es perder el aprendizaje.

**Programación** (`srs_scheduler.dart`): con `IV = [1, 3, 7, 16, 35, 90]`

- recordada con esfuerzo: `step = min(step + 1, 5)`, `due = hoy + IV[step]`
- recordada con facilidad: `step = min(step + 2, 5)`, `due = hoy + IV[step]`
- no recordada: `step = 0`, `due = hoy + 1`, `lapses++`

### PlacementResult

| Campo | Tipo | Nota |
|---|---|---|
| `estimatedLevelId` | `String` | Cualquier nivel MCER, incluso sin contenido (FR-035) |
| `assignedLevelId` | `String` | Derivado: el nivel con contenido más alto ≤ estimado (FR-036) |
| `masteredLevelIds` | `List<String>` | Niveles **con contenido** por debajo del estimado |
| `skipped` | `bool` | true si omitió la prueba |
| `takenAt` | `DateTime` | |

**La distinción entre estimado y asignado es lo que hace honesta la nivelación.** Si alguien
da B1 en la prueba, se le dice "tu nivel estimado es B1" —eso es información verdadera y
útil— pero el nivel donde puede estudiar se limita a lo que existe. En esta entrega
`assignedLevelId` siempre es `A1`, y `estimatedLevelId` puede ser cualquiera.

`assignedLevelId` es **derivado, no almacenado como verdad independiente**: se recalcula
contra el catálogo vigente. Cuando se construya A2, quien tenga `estimatedLevelId: B1`
pasará a tener `assignedLevelId: A2` sin ninguna migración de datos.

### BackupDocument

Entidad de transporte, no de almacenamiento: existe solo mientras se exporta o se importa
(FR-045). Detalle del formato en [contracts/services.md](./contracts/services.md#backupservice).

| Campo | Tipo | Nota |
|---|---|---|
| `backupVersion` | `int` | versión del formato de respaldo |
| `appVersion` | `String` | versión de la app que lo generó, para diagnóstico |
| `courseId` | `String` | un respaldo pertenece a un curso |
| `exportedAt` | `DateTime` | |
| `progress` | `StudentProgress` | la instantánea completa |

`progress` se serializa con **la misma forma que el documento remoto**, de modo que no hay
dos serializaciones que mantener sincronizadas. Al importar se **fusiona**, nunca se
reemplaza, así que un respaldo viejo no puede hacer retroceder a quien ya avanzó más.

### SyncState

| Campo | Tipo | Nota |
|---|---|---|
| `lastSyncedAt` | `DateTime?` | null si nunca sincronizó |
| `hasPendingChanges` | `bool` | alimenta `sync_banner` |
| `lastError` | `String?` | visible para FR-043 |
| `storageDegraded` | `bool` | true si se cayó a memoria |

Nunca se sincroniza: describe la relación de *este* dispositivo con la nube.

---

## 3. Esquema local v1

Seis tablas. Detalle completo y política de migración en
[contracts/local-schema.md](./contracts/local-schema.md).

| Tabla | Para qué | Clave |
|---|---|---|
| `schema_meta` | versión del esquema (FR-044) | fila única |
| `student_profile` | uid, curso activo, XP, racha, última actividad | `uid` + `course_id` |
| `level_progress` | estado de cada nivel | `uid` + `course_id` + `level_id` |
| `activity_results` | mejor puntaje de lección y examen | `uid` + `course_id` + `activity_id` |
| `review_cards` | cola de repetición espaciada | `uid` + `course_id` + `module_id` + `term` |
| `placement_results` | resultado de nivelación | `uid` + `course_id` |
| `sync_meta` | estado de sincronización local | `uid` |

**Índices**: `review_cards(uid, course_id, due_date)` es el que sostiene la meta de 50 ms
con 2.000 tarjetas; sin él, "qué vence hoy" degrada a recorrido completo.

**Regla de escritura**: aprobar una lección toca `activity_results`, `student_profile` y
puede tocar `level_progress`. Las tres escrituras van en **una transacción**: un corte de
energía no puede dejar XP sumado sin la lección aprobada.

---

## 4. La fusión, con precisión

Esta es la pieza de la que depende FR-042 y SC-005.

Toda regla de fusión de la tabla de `StudentProgress` es un **máximo** sobre un orden
total, o una **unión** de conjuntos. Eso convierte el progreso en un *join-semilattice*, y
de ahí se siguen tres propiedades que las pruebas verifican directamente:

| Propiedad | Qué significa | Consecuencia práctica |
|---|---|---|
| Conmutativa | `merge(a,b) == merge(b,a)` | da igual qué dispositivo sincronice primero |
| Asociativa | `merge(merge(a,b),c) == merge(a,merge(b,c))` | tres o más dispositivos convergen igual |
| Idempotente | `merge(a,a) == a` | sincronizar dos veces no altera nada |

`test/engine/progress_merger_test.dart` genera permutaciones de estados de progreso y
comprueba las tres, más la invariante que de verdad importa:

> **Ningún valor numérico del resultado es menor que el mismo valor en cualquiera de las
> entradas, y ningún conjunto del resultado es más pequeño.**

Es decir: fusionar **nunca** puede quitarle avance a nadie. Esa es la propiedad que hace
que no haga falta confiar en el código, porque está comprobada.

**El caso de la racha, y por qué el máximo solo no basta**: fusionar por máximo tiene un
efecto perverso. Imagina racha 7 en el teléfono con última actividad el lunes, y racha 1 en
el PC con última actividad el jueves. El máximo daría racha 7 con última actividad el
jueves: una racha de siete días que en realidad se rompió el martes. FR-031 exige que una
racha caducada se reinicie, así que el máximo a secas **violaría FR-031 de forma
observable**.

**Corrección aplicada durante la implementación**: el primer diseño decía «fusionar por
máximo y después recalcular». Al escribir el código resultó que eso **rompe la
asociatividad**, porque el recálculo necesitaría saber a qué fecha pertenecía la racha más
alta, y ese dato ya se perdió al fusionar.

La regla correcta es tratar la racha y su fecha como **una sola unidad**: gana la del
dispositivo que estudió más recientemente y, en empate de fecha, la racha mayor.

| Entradas | Resultado |
|---|---|
| racha 7 del lunes · racha 1 del jueves | **racha 1**, jueves (la del lunes caducó) |
| racha 7 del lunes · racha 3 del lunes | racha 7 (empate de fecha, gana la mayor) |
| racha 7 del lunes · racha 8 del martes | racha 8, martes |
| racha 5 del lunes · sin actividad | racha 5, lunes |

Eso sigue siendo un máximo, ahora sobre el orden lexicográfico
`(lastActivityDate, streakCount)`, así que **conserva las tres propiedades** y a la vez
respeta FR-032: una racha caducada no revive. Sigue favoreciendo al estudiante en el único
caso donde hay duda legítima, que es cuando ambos dispositivos se usaron el mismo día.

`progress_merger_test.dart` cubre los cuatro casos de la tabla y verifica las tres
propiedades sobre todas las permutaciones de cinco estados de ejemplo.

**Lo que no se fusiona**: `syncState` es estado local del dispositivo. El contenido no se
fusiona porque no se guarda.

---

## 5. Documento remoto

Un documento por estudiante y curso, en `users/{uid}/courses/{courseId}`. Forma exacta y
reglas de seguridad en [contracts/firestore.md](./contracts/firestore.md).

La escritura **siempre** ocurre dentro de una transacción de Firestore que lee el documento
remoto, lo fusiona con el local usando `progress_merger` y escribe el resultado. Nunca hay
un `set` directo que pueda sobrescribir. La persistencia offline de Firestore queda
desactivada para que no exista una segunda caché compitiendo con Drift.
