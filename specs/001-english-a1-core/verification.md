# Verificación y despliegue — estado al 8 de octubre de 2026

La app está **publicada** en <https://languages-buildlark.web.app> y el dominio
personalizado queda pendiente de dos pasos que exigen consola y DNS.

Este documento separa tres cosas que es fácil confundir: lo **verificado**, lo
**cubierto por pruebas automatizadas** y lo que **sigue pendiente de hacer a
mano**. Un criterio cubierto por pruebas no es lo mismo que uno comprobado en un
teléfono real, y mezclarlos sería decir que está hecho algo que no se ha mirado.

---

## Verificado de verdad

| Tarea | Qué se hizo | Resultado |
|---|---|---|
| T161 | `flutter analyze` | `No issues found!` |
| T162 | `flutter test` | 476 pruebas en verde |
| T173 · SC-011 | Curso de prueba de un módulo creado en `lib/content/zz/`, registrado en `catalog.dart`, comprobado recorrible por el motor | `git status --short lib/core lib/engine lib/services lib/ui` imprimió **nada**. Curso descartado al terminar |
| T178 | `flutter build web --release` y `firebase deploy --only hosting,firestore:rules` | Desplegado. Reglas de Firestore ya estaban al día |
| T177 (parcial) | App publicada abierta en navegador | Arranca sin un solo error de consola; `drift_worker.js` carga; `sqlite3.wasm` se sirve como `application/wasm`; la base `languages_app` **existe en IndexedDB**; drift elige `sharedIndexedDb`, su ruta persistente fiable |

### Dos fallos reales que encontró esta fase

Los dos fallaban **en silencio**: la app arrancaba, se veía bien y no guardaba
nada. Ninguna prueba de la VM de Dart podía verlos, porque solo ocurren al
compilar para web.

1. **`driftDatabase(name:)` lanza en web** si no se le pasa `web:`. Como el error
   ocurre al construir la base, `openAppDatabase` lo capturaba y caía a la
   reserva volátil. Toda visita desde el navegador habría corrido sobre una base
   en memoria, con el aviso de «tu avance no se está guardando» puesto, y
   efectivamente perdiéndolo.
2. **`main.dart` importaba `package:drift/native.dart`**, que arrastra
   `dart:ffi`. El build web fallaba con un error que apuntaba a sqlite3 en lugar
   de a la línea culpable.

Ambos quedan vigilados por `test/services/db/web_build_guard_test.dart`.

---

## Cubierto por pruebas automatizadas

No se recorrió a mano, pero hay pruebas que ejercen exactamente lo que el
criterio pide.

| Tarea | Dónde |
|---|---|
| T169 · SC-007 · la explicación dice por qué | `a1_integrity_test.dart` exige explicación con longitud mínima en **todos** los ejercicios de los cinco tipos; `lesson_screen_test.dart` y `exercise_widgets_test.dart` comprueban que al fallar aparecen la explicación y la respuesta esperada |
| T171 · SC-009 · nivel bloqueado y nivel anunciado no abren | `course_flow_test.dart` y `progression_screens_test.dart`: la tarjeta se dibuja sin `onTap`, así que no hay ruta ni tocando ni con teclado |
| T174 · SC-012 · racha con reloj inyectado | `streak_tracker_test.dart` recorre 40 días seguidos cruzando dos meses, además del año bisiesto y el cambio de año |
| T176 · FR-045 y FR-046 | `json_backup_service_test.dart` (ida y vuelta, respaldo viejo que no pierde lo posterior, versión futura, archivo corrupto, idioma ajeno) y `settings_screen_test.dart` (las tres acciones por la interfaz, con la confirmación de borrado) |
| T170 · SC-008 (parcial) | `oral_exercises_test.dart` aprueba una lección completa por las alternativas accesibles, sin micrófono ni voz. Falta revocar el permiso en un dispositivo real |
| T172 · SC-010 (parcial) | Hay prueba de 360 dp en lección, nivelación, progreso y ajustes, y de 130 % de tamaño de letra en el anillo de progreso. Falta el barrido completo con `adb shell` |

---

## Pendiente de hacer a mano

### En el emulador o en un teléfono

Estas no se pueden automatizar de forma honesta: miden tiempo real, estado del
sistema o dos dispositivos a la vez.

- **T163 · SC-001** — cronometrar en emulador limpio: crear cuenta y llegar al
  primer ejercicio en menos de 3 minutos.
- **T164 · SC-002** — aprobar una lección, `adb reboot`, reabrir y comparar XP,
  racha y lecciones aprobadas.
- **T165 · SC-003** — lección completa en modo avión, incluido el audio, tras
  haber iniciado sesión una vez.
- **T166 · SC-004** — emulador y Chrome abiertos con la misma cuenta: aprobar
  una lección en uno y verla en el otro en menos de 30 s sin recargar.
- **T167 · SC-005** — avanzar distinto en ambos en modo avión, restaurar la
  conexión y verificar que se conserva lo mejor de cada uno.
- **T168 · SC-006** — cronometrar cada lección de A1 (objetivo: 5 a 10 minutos).
- **T170 · SC-008** — revocar el permiso de micrófono y silenciar el
  dispositivo; aprobar una lección completa.
- **T172 · SC-010** — `adb shell wm size 360x800` y `font_scale 1.3`; recorrer
  todas las pantallas; restaurar al terminar.
- **T175 · FR-047 a FR-049** — TalkBack, objetivos táctiles de 48 dp y contraste
  WCAG AA en claro y oscuro.

### En el navegador

- **T177** — lo que falta: crear una cuenta en la app publicada, aprobar una
  lección, pulsar F5 y comprobar que el progreso sigue ahí. La base ya se crea
  y persiste; lo que no se ha ejercido es el ciclo completo con sesión abierta.

### Dominio personalizado (T179 y T180)

Hoy `languages.buildlark.com` **no existe en DNS**, y `www.buildlark.com`
apunta a Squarespace (198.185.159.x y 198.49.23.x).

1. Consola de Firebase → **Hosting** → *Añadir dominio personalizado* →
   `languages.buildlark.com`.
2. Firebase entrega un registro **TXT** de verificación y, después, dos
   registros **A** (o un CNAME). Añadirlos donde se gestione el DNS de
   `buildlark.com`.
3. Esperar la emisión del certificado, que suele tardar entre unos minutos y 24
   horas.
4. **No olvidar**: Consola de Firebase → **Authentication** → *Settings* →
   *Authorized domains* → añadir `languages.buildlark.com`. Sin ese paso el
   registro y el acceso fallan en el dominio nuevo con `auth/unauthorized-domain`
   aunque el sitio se vea perfectamente.
5. **T180** — ya en el dominio: registro, lección completa y persistencia tras
   recargar.

---

## Notas del despliegue

- **Caché.** `index.html` y `flutter_service_worker.js` se sirven con
  `no-cache`; el resto de recursos, con `immutable` a un año. Sin eso, un
  despliegue puede servir un `index.html` viejo apuntando a recursos nuevos.
  La primera regla se escribió para `/index.html` y no se aplicaba, porque la
  petición real es a `/`: están ambas.
- **`sharedIndexedDb` y no OPFS.** Drift informa que faltan
  `dedicatedWorkersInSharedWorkers` y `sharedArrayBuffers`, así que no puede
  usar OPFS. Es lo esperado sin aislamiento de origen cruzado, y
  `sharedIndexedDb` es la ruta persistente que drift considera fiable —la
  arriesgada es `unsafeIndexedDb`—. Activar OPFS exigiría cabeceras COOP/COEP,
  que conviene no tocar sin probar antes que no rompen el SDK de Firebase.
- **El identificador de la app ya es `com.buildlark.languages`** en las cinco
  plataformas, y no queda ni un `com.example` en el proyecto. Se resolvió el 6
  de octubre ([issue #1](https://github.com/buildlark-dev/languages_app/issues/1),
  cerrada). Comprobado el 8 de octubre con `flutter build apk --debug` y
  `aapt2 dump packagename`, que lee el identificador **del APK construido** y
  devuelve `com.buildlark.languages`: es evidencia de que toda la cadena
  —gradle, `namespace`, paquete Kotlin, `google-services.json` y el registro en
  Firebase— está alineada, y no solo de que los archivos digan lo correcto.

  En una versión anterior de este documento figuraba como pendiente. Era un
  error mío: lo di por no hecho sin mirarlo.

- **Lo que sí bloquea Play Store es la firma.** `android/app/build.gradle.kts`
  sigue con `signingConfig = signingConfigs.getByName("debug")` y su `TODO`.
  Una compilación de publicación firmada con las claves de depuración no se
  puede subir. Hace falta generar un `keystore` de publicación, guardarlo fuera
  del repositorio y referenciarlo desde un `key.properties` ignorado por git.
  No afecta al despliegue web ni a las pruebas en emulador.

---

## Despliegue web, 9 de octubre de 2026 (Fase 17)

Esta sección corrige la anterior. Lo que decía sobre la caché era falso, y el
error no se veía desde el navegador: hay que leer las cabeceras.

### Lo que estaba roto

Medido con `curl -I` sobre el sitio publicado:

```
/flutter_bootstrap.js  →  cache-control: public, max-age=31536000, immutable
/main.dart.js          →  public, max-age=31536000, immutable
/version.json          →  public, max-age=31536000, immutable
/flutter_service_worker.js → public, max-age=31536000, immutable
```

La regla `no-cache` de `flutter_service_worker.js` estaba escrita **antes** de
la comodín `**/*.@(js|wasm|json|…)`, y Firebase aplica la **última**
coincidencia, no la primera. Flutter no pone hash de contenido en esos nombres,
así que un navegador que ya los tenía no volvía a pedirlos durante un año: la
PWA instalada quedó congelada y ningún despliegue llegaba a ella.

Además, `navigator.serviceWorker.getRegistrations()` devolvía lista vacía. El
`flutter_service_worker.js` que genera Flutter 3.44 son treinta líneas cuyo
único trabajo es **desregistrarse**: no guarda nada. La web no tenía con qué
abrirse sin conexión y tampoco canal para enterarse de una versión nueva.

Y la consola de la app cargada escribía
`MissingPluginException(No implementation found for method getAll on channel
plugins.flutter.io/shared_preferences)`: el registro de plugins web generado el
8 de octubre a las 07:28 era anterior a la entrada de `shared_preferences` en
`pubspec.yaml` (12:58), y el build desplegado (21:49) lo reutilizó. En web el
tema y la velocidad de voz no se guardaban.

### Lo que se verificó después

Cabeceras, con `curl -I`:

```
/                       Cache-Control: no-cache
/flutter_bootstrap.js   Cache-Control: no-cache
/main.dart.js           Cache-Control: no-cache
/build-id.json          Cache-Control: no-store
/app_service_worker.js  Cache-Control: no-cache
```

Nada se sirve ya con `immutable`: lo que Flutter no versiona por contenido se
revalida por ETag, que cuesta una petición condicional y evita que un arreglo
tarde un año en llegar. El modo sin conexión lo da el service worker, no la
caché HTTP, así que no se pierde nada.

En el navegador, tras una carga limpia:

```
service worker:  app_service_worker.js — scope "/", estado "activated"
caché:           9 entradas, con "/", flutter_bootstrap.js, main.dart.js,
                 sqlite3.wasm, drift_worker.js, las fuentes y
                 canvaskit/chromium/canvaskit.{js,wasm}
build-id.json:   a2a2e2f-20261009-0916, servido con no-store
registro web:    6 plugins, shared_preferences_web incluido
```

`--no-web-resources-cdn` hizo falta para lo último: por defecto Flutter pide
canvaskit a `www.gstatic.com`, y un recurso de otro origen no se puede guardar
—la respuesta es opaca—, así que sin red no había con qué dibujar.

### Lo que sigue sin funcionar, y es medible

**La web todavía no arranca sin conexión.** Queda fuera de nuestro dominio lo
que el SDK de Firebase carga en tiempo de ejecución:

```
www.gstatic.com/firebasejs/12.19.0/firebase-app.js
www.gstatic.com/firebasejs/12.19.0/firebase-auth.js
www.gstatic.com/firebasejs/12.19.0/firebase-firestore-pipelines.js
fonts.gstatic.com/… (Roboto)
```

`Firebase.initializeApp` es lo primero que hace `main()`, así que sin esos
archivos la app no llega a pintar. Las fuentes no importan —hay respaldo del
sistema—; el SDK sí. Servirlo desde nuestro dominio significa versionar unos
cientos de kilobytes de JavaScript de terceros en el repositorio y fijar su
versión a mano, que es una decisión de proyecto y no un detalle de despliegue:
queda anotada como trabajo aparte. Hasta entonces **FR-039 y SC-003 se cumplen
en Android y no en web**, y decirlo es preferible a seguir contándolo como
hecho.
