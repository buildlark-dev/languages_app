# Phase 0 — Research: Núcleo del curso de inglés A1

**Feature**: `001-english-a1-core` | **Date**: 2026-10-06

Entorno verificado en la máquina de desarrollo:

| Herramienta | Versión instalada |
|---|---|
| Flutter | 3.44.2 (stable, 2026-06-10) |
| Dart | 3.12.2 |
| Firebase CLI | 15.29.0 |
| Emulador Android | Pixel 7 (disponible) |

Todas las versiones de paquete citadas abajo se verificaron en pub.dev el 2026-10-06.

---

## D1 — Gestión de estado: Riverpod

**Decisión**: `flutter_riverpod` 3.4.3.

**Rationale**: el estado compartido real de esta funcionalidad no es pequeño —sesión
autenticada, progreso del estudiante, cola de repaso, estado de sincronización, lección
en curso, tema— y lo consumen más de diez pantallas. Riverpod permite leer y sustituir
dependencias **sin `BuildContext`**, lo que mantiene el motor (`lib/engine/`) libre de
cualquier import de Flutter y hace que se pueda probar con un `ProviderContainer` en una
prueba unitaria, sin montar widgets. Eso sostiene directamente el Principio V.

**Alternatives considered**:

- `ChangeNotifier` + `InheritedNotifier` de la biblioteca estándar: viable, pero obliga a
  escribir a mano la inyección y la sustitución de dependencias para pruebas, y acopla la
  lectura de estado a `BuildContext`. Sería reimplementar peor lo que ya existe.
- `provider`: menos seguro en tipos y dependiente de `BuildContext`.
- `bloc`: más ceremonia (evento + estado por interacción) de la que justifica esta
  escala.

**Nota de gobernanza**: la constitución prefiere la biblioteca estándar frente a una
dependencia externa, así que esta elección queda registrada en Complexity Tracking del
plan.

---

## D2 — Almacenamiento local: Drift

**Decisión**: `drift` 2.35.1 + `drift_flutter` 0.3.1.

**Rationale**: el Principio IV exige esquema versionado y migración que preserve el
progreso. Drift es el único candidato con versionado de esquema y API de migración de
primera clase, además de consultas tipadas generadas en tiempo de compilación. La cola de
repaso necesita consultar "qué vence hoy" sin cargar todo en memoria, lo que pide un
motor con índices de verdad. Funciona en Android y en web, que son las dos plataformas
primarias.

**Alternatives considered**:

- `shared_preferences`: sin esquema, sin migraciones y sin consultas. Averiguar las
  palabras vencidas obligaría a deserializar la cola completa en cada arranque. Es lo que
  usaba el prototipo HTML (`localStorage`) y no escala al requisito FR-041.
- `hive`: rápido, pero sin consultas por rango y con una historia de migración más débil.
- `isar`: continuidad del proyecto incierta; no quiero apostar el almacén de progreso.
- `sqflite`: sin tipado; el mapeo manual multiplica los errores silenciosos.

**Consecuencia operativa**: la web necesita `sqlite3.wasm` y `drift_worker.js` dentro de
`web/`. Queda como tarea de configuración explícita.

---

## D3 — Autenticación: Firebase Auth con correo y contraseña

**Decisión**: `firebase_core` 4.15.0 + `firebase_auth` 6.7.0 (que requiere
`firebase_core` ^4.14.0).

**Rationale**: FR-002 pide exactamente crear cuenta, iniciar sesión, cerrar sesión y
restablecer contraseña; Firebase Auth cubre las cuatro sin servidor propio, incluido el
correo de restablecimiento. FR-003 (sesión persistente) lo resuelve de fábrica. El
proyecto ya se despliega en Firebase Hosting, así que no se añade un proveedor nuevo a la
infraestructura.

**Alternatives considered**:

- Backend propio de autenticación: sin ninguna ventaja aquí y con obligación de custodiar
  contraseñas.
- Entrada solo con proveedores federados (Google, Apple): menos fricción, pero FR-002
  pide restablecimiento de contraseña, que solo tiene sentido con credenciales propias.
  Los proveedores federados se pueden añadir después sin rediseño.

---

## D4 — Sincronización: Firestore con fusión monotónica, no con su caché

**Decisión**: `cloud_firestore` 6.10.0 **con la persistencia local de Firestore
desactivada**. El almacén local autoritativo es Drift (D2). La sincronización es una
transacción explícita de leer-fusionar-escribir.

**Rationale — y este es el punto crítico del diseño**: Firestore resuelve conflictos por
*última escritura gana* a nivel de documento. Si el progreso viviera en su caché offline,
estudiar en el teléfono sin red y luego abrir el PC **borraría** el avance del teléfono al
sincronizar. Eso viola FR-039 ("MUST NOT descartar progreso en silencio") y haría
imposible SC-005.

La solución es que **toda** magnitud del progreso se fusione con una regla monotónica:

| Dato | Regla de fusión |
|---|---|
| Puntaje de cada lección y examen | máximo |
| XP | máximo |
| Racha | máximo |
| Conjunto de lecciones/módulos aprobados | unión |
| Estado de cada nivel | el más avanzado |
| Tarjeta de repaso | paso de intervalo máximo, fecha de vencimiento más próxima |
| Cola de repaso | unión por palabra |

Máximo y unión forman un **retículo** (*join-semilattice*): el resultado no depende del
orden en que llegan los dispositivos y repetir la fusión no cambia nada. Es decir, la
convergencia es demostrable y las pruebas pueden verificarla con cualquier permutación de
eventos. Firestore no ofrece una operación `max` sobre campos (solo `increment`), así que
la fusión va dentro de una transacción que lee el documento remoto, lo une con el estado
local y lo reescribe.

Tener dos cachés compitiendo (la de Firestore y Drift) solo produciría estados
divergentes, de ahí la desactivación explícita de la persistencia de Firestore.

**Alternatives considered**:

- Confiar en la persistencia offline de Firestore como almacén único: menos código, pero
  pérdida silenciosa de progreso. Rechazado por FR-039.
- Diario de eventos con reproducción (event sourcing): converge igual de bien y conserva
  historia, pero multiplica el volumen de datos y la complejidad de migración para un
  beneficio que esta funcionalidad no necesita.
- Backend propio con fusión en servidor: traslada el problema sin resolverlo y añade
  infraestructura.

---

## D5 — Síntesis de voz: flutter_tts

**Decisión**: `flutter_tts` 4.2.5.

**Rationale**: usa el motor de voz del sistema operativo, así que una vez que el
dispositivo tiene instalada la voz en inglés la reproducción es local y **sin conexión**,
que es justo lo que exige FR-013. No hace falta empaquetar ni descargar audio: el
contenido declara texto y el motor lo pronuncia, lo que además mantiene el tamaño de la
app bajo y permite añadir francés y portugués sin producir audio nuevo.

**Riesgo identificado**: si el dispositivo no tiene datos de voz en inglés, la
reproducción falla. Mitigación: al inicializar se consulta `getLanguages`; si no hay
`en-*` disponible, la app lo informa y los ejercicios de escucha usan su alternativa
accesible (FR-018). En web depende de las voces del navegador, que varían.

**Alternatives considered**:

- Audio pregrabado como assets: calidad y consistencia superiores, pero exige producir y
  versionar cientos de archivos por idioma, y multiplica el peso de la app. Contradice la
  extensibilidad que pide el Principio I.
- Síntesis en la nube (Google Cloud TTS): mejor voz, pero rompe FR-013 (audio sin
  conexión) y añade costo por uso.

---

## D6 — Reconocimiento de habla: speech_to_text, con degradación en tres pasos

**Decisión**: `speech_to_text` 7.5.0, pidiendo
`SpeechListenOptions(onDevice: true)` primero.

**Hallazgo decisivo de la investigación**: el reconocimiento en el dispositivo
**no se puede garantizar**. La opción `onDevice` existe y Android la respeta, pero la
sesión *falla* si no está disponible, y en la práctica el dispositivo necesita tener
instalado el paquete de idioma offline correspondiente. En web, la API del navegador
envía el audio a un servicio remoto, así que exige conexión.

**Esto choca de frente con FR-036** ("completar lecciones [...] sin conexión"), porque un
ejercicio de pronunciación es parte de una lección.

**Resolución**: la alternativa accesible que FR-018 ya exige para quien no puede usar
micrófono **cumple simultáneamente** como ruta sin conexión. Degradación en tres pasos:

1. Reconocimiento en el dispositivo (`onDevice: true`) — sin conexión, preferido.
2. Si falla y hay red, reconocimiento del servicio del sistema.
3. Si no hay ninguno, o el permiso está denegado, o no hay micrófono: **alternativa
   accesible**, con la que la lección se puede aprobar igual.

Con esto FR-036 se cumple de forma estricta: la lección siempre es completable sin
conexión, aunque el camino concreto varíe. FR-019 refuerza que un fallo de
reconocimiento nunca cuenta como error de contenido.

**Alternatives considered**:

- `whisper_edge` / `whisper_ggml` (whisper.cpp en el dispositivo): reconocimiento
  realmente offline y garantizado, independiente del sistema operativo. Rechazado **para
  esta entrega** por el peso del modelo (decenas o cientos de MB), el tiempo de
  inferencia en un teléfono modesto y la falta de soporte en web. Queda anotado como la
  vía a evaluar si la degradación resulta insuficiente en pruebas reales.
- No incluir pronunciación: descartado por decisión explícita del responsable del
  proyecto.

**Calificación de la pronunciación**: comparación normalizada entre el texto reconocido y
la frase objetivo (minúsculas, sin puntuación, espacios colapsados). Acento y entonación
no se puntúan, según lo asumido en la especificación.

---

## D7 — El contenido es código Dart, no assets JSON

**Decisión**: el contenido de cada idioma son objetos `const` de Dart en
`lib/content/<idioma>/`, que implementan los contratos de `lib/core/`.

**Rationale**: da verificación en tiempo de compilación (un módulo mal formado no
compila, en lugar de fallar en el teléfono del estudiante), elimina el parseo y la carga
de assets, y hace que el funcionamiento sin conexión sea gratuito. Es también lo que
vuelve real el Principio I: el motor depende de los contratos, nunca del contenido.

**Alternatives considered**:

- Assets JSON: permitiría editar contenido sin recompilar y actualizarlo por red, pero
  pierde el tipado, exige validación en tiempo de ejecución y abre la puerta a que un
  módulo malformado llegue al estudiante. Cuando exista necesidad real de actualizar
  contenido sin publicar versión, se puede añadir una fuente remota **detrás del mismo
  contrato**, sin tocar el motor.

**Consecuencia**: con el límite de ~300 líneas por archivo del Principio II, cada módulo
de A1 necesita su propio archivo.

---

## D8 — Navegación sin dependencia externa

**Decisión**: `Navigator` de la biblioteca estándar, con un widget raíz que decide entre
el flujo de autenticación y el de estudio.

**Rationale**: la especificación no pide enlaces profundos, URLs compartibles ni
navegación por URL. Flutter web ya integra el botón Atrás del navegador con las
operaciones de `Navigator`, así que la experiencia en web queda correcta. Evitar
`go_router` mantiene una dependencia menos, en línea con la constitución.

**Alternatives considered**:

- `go_router`: necesario si hiciera falta URL por pantalla o enlaces profundos. Se puede
  adoptar después; el cambio queda confinado a `lib/app/`.

---

## D9 — Reloj inyectado

**Decisión**: el motor nunca llama a `DateTime.now()`. Recibe un `Clock` (función que
devuelve la fecha y hora actual) definido en `lib/core/clock.dart`.

**Rationale**: la racha (FR-031) y los intervalos de repaso (FR-028) son lógica de fechas.
Probar "deja pasar un día y la racha se reinicia" con el reloj real exigiría esperar un
día o manipular el reloj del sistema. Con el reloj inyectado, una prueba unitaria recorre
noventa días en milisegundos. Sin esto, SC-012 y los escenarios 2 y 3 de la Historia 7 no
son verificables en la práctica.

---

## D10 — Pruebas con dobles escritos a mano

**Decisión**: `flutter_test` para unitarias y de widget, con implementaciones falsas
escritas a mano de los contratos de servicio (auth, sync, TTS, STT). Sin biblioteca de
simulación.

**Rationale**: los contratos son pequeños y pocos. Un falso explícito de treinta líneas se
lee mejor que una cadena de `when(...).thenReturn(...)`, y Drift ofrece base de datos en
memoria para las pruebas del almacén. Una dependencia menos.

---

## D11 — Internacionalización separada del contenido

**Decisión**: `flutter_localizations` + `intl` con archivos ARB para las cadenas de
interfaz, en español.

**Rationale**: el Principio I exige que el idioma de la interfaz y el idioma estudiado sean
dimensiones independientes. Con las cadenas de interfaz en ARB, añadir una interfaz en
otro idioma no toca el contenido didáctico, y añadir un idioma de estudio no toca la
interfaz.

---

## D12 — Configuración de Firebase: no es secreta, y ocultarla rompe la compilación

**Decisión**: versionar `firebase_options.dart`, `android/app/google-services.json` y
`firestore.rules`. Mantener fuera del repositorio únicamente los secretos reales: claves
de cuenta de servicio y archivos `.env`.

**Rationale y corrección de una decisión previa**: al configurar el repositorio se añadió
al `.gitignore` un bloque que excluye `google-services.json` y `GoogleService-Info.plist`.
Fue una precaución mal dirigida. Esos archivos contienen **identificadores de cliente
públicos**, no credenciales: cualquiera puede extraerlos de un APK publicado. La seguridad
de Firebase no proviene de ocultarlos, sino de las **reglas de seguridad de Firestore** y
de las restricciones de la clave de API. Mantenerlos ignorados tiene un costo real: un
clon nuevo del repositorio no compila para Android.

Cambio requerido en `.gitignore`: eliminar las líneas `google-services.json` y
`GoogleService-Info.plist`; conservar `*-service-account*.json`, `.env`, `.env.*` y
`.firebase/`.

Las reglas de Firestore son entonces parte entregable de esta funcionalidad, no un ajuste
de consola: cada persona solo puede leer y escribir su propio documento de progreso.

---

## Resumen de dependencias nuevas en `pubspec.yaml`

| Paquete | Versión | Para qué | Requisito que lo exige |
|---|---|---|---|
| `flutter_riverpod` | ^3.4.3 | estado compartido e inyección | FR-003, FR-029, FR-032 |
| `drift` | ^2.35.1 | almacén local con esquema versionado | FR-037, FR-041 |
| `drift_flutter` | ^0.3.1 | apertura de la base según plataforma | FR-037 |
| `firebase_core` | ^4.15.0 | base de Firebase | FR-001 |
| `firebase_auth` | ^6.7.0 | cuenta, sesión, restablecimiento | FR-001 a FR-005 |
| `cloud_firestore` | ^6.10.0 | sincronización del progreso | FR-038, FR-039 |
| `flutter_tts` | ^4.2.5 | pronunciación sin conexión | FR-013, FR-014 |
| `speech_to_text` | ^7.5.0 | ejercicios de pronunciación | FR-015, FR-016 |
| `intl` | del SDK | formato de fechas y cadenas | FR-009 |
| `flutter_localizations` | del SDK | interfaz en español | FR-009 |

Desarrollo: `drift_dev` y `build_runner` para la generación de código de Drift.

---

## Riesgos abiertos, con su mitigación

| Riesgo | Mitigación | Verificación |
|---|---|---|
| El dispositivo no tiene voz en inglés instalada | Detección al inicializar y alternativa accesible | Probar en emulador limpio sin datos de voz |
| El reconocimiento en el dispositivo no está disponible | Degradación en tres pasos (D6) | Probar con red apagada y permiso denegado |
| Dos dispositivos con progreso divergente | Fusión monotónica (D4) | Pruebas de propiedad con permutaciones de eventos |
| La web necesita artefactos de sqlite3 en `web/` | Tarea de configuración explícita | `flutter build web` y prueba de persistencia en navegador |
| Reconocimiento de voz en el emulador de Android | El emulador enruta el micrófono del equipo; si falla, se verifica en dispositivo físico | Prueba manual documentada en quickstart |
| Pérdida de progreso por fallo de almacenamiento | Degradación a memoria con aviso explícito (FR-040) | Prueba con base de datos que lanza error |
