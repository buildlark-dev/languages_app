# Contract — Documento remoto, fusión y reglas de seguridad

**Feature**: `001-english-a1-core` | **Date**: 2026-10-06

Firestore es **destino de sincronización**, no fuente de verdad. La fuente de verdad es el
almacén local (ver [local-schema.md](./local-schema.md)).

**Su persistencia local queda desactivada**: dos cachés compitiendo producen estados
divergentes, y la de Firestore resuelve conflictos por última escritura gana, que es
exactamente lo que FR-042 prohíbe.

---

## Forma del documento

Ruta: `users/{uid}/courses/{courseId}`

```
{
  "schemaVersion":     number,
  "currentLevelId":    string,
  "xp":                number,
  "streakCount":       number,
  "lastActivityDate":  timestamp,

  "levelStates": {
    "A1": number,            // 0 locked · 1 unlocked · 2 mastered · 3 passed
    "A2": number
  },

  "activities": {
    "<activityId>": {
      "kind":         number,   // 0 lección · 1 examen de módulo · 2 examen de nivel
      "bestScore":    number,   // 0.0 a 1.0, el mejor obtenido
      "attempts":     number,
      "lastAttemptAt": string   // ISO 8601
    }
  },

  "reviewCards": {
    "<moduleId>|<term>": {
      "translation":  string,
      "intervalStep": number,   // 0 a 5
      "dueDate":      timestamp,
      "lapses":       number
    }
  },

  "placement": {
    "estimatedLevelId": string,     // cualquier nivel MCER, incluso sin contenido
    "masteredLevelIds": [string],   // solo niveles con contenido
    "skipped":          boolean,
    "takenAt":          timestamp
  },

  "updatedAt": timestamp
}
```

Todo son mapas con clave, nunca listas de objetos. Es deliberado: un mapa se fusiona por
clave sin ambigüedad, mientras que dos listas obligarían a emparejar elementos y a decidir
el orden. Esa elección de forma es lo que hace trivial la fusión.

**Corrección aplicada durante la implementación**: el diseño inicial separaba
`lessonResults` y `examResults`. Se unificaron en `activities` con la clase dentro de cada
entrada, porque el modelo necesita distinguir examen de módulo de examen de nivel —cada uno
tiene su umbral— y dos mapas solo codificaban «lección o examen». Una regla de fusión en
lugar de dos.

**Las fechas se guardan como texto ISO 8601**, no como `Timestamp` de Firestore. Así el
mismo mapa sirve como JSON de respaldo sin conversiones, que es lo que el contrato de
servicios pedía al decir que el respaldo reusa la forma del documento remoto.

`syncState` **no** aparece: es estado del dispositivo, no del estudiante.

`assignedLevelId` **no** aparece: es un valor derivado del nivel estimado contra el catálogo
vigente. Almacenarlo lo convertiría en una verdad que envejece: cuando se publique el
contenido de A2, quien tenga `estimatedLevelId: B1` debe pasar a estudiar en A2 sin ninguna
migración, y eso solo funciona si el valor se recalcula en cada arranque.

El contenido didáctico **no** aparece: va compilado en la app.

---

## Protocolo de escritura

Una sola operación permitida, siempre dentro de una transacción de Firestore:

```
transacción:
  remoto  ← leer(users/{uid}/courses/{courseId})
  si remoto es nulo:
      escribir(local)
  si no:
      fusionado ← progress_merger.merge(local, remoto)
      escribir(fusionado)
  devolver lo escrito
```

El llamador escribe en la base local lo devuelto, de modo que ambos lados quedan iguales.

**Nunca** hay un `set` directo. `SyncService` no expone ninguna operación de reemplazo, para
que ni por descuido se pueda perder progreso.

Firestore no ofrece un `max` sobre campos —solo `increment`— y `increment` sería **erróneo**
aquí: si dos dispositivos incrementaran el XP de forma independiente, el total contaría dos
veces la misma actividad. La especificación pidió el máximo (FR-042), y el máximo exige leer
antes de escribir. De ahí la transacción.

---

## Protocolo de lectura en vivo

Mientras la app está en primer plano se mantiene una suscripción al documento
(`SyncService.remoteChanges`). Cada emisión se fusiona con el estado local mediante la misma
función `progress_merger` y se escribe el resultado.

Sin esta suscripción, SC-004 sería incumplible: todos los disparadores de escritura son
acciones locales, así que un segundo dispositivo abierto y ocioso nunca se enteraría de nada
hasta que la persona lo reiniciara.

Desactivar la persistencia local de Firestore **no** afecta a esta suscripción: lo que se
desactiva es la segunda caché en disco, no la capacidad de escuchar cambios. Y como la
fusión es idempotente, volver a recibir algo ya fusionado no tiene efecto, de modo que no
hace falta llevar registro de qué emisión se procesó.

## Reglas de fusión

| Campo | Regla |
|---|---|
| `schemaVersion` | mayor |
| `currentLevelId` | el nivel más avanzado |
| `xp` | **máximo** |
| `streakCount` | máximo, y después recalculado contra `lastActivityDate` |
| `lastActivityDate` | más reciente |
| `levelStates[*]` | **máximo** del entero de estado |
| `activities[*].bestScore` | **máximo** por clave, unión de claves |
| `activities[*].attempts` | máximo |
| `activities[*].lastAttemptAt` | más reciente |
| `reviewCards[*].intervalStep` | máximo |
| `reviewCards[*].dueDate` | **más próxima** |
| `reviewCards[*].lapses` | máximo |
| `reviewCards` | unión de claves |
| `placement` | el no nulo; si ambos, el de `takenAt` más reciente |

Todas son máximos sobre órdenes totales o uniones de conjuntos, así que la fusión es
conmutativa, asociativa e idempotente.

**Caso especial de la racha**: `streakCount` y `lastActivityDate` se fusionan **juntos**,
como un par, no de forma independiente. Gana el par del dispositivo que estudió más
recientemente; en empate de fecha, la racha mayor.

Sin eso, fusionar resucitaría una racha que FR-032 obliga a reiniciar: racha 7 con última
actividad el lunes, más racha 1 del jueves, daría "racha de 7 días" para alguien que no
estudió el martes ni el miércoles.

Fusionarlos como par sigue siendo un máximo, ahora sobre el orden lexicográfico
`(lastActivityDate, streakCount)`, así que las tres propiedades se conservan. Un recálculo
posterior **no** habría servido: necesitaría la fecha a la que pertenecía la racha más alta,
dato que ya se pierde al fusionar, y eso rompería la asociatividad.

Las consecuencias, verificadas en `test/engine/progress_merger_test.dart`, están explicadas
en [data-model.md](../data-model.md#4-la-fusión-con-precisión).

La invariante que se comprueba y que resume todo:

> fusionar nunca devuelve un número menor ni un conjunto más pequeño que cualquiera de sus
> entradas.

**`dueDate` toma la más próxima** y no la más lejana porque, ante la duda, se repasa antes:
repasar de más cuesta treinta segundos, no repasar lo que se estaba olvidando cuesta el
aprendizaje.

---

## Reglas de seguridad

Archivo `firestore.rules`, entregable de esta funcionalidad y no un ajuste de consola. Es
la pieza que de verdad protege los datos, no el hecho de que los archivos de configuración
de Firebase estén o no en el repositorio (ver D12 de research.md).

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Cada persona accede únicamente a su propio progreso.
    match /users/{uid}/courses/{courseId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == uid;
    }

    // Todo lo demás, denegado.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Obligaciones:

1. Sin sesión no hay lectura ni escritura.
2. Con sesión, solo el documento cuyo `uid` coincide con el del token.
3. Denegación por defecto para cualquier otra ruta: nada nuevo queda abierto por olvido.

**Verificación**: probar con el emulador de Firestore que una sesión autenticada **no**
puede leer el documento de otro `uid`, y que una petición sin sesión es rechazada. Es una
prueba obligatoria, no una revisión visual de las reglas.

---

## Costo y volumen

Un documento por estudiante y curso, de unos pocos kilobytes. Una lectura y una escritura
por sincronización, y la sincronización ocurre al iniciar sesión, al terminar una actividad,
al recuperar conexión y al pasar a segundo plano. Para un estudiante diario eso son unas
decenas de operaciones al día, holgadamente dentro del nivel gratuito de Firebase.

Si el volumen creciera, la vía es sincronizar por lotes con menor frecuencia, no cambiar el
protocolo de fusión.
