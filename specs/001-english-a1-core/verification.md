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

---

## T191 · Recorrido en el emulador Pixel 7, 13 de octubre de 2026

Primera vez que la app se abre en Android. Hasta hoy se compilaba, se corregía
su manifiesto y se verificaba el APK, pero **ninguna pantalla se había visto
corriendo ahí**. La sesión la inició el responsable del proyecto; el recorrido
lo hizo Claude por `adb`, sin tocar el borrado de progreso.

### Lo que se vio, pantalla por pantalla

| # | Pantalla | Qué se vio |
|---|---|---|
| 1 | Acceso | Correo, contraseña, «Entrar», «¿No tienes cuenta? Créala» y «Olvidé mi contraseña» |
| 4 | Inicio | Correo de la sesión, catálogo con «Inglés · 1 nivel(es) · 5 próximo»; tras elegir curso, la tarjeta de repaso |
| 5 | Mapa de niveles | Oferta de nivelación, A1 «Fundamentos» con su barra, A2 a C2 como «Próximo» y bloqueados |
| 6 | Módulos del nivel | Los cuatro módulos con su check de aprobado y la tarjeta del examen de A1 |
| 7 | Detalle de módulo | Objetivo «Al terminar podrás», dos lecciones aprobadas, gramática plegable y examen del módulo |
| 8 | Lección | Vocabulario con emoji, traducción sin artículo y **botón de altavoz en cada ítem** |
| 9 | Examen | «Ejercicio 1 de 10», opción múltiple, barra de avance, «Comprobar» deshabilitado hasta elegir |
| 12 | Progreso | 100 % de A1, 4 de 4 módulos, 48 palabras al día, 1 día seguido, 504 XP, niveles con su estado |
| 13 | Ajustes | Tema, velocidad de voz con «Probar la voz», respaldo y borrado en rojo con su alcance escrito |

### Lo que no se pudo ver, y por qué

| # | Pantalla | Qué lo impide |
|---|---|---|
| 2 | Registro | Solo se llega desde el acceso, y llegar exige cerrar la sesión |
| 3 | Restablecer contraseña | Igual |
| 10 | Repaso | No hay nada vencido: la tarjeta dice «estás al día» y no se abre |
| 11 | Nivelación | La oferta se oculta cuando ya hay avance, que es el comportamiento correcto |

Son cuatro de trece. **T191 queda abierta**: declarar «recorrido» un recorrido
incompleto es exactamente lo que el Principio V prohíbe.

### Lo que el recorrido encontró

**La sincronización trae el progreso en vivo.** A las 8:08 el nivel A1 marcaba
`0/4` —instalación nueva, base local vacía—. A las 8:09, sin reiniciar la app ni
tocar nada, marcaba `4/4` y la oferta de nivelación había desaparecido sola. Es
evidencia directa de SC-004 en un dispositivo recién instalado, aunque no
sustituye a T166, que pide el caso de dos destinos en primer plano a la vez.

**El audio funciona en Android.** Al tocar el altavoz de «name», con `logcat`:

```
GoogleTTSServiceImpl: Synthesis request for locale eng-USA and name en-US-language
GoogleTTSServiceImpl: TTS dispatch: en-us-x-iog-seanet-embedded
TTS: Utterance ID has started → has completed
```

**El arreglo de T164 se ve funcionando**: «Aprobado con un 100 %. Puedes
repetirlo cuando quieras.»

**Fallo nuevo: el título de la gramática salía con el HTML en crudo** — «El
verbo `<i>to be</i>` y los pronombres». El cuerpo sí se renderizaba, así que el
mismo texto se veía bien dentro del panel y mal en su encabezado. Corregido.

**Y el diagnóstico de T164 era incompleto.** El examen de A1 **nunca se ha
aprobado**: la pantalla de progreso marca A1 como «En curso», no como superado,
y la tarjeta ofrece «Presentar el examen». Así que lo que faltaba no era solo
enseñar la nota al aprobar, sino **no esconder el intento que no aprobó**: la
tarjeta decía «Necesitas 80 % para superar el nivel» y nada más, de modo que
quien suspendió por poco y quien suspendió por mucho veían lo mismo. Ahora dice
«Tu mejor intento: 65 %. Necesitas 80 % para superar el nivel.»

### Segunda pasada por el emulador, mismo día

Con la sesión cerrada a propósito se alcanzaron las dos pantallas que faltaban,
y se comprobó en el dispositivo el arreglo del título de gramática.

| # | Pantalla | Qué se vio |
|---|---|---|
| 1 | Acceso | Campos vacíos, «Entrar», «¿No tienes cuenta? Créala», «Olvidé mi contraseña» |
| 2 | Registro | «Crear cuenta» con **«Solo pedimos correo y contraseña. Nada más.»** a la vista, que es FR-006 hecho comprobable por quien se registra |
| 3 | Restablecer contraseña | «Recuperar el acceso»: correo y «Enviar instrucciones» |
| — | Confirmación de cierre de sesión | «¿Cerrar sesión? Tu progreso está respaldado en la nube. Podrás recuperarlo al volver a entrar», con Cancelar primero |

**El título de la gramática ya se renderiza**: «El verbo *to be* y los
pronombres», en cursiva, donde antes salían las etiquetas en crudo.

**Cerrar sesión deja la app en la pantalla de acceso, sin nada encima.** Es la
otra mitad del arreglo de T163, la que no se reportó pero tenía el mismo fallo.

Quedan **2 de 13**: repaso y nivelación. Ninguna por un defecto —no hay nada
vencido que repasar, y la oferta de nivelación se oculta cuando ya hay avance—,
así que las dos solo aparecen en una cuenta recién creada. Se capturarán la
próxima vez que se cree una cuenta de prueba.

**Observación menor:** «Recuperar el acceso» no explica qué va a pasar al tocar
el botón. La pantalla de registro sí se explica sola; esta no dice que llegará
un correo con un enlace.
