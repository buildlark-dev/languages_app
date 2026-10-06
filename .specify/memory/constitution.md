# Constitución de languages_app

Aplicación de aprendizaje de idiomas (inglés, francés y portugués al inicio, con más
idiomas por venir) construida en Flutter/Dart, que debe llevar a una persona
hispanohablante desde cero absoluto hasta hablar con fluidez el idioma que elija.
Esta constitución gobierna cómo se diseña, se escribe, se prueba y se publica ese
producto.

## Core Principles

### I. Contenido desacoplado del motor (NO NEGOCIABLE)

El motor de aprendizaje (lecciones, ejercicios, repetición espaciada, progreso,
exámenes) NO DEBE contener texto, vocabulario, gramática ni reglas de ningún idioma
concreto. Todo contenido vive en datos tipados por idioma (`lib/content/en/...`,
`lib/content/fr/...`, `lib/content/pt/...`) que implementan los mismos contratos Dart
definidos en `lib/core/`.

Reglas:

- Añadir un cuarto idioma DEBE ser posible registrando un nuevo paquete de contenido
  y una entrada en el catálogo de cursos, sin editar ningún archivo del motor ni de
  la interfaz. Si añadir un idioma obliga a tocar el motor, el diseño está mal y DEBE
  corregirse antes de continuar.
- Las particularidades de un idioma (géneros gramaticales, nasales, enlaces,
  conjugaciones) se modelan como campos opcionales del contrato común o como
  extensiones declarativas, NUNCA como condicionales `if (language == 'fr')` dentro
  del motor o de los widgets.
- Las cadenas de interfaz (botones, mensajes, errores) se separan del contenido
  didáctico y se internacionalizan. El idioma de la interfaz (español) y el idioma
  estudiado son dimensiones independientes.

Rationale: la intención declarada del producto es crecer en idiomas. Si el idioma se
filtra al motor, cada idioma nuevo multiplica el costo y el riesgo de regresión.

### II. Un archivo, una responsabilidad

Cada archivo `.dart` DEBE tener un propósito único, un nombre que lo declare y
dependencias explícitas por `import`. Está prohibido el archivo monolítico: ningún
archivo de producción DEBERÍA superar ~300 líneas, y al superar ese umbral se parte
antes de añadir más funcionalidad.

Reglas:

- Nombres en `snake_case` descriptivo del rol: `main.dart`, `level_a1.dart`,
  `lesson_screen.dart`, `srs_scheduler.dart`, `vocabulary_card_widget.dart`.
- Un widget público por archivo. Los widgets auxiliares privados (`_Algo`) pueden
  acompañar al principal solo si existen únicamente para él.
- Carpetas por capa y responsabilidad: `lib/core/` (modelos y contratos),
  `lib/engine/` (lógica de aprendizaje), `lib/ui/` (pantallas y widgets),
  `lib/content/<codigo_idioma>/` (datos didácticos), `lib/services/` (persistencia,
  audio, Firebase).
- El sentido de las dependencias es `ui → engine → core` y `content → core`. Ninguna
  flecha en sentido contrario: `core` no importa `ui`, el motor no importa contenido
  concreto.

Rationale: el requisito explícito es poder abrir un archivo y saber qué hace sin leer
todo el proyecto de corrido; esa navegabilidad solo se sostiene si la regla es
estructural, no una buena intención.

### III. Rigor pedagógico verificable (MCER)

El producto no es una colección de ejercicios sueltos: es una ruta. Cada nivel DEBE
declararse contra el Marco Común Europeo de Referencia (A1, A2, B1, B2, C1, C2) y
cada módulo DEBE declarar su objetivo funcional en formato "puedo hacer X" (can-do),
como en las rutas de referencia de `Study/`.

Reglas:

- Todo módulo contiene, como mínimo: vocabulario con traducción, explicación
  gramatical en español, ejemplos bilingües, comprensión lectora con preguntas
  razonadas, producción (construir frases y rellenar huecos) y retroalimentación que
  explique *por qué* una respuesta es correcta o incorrecta.
- Los umbrales de dominio son explícitos y uniformes: aprobar lección ≥ 70 %,
  aprobar módulo o examen de nivel ≥ 80 %. No se desbloquea el nivel siguiente sin
  aprobar el examen del nivel actual.
- La ruta DEBE cubrir las cuatro destrezas (escuchar, leer, hablar, escribir). Un
  nivel que solo ejercite reconocimiento pasivo está incompleto y no puede declararse
  terminado.
- Existe una prueba de nivelación inicial para no obligar a un falso principiante a
  empezar en A1.
- El contenido de cada idioma DEBE contrastarse con una fuente de referencia (las
  rutas existentes en `Study/`, o material MCER/CLB/NCLC/CELPIP equivalente) antes de
  publicarse. No se inventa gramática.

Rationale: la promesa es llegar a fluidez, no a entretenimiento. Un criterio de
progresión explícito y medible es lo que distingue una ruta de un juego de preguntas.

### IV. El progreso del estudiante es sagrado

La app DEBE funcionar sin conexión para estudiar y DEBE preservar el progreso ante
cualquier fallo.

Reglas:

- Toda lección, vocabulario y ejercicio ya descargado se puede completar sin red.
- El progreso (nivel, módulos aprobados, cola de repetición espaciada, XP, racha) se
  escribe en almacenamiento local de forma atómica y se sincroniza con la nube cuando
  haya red. Si falla el almacenamiento local, se degrada a memoria y se avisa al
  usuario; NUNCA se falla en silencio.
- El esquema de datos persistidos lleva número de versión, y cada cambio de esquema
  DEBE traer una migración que preserve el progreso existente. Está prohibido
  publicar un cambio que borre o invalide datos de estudiantes.
- Existe exportación e importación de copia de seguridad accesible al usuario.
- La repetición espaciada es parte del contrato del producto: el vocabulario visto
  vuelve a aparecer con intervalos crecientes (base de referencia: 1, 3, 7, 16, 35 y
  90 días) y un fallo reinicia el intervalo.

Rationale: perder una racha de 60 días es la forma más rápida de perder a un
estudiante; el valor acumulado del usuario pesa más que cualquier funcionalidad nueva.

### V. Sin prueba no está terminado

Ninguna funcionalidad se declara completa sin verificación ejecutada y reportada.

Reglas:

- `flutter analyze` DEBE terminar sin errores ni advertencias nuevas antes de cada
  commit.
- Toda lógica del motor (puntuación, desbloqueo de niveles, planificador de
  repetición espaciada, migraciones) DEBE tener pruebas unitarias en `test/`, en
  archivos espejo del código que prueban
  (`test/engine/srs_scheduler_test.dart`).
- Toda pantalla nueva o modificada DEBE tener al menos una prueba de widget que
  verifique su render y su interacción principal.
- Toda pantalla DEBE verificarse además en el emulador de Android antes de darse por
  terminada, y el reporte DEBE decir qué se vio. Si una prueba falla o se omite, se
  dice explícitamente; está prohibido reportar "listo" sobre trabajo no verificado.

Rationale: una app educativa que calcula mal el progreso o rompe el desbloqueo de
niveles destruye la confianza del estudiante, y esos errores son invisibles sin
pruebas.

### VI. Código didáctico y socializado

Este proyecto tiene dos entregables: la app y el aprendizaje de quien la dirige.

Reglas:

- Cada entrega de código DEBE explicarse en el chat, en español, cubriendo: qué hace
  el archivo, por qué se eligió ese enfoque, qué concepto de Dart o Flutter aparece
  en él (`StatelessWidget` frente a `StatefulWidget`, `Future`/`async`, `const`,
  gestión de estado) y cómo se conecta con los archivos que lo rodean.
- El código fuente, los nombres y los identificadores van en inglés; los comentarios
  y la explicación del chat van en español. El contenido visible al estudiante va en
  español (interfaz) más el idioma estudiado.
- Las decisiones de arquitectura no triviales se registran brevemente en el documento
  de plan correspondiente, no solo en el chat.
- Las explicaciones describen el código tal como quedó. Está prohibido explicar
  comportamiento que el código no tiene.

Rationale: el usuario declaró el aprendizaje como objetivo explícito; entregar código
sin explicarlo incumple la mitad del encargo.

### VII. Móvil primero y accesible

La experiencia de referencia es un teléfono en la mano, y la app también se publica en
web.

Reglas:

- Los diseños DEBEN funcionar desde 360 dp de ancho sin desbordes ni recortes, y
  adaptarse a tablet y web sin layouts duplicados.
- Nada de medidas fijas en píxeles para estructuras de pantalla: se usan widgets
  adaptativos (`LayoutBuilder`, `Flexible`, `SafeArea`) y se respeta el tamaño de
  fuente del sistema.
- Objetivos táctiles de al menos 48×48 dp, contraste de texto conforme a WCAG AA y
  etiqueta semántica en todo elemento interactivo para lectores de pantalla.
- El audio es apoyo, no requisito: todo ejercicio de escucha o pronunciación DEBE
  tener alternativa accesible para quien no pueda usar micrófono o altavoz.
- Soporte de modo claro y oscuro desde el primer día.

Rationale: la competencia directa se usa en el bus, con una mano y a veces sin
audífonos; una interfaz que falla en esas condiciones no se usa.

## Restricciones Técnicas y de Despliegue

Stack obligatorio:

- Lenguaje Dart, framework Flutter, entorno Visual Studio Code. El proyecto vive en
  `C:\Users\PC\Desktop\Developing\languages_app` y se mantiene el SDK declarado en
  `pubspec.yaml` (`sdk: ^3.12.2`).
- Plataformas objetivo: Android y Web como primarias. iOS, Windows, macOS y Linux se
  mantienen compilables pero no bloquean entregas.
- Dependencias: cada paquete nuevo de `pubspec.yaml` DEBE justificarse en el plan de
  la funcionalidad que lo necesita. Se prefiere la biblioteca estándar de Flutter
  frente a una dependencia externa.

Despliegue:

- El destino de publicación es Firebase Hosting, servido en `languages.buildlark.com`
  como subdominio de `www.buildlark.com`.
- No se publica una versión que no pase las puertas de calidad de la sección
  siguiente.
- Las claves, los identificadores de proyecto y las credenciales de Firebase NO DEBEN
  escribirse en claro en el repositorio: se usan archivos de configuración ignorados
  por git o variables de entorno.

Repositorio:

- GitHub, con la identidad `support@buildlark.com` para commits, pull requests y
  pushes.
- Las ramas de trabajo siguen el patrón `<numero>-<nombre-corto>` que genera el flujo
  de Spec Kit. No se hace commit directo a la rama por defecto.
- Los mensajes de commit son descriptivos y en imperativo. Cada pull request enuncia
  qué principios de esta constitución ejercita y cómo se verificó.

## Flujo de Desarrollo y Puertas de Calidad

Orden de trabajo para toda funcionalidad nueva (Spec Kit):

1. `/speckit-specify` — especificación en términos de estudiante y resultado de
   aprendizaje.
2. `/speckit-plan` — diseño técnico, estructura de archivos y dependencias.
3. `/speckit-tasks` — descomposición en tareas ordenadas por dependencia.
4. `/speckit-implement` — implementación, con la explicación en el chat que exige el
   Principio VI.

Puertas de calidad, en orden, antes de cerrar una tarea:

1. `flutter analyze` sin errores ni advertencias nuevas.
2. `flutter test` en verde, con las pruebas unitarias y de widget que exige el
   Principio V.
3. Verificación visual en emulador de Android de las pantallas afectadas.
4. Revisión de cumplimiento constitucional: ¿el contenido sigue fuera del motor?
   ¿Algún archivo creció hasta volverse monolítico? ¿Hay migración para los datos
   persistidos que cambiaron?
5. Explicación didáctica entregada en el chat.
6. Commit y pull request con la identidad acordada.

Una tarea bloqueada no detiene las demás: se completa todo lo que no dependa del
bloqueo y se declara explícitamente qué quedó fuera y por qué.

## Governance

Esta constitución está por encima de cualquier otra práctica, preferencia de estilo o
costumbre heredada del código existente. Ante conflicto entre un principio y una
conveniencia de implementación, gana el principio.

Enmiendas:

- Cualquier cambio a este documento se hace por `/speckit-constitution`, con un Sync
  Impact Report al inicio del archivo y aprobación explícita del responsable del
  proyecto.
- Versionado semántico del documento: MAJOR al eliminar o redefinir un principio de
  forma incompatible; MINOR al añadir un principio o sección, o al ampliar
  materialmente una guía; PATCH para aclaraciones, redacción y correcciones sin
  cambio de significado.
- Una enmienda que invalide código ya escrito DEBE traer un plan de migración, no
  solo el texto nuevo.

Cumplimiento:

- Toda revisión de código y todo pull request DEBE verificar el cumplimiento de los
  siete principios. Un incumplimiento se corrige, o se documenta como excepción
  justificada y temporal con fecha de vencimiento.
- La complejidad adicional DEBE justificarse: a igualdad de resultado, se elige la
  solución más simple.
- Las convenciones operativas del día a día (comandos, rutas, atajos) se mantienen en
  `CLAUDE.md` en la raíz del repositorio. Ese archivo guía la ejecución, pero nunca
  contradice esta constitución.

**Version**: 1.0.0 | **Ratified**: 2026-10-06 | **Last Amended**: 2026-10-06
