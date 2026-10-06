# Quickstart — Ejecutar y validar el núcleo de inglés A1

**Feature**: `001-english-a1-core` | **Date**: 2026-10-06

Esta guía sirve para dos cosas: poner la funcionalidad en marcha, y **demostrar** que los
doce criterios de éxito de [spec.md](./spec.md) se cumplen. No contiene código de
implementación: eso va en `tasks.md` y en el código.

---

## Requisitos previos

Verificados en la máquina de desarrollo el 2026-10-06:

| Herramienta | Versión | Comprobar con |
|---|---|---|
| Flutter | 3.44.2 stable | `flutter --version` |
| Dart | 3.12.2 | `dart --version` |
| Firebase CLI | 15.29.0 | `firebase --version` |
| Emulador Android | Pixel 7 | `flutter emulators` |

Además hace falta, una sola vez:

- Un proyecto de Firebase con **Authentication** (correo y contraseña) y **Cloud
  Firestore** habilitados.
- `flutterfire configure` ejecutado, que genera `lib/firebase_options.dart` y
  `android/app/google-services.json`.
- Para la web, `sqlite3.wasm` y `drift_worker.js` dentro de `web/`.

---

## Puesta en marcha

Instalar dependencias:

```bash
flutter pub get
```

Generar el código de Drift (necesario tras cualquier cambio en las tablas):

```bash
dart run build_runner build --delete-conflicting-outputs
```

Lanzar el emulador:

```bash
flutter emulators --launch Pixel_7
```

Ejecutar la app:

```bash
flutter run
```

Ejecutar en web:

```bash
flutter run -d chrome
```

---

## Puertas de calidad

Obligatorias antes de cerrar cualquier tarea (Principio V):

```bash
flutter analyze
```

```bash
flutter test
```

Cobertura, cuando se quiera revisar qué quedó sin probar:

```bash
flutter test --coverage
```

---

## Validación de los criterios de éxito

Cada criterio tiene su forma de comprobarse. Los automáticos corren en la suite; los
manuales se ejecutan en el emulador y **se reportan diciendo qué se vio**.

### SC-001 · Cuenta creada y primer ejercicio en menos de 3 minutos

Manual, con cronómetro, en emulador limpio (`flutter run` con la app desinstalada).
Recorrido: registro → elegir inglés → omitir nivelación → módulo 1 → primer ejercicio
visible. Se mide hasta que el primer ejercicio está en pantalla.

### SC-002 · El progreso sobrevive al cierre y al reinicio

Automático en parte: `test/services/db/app_database_test.dart` verifica la persistencia de
cada tabla.

Manual para el reinicio real: aprobar una lección, anotar XP y racha, cerrar la app desde
el conmutador de tareas, reiniciar el emulador completo (`adb reboot`), volver a abrir y
comparar.

### SC-003 · Flujo completo en modo avión, incluido el audio

Manual. Tras iniciar sesión una vez:

```bash
adb shell cmd connectivity airplane-mode enable
```

Recorrer una lección completa: vocabulario, **reproducir audio** de varios ítems, lectura,
preguntas, construir frases, huecos, un ejercicio de escucha y uno de pronunciación. Luego:

```bash
adb shell cmd connectivity airplane-mode disable
```

Criterio: ninguna pantalla en blanco, ningún indicador de carga indefinido, lección
aprobable de principio a fin. El ejercicio de pronunciación puede caer en su alternativa
escrita: eso **es** el comportamiento correcto (ver D6 de research.md), no un fallo.

### SC-004 · Sincronización visible en otro dispositivo en menos de 30 s

Manual con dos destinos: el emulador Pixel 7 y Chrome, ambos con la misma cuenta y **ambos
abiertos en primer plano**. Aprobar una lección en el emulador y **mirar Chrome sin tocarlo**.

Criterio: el progreso aparece solo, en menos de 30 s, **sin recargar ni reiniciar**. Si hay
que recargar para verlo, la escucha en vivo del documento remoto no está funcionando y SC-004
no se cumple.

### SC-005 · Ninguna pérdida de progreso al sincronizar

Automático, y es la prueba más importante del conjunto:
`test/engine/progress_merger_test.dart` genera permutaciones de estados divergentes y
verifica conmutatividad, asociatividad, idempotencia y la invariante de no decrecimiento.

Manual de refuerzo: poner los dos destinos en modo avión, avanzar **distinto** en cada uno
(distintas lecciones, distinto XP), restaurar la conexión en ambos y comprobar que el
resultado conserva lo mejor de los dos y no lo de uno solo.

### SC-006 · Lección de 5 a 10 minutos

Manual, cronometrando un recorrido completo sin prisa de cada una de las lecciones de A1.

### SC-007 · Toda respuesta incorrecta explica por qué

Automático: `test/content/en/a1_integrity_test.dart` verifica que todo ejercicio de A1
tiene `explanation` no vacía (invariantes 13 y 14 de
[contracts/content-pack.md](./contracts/content-pack.md)).

Manual: responder mal a propósito en cada tipo de ejercicio y leer la retroalimentación.

### SC-008 · Ejercicios orales aprobables con micrófono denegado y sonido apagado

Manual, y es la verificación del Principio VII. Denegar el permiso de micrófono:

```bash
adb shell pm revoke com.example.languages_app android.permission.RECORD_AUDIO
```

Silenciar el dispositivo, recorrer una lección completa y aprobarla usando únicamente las
alternativas accesibles. Repetir con el micrófono concedido pero sin red.

> El identificador `com.example.languages_app` es provisional
> ([issue #1](https://github.com/buildlark-dev/languages_app/issues/1)). Ajustar el comando
> cuando cambie.

### SC-009 · Nadie estudia un nivel sin haber aprobado el anterior, y ningún nivel sin contenido es accesible

Automático: `test/engine/progression_test.dart` recorre la matriz completa de transiciones
de estado de nivel y rechaza toda transición descendente o indebida.

Manual, dos frentes:

1. **Progresión**: intentar avanzar con el módulo anterior a medias y con el examen de nivel
   suspendido. Criterio: bloqueado, con el motivo explicado.
2. **Niveles anunciados**: A2 en adelante aparecen como "próximo · en preparación" y **no se
   puede entrar por ninguna ruta** — ni tocando la tarjeta, ni tras aprobar el examen de A1,
   ni mediante la nivelación. Criterio estructural: no existen como `Level`, así que no hay
   dato que pudiera representar la entrada.

### Nivelación · nivel estimado frente a nivel asignado

Manual, el camino que tu decisión sobre A2 hace relevante. Presentar la nivelación respondiendo
bien lo suficiente para que el estimado supere A1.

Criterio:

- la app informa el **nivel estimado** real (por ejemplo B1), sin rebajarlo ni ocultarlo;
- explica que el contenido de los niveles siguientes está en preparación;
- marca A1 como **dominado** y lo deja abierto para repaso;
- repasar A1 no cambia la marca de dominado ni el nivel estimado;
- la persona nunca queda sin nada que hacer: siempre se le ofrece repasar lo dominado.

### SC-010 · Usable a 360 dp con fuente del sistema al 130 %

Manual, y es el que más defectos saca. En el emulador:

```bash
adb shell wm size 360x800
```

```bash
adb shell settings put system font_scale 1.3
```

Recorrer **todas** las pantallas, con atención especial a las explicaciones gramaticales
largas y las tablas de conjugación. Restaurar después:

```bash
adb shell wm size reset
```

```bash
adb shell settings put system font_scale 1.0
```

### FR-047 a FR-049 · Accesibilidad: lector de pantalla, área táctil y contraste

Manual. SC-010 solo cubre tamaño y escala de fuente, así que la accesibilidad necesita su
propio paso.

Activar el lector de pantalla:

```bash
adb shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService
```

Recorrer una lección completa **solo escuchando**: todo control debe anunciarse con una
etiqueta que diga qué hace, no "botón" a secas. Comprobar además que ningún objetivo táctil
baja de 48 dp y que el contraste de texto cumple WCAG AA en modo claro **y** en oscuro, con
el inspector de accesibilidad de Flutter DevTools.

Desactivar al terminar:

```bash
adb shell settings put secure enabled_accessibility_services ""
```

### FR-045 y FR-046 · Respaldo: exportar, importar y borrar

Parcialmente automático: `test/services/backup/json_backup_service_test.dart` cubre la ida y
vuelta, el rechazo de una versión no soportada y el de un archivo corrupto.

Manual, y aquí está lo que de verdad importa comprobar:

1. Avanzar, exportar el respaldo, seguir avanzando, **importar el respaldo viejo**.
   Criterio: **no se pierde nada**. El progreso posterior sigue ahí, porque importar fusiona
   en lugar de reemplazar.
2. Importar un archivo corrupto. Criterio: mensaje claro y progreso intacto.
3. Borrar el progreso. Criterio: pide confirmación explícita, advierte que es irreversible y
   menciona el respaldo como única vuelta atrás.

### SC-011 · Añadir un idioma no toca el motor

Semiautomático, y es la verificación del Principio I. Crear un curso de prueba mínimo
(un nivel, un módulo) en `lib/content/xx/`, registrarlo en el catálogo y comprobar que
aparece y es recorrible. Luego:

```bash
git status --short lib/core lib/engine lib/services lib/ui
```

Criterio: salida vacía. Si algún archivo de esas cuatro capas cambió, el desacoplamiento
está roto. Descartar el curso de prueba al terminar.

`test/architecture/layer_dependencies_test.dart` cubre el lado estático: ningún archivo de
`engine` importa `content`, `ui` ni Flutter; ningún archivo de `content` importa `engine`,
`ui` ni `services`; ningún archivo de `core` importa nada de las otras capas.

### SC-012 · Racha correcta a lo largo de una semana

Automático: `test/engine/streak_tracker_test.dart`, usando el reloj inyectado
(`core/clock.dart`) para recorrer días sin esperar. Cubre racha consecutiva, salto de un
día, dos actividades el mismo día y cambio de mes.

Imposible de verificar manualmente en tiempo real: ese es precisamente el motivo del reloj
inyectado (D9 de research.md).

---

## Verificación de las reglas de seguridad

Obligatoria, con el emulador de Firestore:

```bash
firebase emulators:start --only firestore
```

Comprobar que una sesión autenticada **no** puede leer el documento de otro `uid`, y que
una petición sin sesión es rechazada. Una revisión visual de `firestore.rules` no sustituye
esta prueba.

---

## Despliegue web

Compilar:

```bash
flutter build web --release
```

Publicar:

```bash
firebase deploy --only hosting
```

El destino es `languages.buildlark.com`, subdominio de `www.buildlark.com`. El dominio
personalizado se añade una sola vez desde la consola de Firebase Hosting, que entrega los
registros DNS a configurar.

Antes de publicar: las puertas de calidad en verde, y la verificación de persistencia en
navegador (aprobar una lección, recargar con F5, comprobar que el progreso sigue ahí; es lo
que confirma que `sqlite3.wasm` y `drift_worker.js` están bien instalados).

---

## Diagnóstico

| Síntoma | Causa probable |
|---|---|
| No suena el audio en el emulador | Falta la voz en inglés en el motor TTS del sistema. `TtsService.initialize` debe devolver `languageMissing` y la app presentar el transcript |
| La pronunciación nunca reconoce nada | El emulador enruta el micrófono del equipo; verificar el micrófono del anfitrión, y si persiste, probar en dispositivo físico |
| `MissingPluginException` tras añadir un paquete | Detener la app por completo y volver a lanzarla: una recarga en caliente no registra plugins nativos |
| Error de Drift sobre código generado | Falta `dart run build_runner build --delete-conflicting-outputs` |
| En web el progreso no persiste | Faltan `sqlite3.wasm` o `drift_worker.js` en `web/` |
| Firestore rechaza la escritura | Reglas de seguridad, o sesión no iniciada; revisar el `uid` del token frente a la ruta |
