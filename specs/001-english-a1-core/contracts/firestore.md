# Contract — Documento remoto, fusión y reglas de seguridad

**Feature**: `001-english-a1-core` | **Date**: 2026-10-06

Firestore es **destino de sincronización**, no fuente de verdad. La fuente de verdad es el
almacén local (ver [local-schema.md](./local-schema.md)).

**Su persistencia local queda desactivada**: dos cachés compitiendo producen estados
divergentes, y la de Firestore resuelve conflictos por última escritura gana, que es
exactamente lo que FR-039 prohíbe.

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

  "lessonResults": {
    "<lessonId>": number     // 0.0 a 1.0, el mejor obtenido
  },

  "examResults": {
    "<examId>": number
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
    "assignedLevelId":  string,
    "masteredLevelIds": [string],
    "skipped":          boolean,
    "takenAt":          timestamp
  },

  "updatedAt": timestamp
}
```

Todo son mapas con clave, nunca listas de objetos. Es deliberado: un mapa se fusiona por
clave sin ambigüedad, mientras que dos listas obligarían a emparejar elementos y a decidir
el orden. Esa elección de forma es lo que hace trivial la fusión.

`syncState` **no** aparece: es estado del dispositivo, no del estudiante.

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
veces la misma actividad. La especificación pidió el máximo (FR-039), y el máximo exige leer
antes de escribir. De ahí la transacción.

---

## Reglas de fusión

| Campo | Regla |
|---|---|
| `schemaVersion` | mayor |
| `currentLevelId` | el nivel más avanzado |
| `xp` | **máximo** |
| `streakCount` | **máximo** |
| `lastActivityDate` | más reciente |
| `levelStates[*]` | **máximo** del entero de estado |
| `lessonResults[*]` | **máximo** por clave, unión de claves |
| `examResults[*]` | **máximo** por clave, unión de claves |
| `reviewCards[*].intervalStep` | máximo |
| `reviewCards[*].dueDate` | **más próxima** |
| `reviewCards[*].lapses` | máximo |
| `reviewCards` | unión de claves |
| `placement` | el no nulo; si ambos, el de `takenAt` más reciente |

Todas son máximos sobre órdenes totales o uniones de conjuntos, así que la fusión es
conmutativa, asociativa e idempotente. Las consecuencias, verificadas en
`test/engine/progress_merger_test.dart`, están explicadas en
[data-model.md](../data-model.md#4-la-fusión-con-precisión).

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
