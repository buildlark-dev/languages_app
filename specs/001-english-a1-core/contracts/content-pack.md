# Contract — Paquete de contenido de un idioma

**Feature**: `001-english-a1-core` | **Date**: 2026-10-06

Este es el contrato que hace cumplible el Principio I. Añadir francés o portugués consiste
en implementarlo y registrarlo en el catálogo. Nada del motor ni de la interfaz cambia.

Definido en `lib/core/content_pack.dart`. El motor depende de este contrato; **nunca** de
una implementación concreta.

---

## Obligaciones del paquete

Un paquete de contenido debe exponer:

| Miembro | Tipo | Obligación |
|---|---|---|
| `courseId` | `String` | Código ISO del idioma, único en el catálogo |
| `course` | `Course` | El curso completo: niveles con contenido y niveles anunciados |
| `placementTest` | `Exam?` | Nulo si el idioma no ofrece nivelación |

Todo es `const` o construido en tiempo de compilación: no hay carga asíncrona, no hay
lectura de assets, no hay parseo. De ahí que el contenido funcione sin conexión sin que
nadie escriba código para lograrlo.

---

## Invariantes que el paquete debe cumplir

Verificadas por `test/content/<idioma>/<nivel>_integrity_test.dart`, que debe existir para
cada idioma añadido:

**Estructura**

1. `courseId` no vacío y único en el catálogo.
2. `course.levels` no vacío, con `id` del conjunto MCER y en orden ascendente.
3. Ningún `id` de módulo, lección, ejercicio o examen repetido en todo el curso.
4. Los `order` de los módulos de un nivel son consecutivos desde 1, sin huecos.

**Completitud pedagógica** (Principio III)

5. Todo módulo declara `canDo` no vacío.
6. Todo módulo tiene al menos 8 ítems de vocabulario, 3 ejemplos bilingües, una lectura con
   preguntas, y al menos una lección.
7. Toda lección tiene al menos 5 ejercicios.
8. Todo examen tiene al menos 10 ejercicios.
9. Todo nivel tiene su `levelExam`.

**Cuatro destrezas** (FR-015, FR-016)

10. Todo módulo contiene al menos un `ListeningExercise`.
11. Todo módulo contiene al menos un `PronunciationExercise`.
12. Todo módulo contiene al menos un ejercicio de producción escrita
    (`SentenceBuilderExercise` o `GapFillExercise`).

**Retroalimentación** (FR-025)

13. Todo ejercicio tiene `explanation` no vacía.
14. Toda `explanation` explica el motivo, no solo repite la respuesta. Se verifica de forma
    aproximada exigiendo una longitud mínima; la calidad la juzga la revisión humana.

**Accesibilidad** (FR-019, SC-008)

15. Todo `ListeningExercise` declara `transcriptFallback`.
16. Todo `PronunciationExercise` declara `writtenFallback`.

Las invariantes 15 y 16 están además garantizadas por el compilador: son parámetros
`required`. La prueba existe como red de seguridad ante un cambio futuro del tipo.

**Respuestas**

17. Todo `GapFillExercise` declara al menos una respuesta aceptada.
18. Las respuestas aceptadas se declaran en minúsculas y sin espacios al borde: la
    comparación las normaliza, pero declararlas limpias evita duplicados inútiles.
19. Todo `MultipleChoiceExercise` y `ListeningExercise` tiene `answerIndex` dentro del
    rango de `options`, y al menos 3 opciones.

**Nivelación**

20. Si `placementTest` no es nulo, cada ejercicio declara el nivel MCER que discrimina. Ese
    conjunto **puede incluir niveles sin contenido**: la prueba estima el nivel real de la
    persona, no el nivel al que la app puede llevarla. Se exige únicamente que sean
    identificadores MCER válidos.
21. Los niveles anunciados sin contenido se declaran en `course.upcomingLevelIds`: son
    identificadores MCER posteriores al último nivel con contenido, sin intersección con
    `course.levels`. **No** se declaran como `Level` vacíos, porque eso violaría las
    invariantes 6 y 9.

**Exámenes y destrezas orales**

22. Los exámenes de módulo y de nivel **pueden** incluir ejercicios de escucha y de
    pronunciación, y cuando los incluyen se les aplican las invariantes 15 y 16: su
    alternativa accesible es obligatoria. Un examen **no está obligado** a incluirlos, para
    que una persona sin micrófono no quede en desventaja en la evaluación que decide su
    paso de nivel.

---

## Registro en el catálogo

`lib/content/catalog.dart` expone la lista de paquetes disponibles. Es el **único** archivo
que importa implementaciones concretas de contenido, y `lib/main.dart` es el único que lo
importa a él.

Añadir un idioma es, exactamente:

1. Crear `lib/content/<idioma>/` con sus archivos de módulo.
2. Implementar el contrato en `<idioma>_course.dart`.
3. Añadir una línea al catálogo.
4. Crear su prueba de integridad.

## Organización de archivos de contenido

El Principio II pide no superar ~300 líneas por archivo. Un módulo completo roza ese límite:
el módulo de referencia en `Study/ruta-de-ingles.html` ocupa unos 5 KB, que en Dart con
parámetros nombrados, más `explanation` en todos los ejercicios y los nuevos de escucha y
pronunciación, se estiman en 250 a 450 líneas.

Regla adoptada: **un archivo por módulo mientras quepa; al pasar de 300 líneas, se divide
por tipo de material**, no por ejercicio individual:

```
a1_module1_identity.dart          ensambla el módulo
a1_module1_vocabulary.dart        lista de vocabulario
a1_module1_grammar.dart           explicación y ejemplos
a1_module1_exercises.dart         ejercicios de las lecciones
```

El archivo que ensambla queda corto y legible, que es el objetivo del principio: poder abrir
un archivo y saber qué contiene. Dividir por tipo de material mantiene además una
correspondencia clara con las invariantes de este contrato, porque cada archivo responde por
un grupo de ellas.

Lo que **no** cambia: `lib/core/`, `lib/engine/`, `lib/services/`, `lib/ui/`. SC-011 lo
verifica añadiendo un curso de prueba de un módulo y comprobando que no se modificó ningún
archivo de esas cuatro capas.

---

## Lo que el paquete no puede hacer

- **No** importar nada de `lib/engine/`, `lib/ui/` ni `lib/services/`. Solo `lib/core/`.
  Lo verifica `test/architecture/layer_dependencies_test.dart`.
- **No** contener lógica: ni calificar, ni programar repasos, ni decidir desbloqueos. Es
  datos. Si un idioma necesitara una regla de evaluación propia, se modela como un campo
  declarativo del contrato, nunca como código dentro del contenido.
- **No** contener cadenas de interfaz (botones, mensajes de error). Esas viven en
  `lib/app/l10n/`. El contenido lleva únicamente material didáctico.
- **No** asumir que el idioma de apoyo es el español: `supportLanguageTag` lo declara.
