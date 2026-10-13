<!--
  La constitución pide dos cosas de cada pull request: que enuncie qué
  principios ejercita y cómo se verificó. Esta plantilla existe para que eso
  salga solo, en lugar de depender de que alguien se acuerde — que es lo que
  falló con el PR #2, cuya descripción siguió diciendo «No application code
  yet» durante treinta y tantos commits.

  Borra las secciones que no apliquen. Una plantilla que obliga a rellenar
  casillas vacías se acaba rellenando en falso, y entonces no verifica nada.
-->

## What this changes

<!-- Dos o tres líneas: qué hace distinto la app después de esto, no qué
     archivos se tocaron. El diff ya dice los archivos. -->

## Why

<!-- El problema que resuelve. Si viene de un fallo observado, la evidencia:
     el mensaje de error, la medición, los pasos para reproducirlo. Una causa
     medida vale más que una explicada. -->

## How it was verified

- [ ] `flutter analyze` — sin errores ni advertencias
- [ ] `flutter test` — en verde (N pruebas)
- [ ] Pantallas afectadas abiertas y revisadas a mano
- [ ] Comprobado en el despliegue, si el cambio toca web o el despliegue

<!-- Principio V: si una prueba falla o se omite, se dice explícitamente.
     Está prohibido reportar «listo» sobre trabajo no verificado, así que
     escribe aquí qué NO se comprobó y por qué. -->

## Constitution

<!-- Marca solo los que este cambio ejercita de verdad, y di cómo se
     demuestra. «Lo cumple» sin prueba no es una respuesta. -->

| | Principio | Cómo se demuestra en este PR |
|---|---|---|
| ☐ | I — Contenido desacoplado del motor | |
| ☐ | II — Un archivo, una responsabilidad | |
| ☐ | III — Rigor pedagógico verificable | |
| ☐ | IV — El progreso del estudiante es sagrado | |
| ☐ | V — Sin prueba no está terminado | |
| ☐ | VI — Código didáctico y socializado | |
| ☐ | VII — Móvil primero y accesible | |

## Known limitations

<!-- Lo que queda fuera, lo que se degradó a propósito y lo que no se pudo
     comprobar. Declararlo aquí es parte del trabajo: un límite escrito es una
     decisión; un límite callado es una sorpresa para quien lo encuentre. -->
