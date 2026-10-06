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
| `course` | `Course` | El curso completo, con sus niveles y módulos |
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

**Cuatro destrezas** (FR-014, FR-015)

10. Todo módulo contiene al menos un `ListeningExercise`.
11. Todo módulo contiene al menos un `PronunciationExercise`.
12. Todo módulo contiene al menos un ejercicio de producción escrita
    (`SentenceBuilderExercise` o `GapFillExercise`).

**Retroalimentación** (FR-024)

13. Todo ejercicio tiene `explanation` no vacía.
14. Toda `explanation` explica el motivo, no solo repite la respuesta. Se verifica de forma
    aproximada exigiendo una longitud mínima; la calidad la juzga la revisión humana.

**Accesibilidad** (FR-018, SC-008)

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

20. Si `placementTest` no es nulo, cada ejercicio declara el nivel MCER que discrimina, y
    el conjunto de niveles cubiertos es un subconjunto de los niveles del curso.

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
