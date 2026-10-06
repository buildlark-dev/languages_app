# Contract — Servicios de infraestructura

**Feature**: `001-english-a1-core` | **Date**: 2026-10-06

Cada servicio se declara como contrato en `lib/services/<area>/<area>_service.dart` y se
implementa aparte. El motor y la interfaz dependen del contrato; la implementación concreta
se inyecta en `lib/main.dart`. Eso permite que las pruebas usen dobles escritos a mano sin
Firebase, sin micrófono y sin red.

---

## AuthService

**Requisitos que cubre**: FR-001 a FR-005.

| Operación | Devuelve | Obligación |
|---|---|---|
| `currentUser` | `StudentIdentity?` | null si no hay sesión |
| `authStateChanges` | `Stream<StudentIdentity?>` | emite al entrar y al salir |
| `signUp(email, password)` | `StudentIdentity` | falla con error tipado, nunca con excepción cruda |
| `signIn(email, password)` | `StudentIdentity` | ídem |
| `sendPasswordReset(email)` | `void` | ídem |
| `signOut()` | `void` | no borra datos locales por sí mismo |

**Errores tipados** — la interfaz debe poder dar un mensaje distinto a cada caso (FR-004),
así que el contrato no deja pasar excepciones de Firebase hacia arriba:

`invalidEmail` · `weakPassword` · `emailAlreadyInUse` · `wrongCredentials` ·
`userNotFound` · `tooManyAttempts` · `noConnection` · `unknown`

`noConnection` es el que sostiene el caso borde del primer arranque sin red: la interfaz
muestra un mensaje específico con reintento, y **no** pierde lo que la persona escribió.

**Obligación sobre el cierre de sesión**: `signOut` no borra la base local. Quién borra y
cuándo lo decide la interfaz, que antes debe advertir qué quedaría sin respaldar (FR-005).

---

## SyncService

**Requisitos que cubre**: FR-041, FR-042, FR-043.

| Operación | Devuelve | Obligación |
|---|---|---|
| `pull(uid, courseId)` | `StudentProgress?` | estado remoto, o null si no existe |
| `pushMerged(local)` | `StudentProgress` | **transacción**: lee remoto, fusiona, escribe, devuelve el resultado |
| `remoteChanges(uid, courseId)` | `Stream<StudentProgress>` | escucha en vivo el documento remoto |
| `syncStatus` | `Stream<SyncState>` | alimenta `sync_banner` |

**Obligación central**: `pushMerged` **nunca** sobrescribe. Internamente ejecuta una
transacción de Firestore que lee el documento remoto, lo pasa por
`engine/progress_merger.dart` junto al estado local y escribe el resultado. No existe en el
contrato ninguna operación que permita un reemplazo directo, para que ni por descuido se
pueda perder progreso.

El resultado que devuelve es el estado fusionado, que el llamador debe escribir en la base
local. Así los dos lados quedan iguales tras cada sincronización.

**Cuándo se empuja** (`sync_scheduler.dart`): al iniciar sesión, al terminar una lección o
un examen, al terminar una sesión de repaso, al recuperar la conexión, y al pasar la app a
segundo plano. Nunca bloquea la interfaz: si falla, se registra en `SyncState.lastError` y
se reintenta.

**Cuándo se recibe** (`remoteChanges`): de forma continua mientras la app está en primer
plano, mediante la escucha en vivo del documento remoto. Cada emisión se fusiona con el
estado local —con la misma función `progress_merger`, no con una lógica paralela— y se
escribe el resultado.

Esto es lo que hace cumplible SC-004: un segundo dispositivo abierto y ocioso recibe el
avance en segundos **sin que la persona recargue ni reinicie la app**. Sin la escucha en
vivo, los disparadores de empuje son todos acciones locales y un dispositivo inactivo
nunca se enteraría de nada.

Nota: desactivar la persistencia local de Firestore (ver
[firestore.md](./firestore.md)) **no** impide la escucha en vivo. Son mecanismos
independientes: lo que se desactiva es la segunda caché, no la suscripción.

Como la fusión es idempotente, recibir una emisión que ya se había fusionado no tiene
efecto, así que no hace falta llevar la cuenta de qué se procesó.

**Obligación de no fallar en silencio** (FR-043): todo fallo llega a `syncStatus` con su
motivo. La interfaz es responsable de hacerlo visible.

---

## TtsService

**Requisitos que cubre**: FR-014, FR-015.

| Operación | Devuelve | Obligación |
|---|---|---|
| `initialize(languageTag)` | `TtsAvailability` | nunca lanza; informa qué se pudo |
| `speak(text)` | `void` | no-op silencioso si no está disponible |
| `stop()` | `void` | |
| `setRate(rate)` | `void` | preferencia de la persona |

**`TtsAvailability`**: `available` · `languageMissing` (el motor existe pero no hay voz del
idioma) · `engineMissing` · `unsupportedPlatform`.

**Obligación**: `initialize` consulta las voces del sistema y **no asume** que exista la
del idioma estudiado. Si devuelve algo distinto de `available`, la interfaz presenta los
ejercicios de escucha con su `transcriptFallback` y lo explica, en lugar de mostrar un
botón de audio que no suena.

Como la síntesis la hace el motor del sistema operativo, funciona sin conexión. Esa es la
razón de D5 en research.md y lo que hace cumplible FR-014 sin empaquetar audio.

---

## SttService

**Requisitos que cubre**: FR-016 a FR-020. Es el servicio con la degradación más delicada.

| Operación | Devuelve | Obligación |
|---|---|---|
| `checkAvailability()` | `SttAvailability` | sin pedir permiso todavía |
| `requestPermission()` | `bool` | se invoca solo cuando la persona va a usarlo |
| `listenOnce(languageTag)` | `SttOutcome` | nunca lanza |
| `cancel()` | `void` | |

**`SttAvailability`**: `onDeviceReady` · `networkOnly` · `permissionDenied` ·
`noMicrophone` · `unsupportedPlatform`.

**`SttOutcome`**: `recognized(text)` · `noSpeechDetected` · `failedUseAlternative(reason)`.

### Degradación en tres pasos

Esta es la implementación de D6 de research.md, y la única manera de cumplir FR-039 junto
con FR-016:

1. Intentar `SpeechListenOptions(onDevice: true)`. Es reconocimiento local, sin conexión.
2. Si la sesión falla y hay red, reintentar con el reconocedor del sistema.
3. Si no hay ninguno disponible —sin red, sin paquete de idioma, permiso denegado, sin
   micrófono o plataforma sin soporte— devolver `failedUseAlternative`, y la interfaz
   presenta el `writtenFallback`.

El paso 3 **no es un error**: es una ruta válida con la que la lección se aprueba igual. De
ahí que SC-008 exija que el 100 % de los ejercicios orales se pueda aprobar con el
micrófono denegado y el sonido apagado.

**Obligación sobre la calificación** (FR-020): un `failedUseAlternative` o un
`noSpeechDetected` **no** cuentan como respuesta incorrecta. Solo un `recognized` cuya
comparación con la frase objetivo no alcanza el umbral cuenta como fallo, y aun así la
persona puede continuar tras varios intentos.

**Obligación sobre el permiso** (FR-018): `requestPermission` se invoca únicamente cuando
la persona decide usar el micrófono, y la interfaz explica para qué antes de pedirlo. Nunca
al arrancar la app.

---

## BackupService

**Requisitos que cubre**: FR-045, FR-046. Es además una obligación directa del Principio IV
de la constitución ("Existe exportación e importación de copia de seguridad accesible al
usuario").

| Operación | Devuelve | Obligación |
|---|---|---|
| `export(uid, courseId)` | `BackupDocument` | instantánea completa del progreso |
| `serialize(backup)` | `String` | JSON legible, con versión de esquema |
| `parse(text)` | `BackupParseResult` | valida antes de aplicar; nunca lanza |
| `import(backup)` | `StudentProgress` | **fusiona**, no reemplaza |
| `wipe(uid, courseId)` | `void` | borrado total, solo tras confirmación de la interfaz |

**Formato**: JSON con la misma forma que el documento remoto (ver
[firestore.md](./firestore.md)), más un encabezado con `backupVersion`, `appVersion`,
`exportedAt` y el `courseId`. Reusar la forma del documento remoto evita mantener dos
serializaciones y significa que un respaldo se puede inspeccionar a ojo.

**Obligación central**: `import` **fusiona** con el progreso existente usando
`engine/progress_merger.dart`, igual que la sincronización. Importar un respaldo viejo
nunca puede hacer retroceder a quien ya avanzó más. Esta es la misma garantía de FR-042 y
descansa en la misma propiedad de no decrecimiento.

**Validación antes de aplicar** (`BackupParseResult`): `valid(backup)` ·
`unsupportedVersion(found, supported)` · `malformed(reason)` · `wrongCourse(found)`. Un
archivo corrupto o de otra versión se rechaza con un mensaje claro y **no toca** el
progreso existente.

**Obligación sobre `wipe`** (FR-046): el servicio no pregunta nada. La confirmación
explícita es responsabilidad de la interfaz, que debe advertir que la operación es
irreversible y que el respaldo es la única vuelta atrás. El servicio solo ejecuta.

**Dónde se expone**: `settings_screen.dart`, con tres acciones separadas —exportar,
importar, borrar— y la destructiva visualmente diferenciada de las otras dos.

---

## SettingsStore

| Operación | Obligación |
|---|---|
| `themeMode` | claro, oscuro o del sistema (FR-048) |
| `speechRate` | velocidad de la voz |
| `lastCourseId` | curso activo |

Local, no se sincroniza: son preferencias del dispositivo, no progreso.

---

## Dobles para pruebas

`test/fakes/` contiene una implementación falsa de cada contrato. Obligación: cada falso
debe poder simular **todos** los estados de fallo, no solo el camino feliz. En concreto,
`FakeSttService` debe poder devolver cada valor de `SttAvailability` y cada variante de
`SttOutcome`, porque la ruta alternativa es un requisito verificable (SC-008) y no un caso
excepcional.
