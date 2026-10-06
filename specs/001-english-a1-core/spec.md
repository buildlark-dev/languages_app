# Feature Specification: Núcleo del curso de inglés A1

**Feature Branch**: `001-english-a1-core`

**Created**: 2026-10-06

**Status**: Draft

**Input**: User description: "Núcleo del curso de inglés nivel A1: primera funcionalidad vertical de la app. Un estudiante hispanohablante elige el idioma (inglés), hace una prueba de nivelación opcional, y recorre los módulos del nivel A1 completando lecciones con vocabulario, explicación gramatical en español, ejemplos bilingües, comprensión lectora con preguntas razonadas y ejercicios de producción (construir frases y rellenar huecos). El progreso se guarda localmente y funciona sin conexión; el vocabulario visto entra en una cola de repetición espaciada con intervalos crecientes (1, 3, 7, 16, 35, 90 días). Umbrales: aprobar lección >= 70%, aprobar módulo o examen de nivel >= 80%; el nivel A2 no se desbloquea sin aprobar el examen de A1. Debe mostrar XP y racha diaria. La arquitectura debe dejar el contenido de inglés en lib/content/en/ desacoplado del motor, de modo que francés y portugués se añadan después sin tocar el motor. Interfaz en español, móvil primero desde 360 dp, con modo claro y oscuro. Referencia de contenido y estructura ya validada: Study/ruta-de-ingles.html (niveles A1-C1 con módulos que llevan vocabulario, gramática, lectura, construir frases y huecos)."

**Decisiones de alcance resueltas** (2026-10-06): esta entrega cubre las cuatro
destrezas, incluida pronunciación con micrófono; requiere cuenta de usuario desde el
inicio con sincronización en la nube; y la prueba de nivelación permite saltar niveles,
marcando el contenido omitido como dominado y disponible para repaso.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Crear cuenta, entrar y recuperar el progreso en otro dispositivo (Priority: P1)

Una persona abre la app por primera vez, crea su cuenta y entra. Estudia, acumula
progreso, y más tarde instala la app en otro dispositivo; al entrar con la misma cuenta
encuentra su progreso tal como lo dejó. Si pierde el teléfono, no pierde su avance.

**Why this priority**: La cuenta es la puerta de entrada a todo lo demás y el soporte de
la promesa de no perder el progreso. Sin ella no hay sesión, no hay sincronización y no
hay nada que recuperar.

**Independent Test**: Se puede probar de forma aislada creando una cuenta, registrando
algo de actividad, entrando con esa misma cuenta en un segundo dispositivo y
comprobando que el estado coincide.

**Acceptance Scenarios**:

1. **Given** una persona que abre la app por primera vez, **When** crea su cuenta con
   los datos requeridos, **Then** entra a la app y puede elegir el idioma a aprender.
2. **Given** una cuenta ya existente, **When** la persona entra con sus credenciales,
   **Then** recupera su progreso y continúa donde lo dejó.
3. **Given** credenciales incorrectas, **When** la persona intenta entrar, **Then**
   recibe un mensaje claro de qué falló y cómo recuperar el acceso, sin perder lo que
   escribió.
4. **Given** una persona que olvidó su contraseña, **When** solicita restablecerla,
   **Then** recibe instrucciones para hacerlo y puede volver a entrar.
5. **Given** progreso hecho en un dispositivo, **When** la persona entra con la misma
   cuenta en otro dispositivo con conexión, **Then** ve el mismo nivel, los mismos
   módulos aprobados, el mismo XP y la misma cola de repaso.
6. **Given** una sesión ya iniciada, **When** la persona vuelve a abrir la app,
   **Then** entra directamente sin tener que autenticarse de nuevo.
7. **Given** una sesión iniciada con progreso sin sincronizar, **When** la persona pide
   cerrar sesión, **Then** la app le advierte qué quedaría sin respaldar y le pide
   confirmación explícita.

---

### User Story 2 - Completar una lección y ver que el progreso quedó guardado (Priority: P1)

La persona entra al primer módulo de A1 ("Identidad y saludos") y completa su primera
lección: repasa el vocabulario con su traducción, lee la explicación gramatical en
español, revisa ejemplos bilingües y resuelve los ejercicios de comprensión y
producción. Al terminar ve su puntaje, si aprobó y cuánto XP ganó. Cierra la app por
completo y al volver encuentra la lección aprobada y su XP intacto.

**Why this priority**: Es la unidad mínima de valor del producto. Sin una lección que se
pueda completar y cuyo resultado sobreviva al cierre de la app, no hay producto: hay una
maqueta. Todo lo demás se apoya en este ciclo.

**Independent Test**: Se puede probar de forma aislada completando una sola lección y
reiniciando la app para comprobar que el estado persiste. Entrega valor real: la persona
ya aprendió y practicó contenido de inglés.

**Acceptance Scenarios**:

1. **Given** una persona autenticada que elige inglés, **When** se abre la ruta,
   **Then** ve los módulos de A1 con solo el primero disponible.
2. **Given** una lección abierta con sus ejercicios, **When** responde correctamente al
   menos el 70 % de los ítems, **Then** la lección queda aprobada y se le suma XP.
3. **Given** una lección abierta, **When** responde correctamente menos del 70 % de los
   ítems, **Then** la lección queda sin aprobar, se le muestra qué falló y por qué, y
   puede reintentarla.
4. **Given** una lección ya aprobada, **When** la persona cierra la app por completo y
   la vuelve a abrir, **Then** la lección sigue aprobada y el XP acumulado es el mismo.
5. **Given** un ejercicio respondido de forma incorrecta, **When** se muestra la
   corrección, **Then** la explicación dice *por qué* la respuesta correcta lo es, no
   solo cuál era.
6. **Given** una lección a medias, **When** la app se cierra de forma inesperada,
   **Then** al volver la lección se trata como no presentada y no como fallada.

---

### User Story 3 - Avanzar por los módulos de A1 y desbloquear el siguiente nivel (Priority: P1)

La persona completa las lecciones de un módulo, aprueba el examen del módulo y
desbloquea el siguiente. Al aprobar los cuatro módulos de A1 presenta el examen del
nivel; si lo aprueba, A1 queda superado y A2 desbloqueado. Si no, A2 sigue cerrado y
puede reintentar.

**Why this priority**: Es lo que convierte una colección de lecciones en una ruta con
progresión. Sin desbloqueos y exámenes, la persona no tiene forma de saber si domina el
nivel, que es la promesa central del producto.

**Independent Test**: Se puede probar de forma aislada recorriendo A1 de principio a fin
y verificando que las puertas de módulo y de nivel se abren y cierran según el umbral
del 80 %.

**Acceptance Scenarios**:

1. **Given** un módulo con todas sus lecciones aprobadas, **When** la persona aprueba
   el examen del módulo con al menos 80 %, **Then** el módulo queda aprobado y el
   siguiente queda disponible.
2. **Given** un examen de módulo, **When** obtiene menos de 80 %, **Then** el módulo
   sigue sin aprobar, el siguiente permanece bloqueado y puede reintentar.
3. **Given** un módulo bloqueado, **When** la persona intenta abrirlo, **Then** la app
   le indica qué debe aprobar antes y no le permite entrar.
4. **Given** los cuatro módulos de A1 aprobados, **When** la persona aprueba el examen
   de nivel con al menos 80 %, **Then** A1 queda superado y A2 desbloqueado.
5. **Given** los cuatro módulos de A1 aprobados, **When** obtiene menos de 80 % en el
   examen de nivel, **Then** A2 permanece bloqueado y puede reintentarlo.
6. **Given** un módulo ya aprobado, **When** la persona lo reintenta y obtiene un
   puntaje peor, **Then** el módulo sigue aprobado y se conserva su mejor puntaje.

---

### User Story 4 - Escuchar y pronunciar en inglés (Priority: P2)

La persona escucha cómo se pronuncia cada palabra y cada frase de ejemplo, y practica
diciéndolas en voz alta: la app la escucha por el micrófono y le dice si lo que dijo se
entendió como la frase objetivo. Además resuelve ejercicios de comprensión auditiva
donde escucha un audio y responde sobre lo que oyó. Si no puede o no quiere usar
micrófono o altavoz, tiene una alternativa para completar la lección igual.

**Why this priority**: Es lo que convierte A1 en un nivel completo: sin escucha y habla,
la persona reconoce inglés escrito pero no lo entiende ni lo produce al hablar, y la
constitución no admite declarar un nivel terminado así. Va después de P1 porque necesita
que el ciclo de lección ya funcione.

**Independent Test**: Se puede probar de forma aislada reproduciendo el audio de un
módulo, grabando una frase y verificando la calificación, y recorriendo la ruta
alternativa con el micrófono denegado.

**Acceptance Scenarios**:

1. **Given** un ítem de vocabulario o un ejemplo, **When** la persona pide escucharlo,
   **Then** oye su pronunciación en inglés, y lo logra también sin conexión.
2. **Given** un ejercicio de pronunciación, **When** la persona dice la frase objetivo y
   se la entiende, **Then** el ejercicio cuenta como acierto y recibe la
   retroalimentación correspondiente.
3. **Given** un ejercicio de pronunciación, **When** lo que dice no corresponde a la
   frase objetivo, **Then** se le indica qué se entendió y qué se esperaba, y puede
   reintentar.
4. **Given** un ejercicio de pronunciación, **When** la persona no concede permiso de
   micrófono o el dispositivo no tiene uno, **Then** la app le ofrece una alternativa
   equivalente y la lección se puede aprobar sin usar micrófono.
5. **Given** varios intentos de pronunciación fallidos seguidos, **When** la persona
   quiere seguir, **Then** puede continuar la lección sin quedar atrapada en el
   ejercicio.
6. **Given** un ejercicio de comprensión auditiva, **When** la persona escucha el audio,
   **Then** puede repetirlo y responder las preguntas sobre lo que oyó.

---

### User Story 5 - Repasar vocabulario con repetición espaciada (Priority: P2)

El vocabulario que la persona ya vio entra en una cola de repaso. Cada día la app le
indica cuántas palabras tiene pendientes y le presenta una sesión corta donde califica
si recordó cada una. Las que recordó vuelven más tarde; las que falló vuelven al día
siguiente.

**Why this priority**: Es el mecanismo que convierte la exposición en memoria a largo
plazo y el que la trae de vuelta cada día. Sin él la app enseña pero no consolida.
Requiere contenido ya visto, por eso va tras P1.

**Independent Test**: Se puede probar de forma aislada completando una lección para
sembrar la cola y verificando que las palabras aparecen y que su próxima fecha cambia
según la calificación.

**Acceptance Scenarios**:

1. **Given** una lección completada con vocabulario nuevo, **When** la persona vuelve a
   la pantalla principal, **Then** ve cuántas palabras tiene pendientes de repaso.
2. **Given** una palabra en repaso, **When** la persona indica que la recordó, **Then**
   su siguiente revisión se programa a un intervalo mayor, siguiendo la secuencia 1, 3,
   7, 16, 35 y 90 días.
3. **Given** una palabra en repaso, **When** indica que no la recordó, **Then** su
   intervalo se reinicia y vuelve a aparecer al día siguiente.
4. **Given** una cola sin palabras vencidas hoy, **When** la persona abre el repaso,
   **Then** la app le confirma que está al día en lugar de mostrar una sesión vacía.

---

### User Story 6 - Ubicarse con la prueba de nivelación y saltar lo que ya domina (Priority: P2)

Una persona que ya sabe inglés no quiere repetir lo que domina. Al elegir el idioma
presenta una prueba de nivelación corta y opcional. Si el resultado la ubica por encima
de A1, los niveles anteriores quedan marcados como dominados, abiertos para repasarlos
cuando quiera, y empieza en el nivel que le corresponde.

**Why this priority**: Evita el abandono de quien no es principiante absoluto, y con el
salto habilitado se vuelve la puerta de entrada real de ese público. Sube a P2 porque la
decisión de saltar afecta el estado inicial de progreso de toda la ruta.

**Independent Test**: Se puede probar de forma aislada presentando la prueba con
distintos patrones de respuesta y verificando el nivel asignado, qué quedó marcado como
dominado y que lo marcado sigue accesible para repaso.

**Acceptance Scenarios**:

1. **Given** una persona que acaba de elegir inglés, **When** se le ofrece la prueba,
   **Then** puede omitirla y empezar en A1 desde el primer módulo.
2. **Given** la prueba presentada, **When** la persona responde mal la mayoría de los
   ítems básicos, **Then** queda ubicada en A1 desde el primer módulo.
3. **Given** la prueba completada, **When** el resultado la ubica por encima de A1,
   **Then** los niveles por debajo del asignado quedan marcados como dominados, el nivel
   asignado queda desbloqueado y empieza ahí.
4. **Given** un nivel marcado como dominado por la nivelación, **When** la persona lo
   abre, **Then** puede repasar sus módulos y lecciones sin que eso altere su nivel
   asignado.
5. **Given** un nivel asignado por la nivelación que todavía no tiene contenido en esta
   entrega, **When** la persona entra, **Then** la app le dice explícitamente que ese
   nivel está en preparación y le ofrece repasar lo que quedó marcado como dominado, sin
   dejarla en una pantalla vacía.
6. **Given** una persona que ya tiene progreso registrado, **When** vuelve a la pantalla
   de inicio, **Then** no se le vuelve a ofrecer la prueba de nivelación de forma
   intrusiva.

---

### User Story 7 - Mantener la racha diaria y ver el progreso acumulado (Priority: P3)

La persona ve cuántos días consecutivos ha estudiado y cuánto XP acumuló. Si estudia
hoy, la racha sube; si deja pasar un día completo, se reinicia. Puede consultar una
pantalla de progreso con su avance por módulo y por nivel.

**Why this priority**: Es el motor de hábito y la señal de avance que sostiene la
constancia, pero el producto enseña igual sin él. Depende de que exista actividad que
medir.

**Independent Test**: Se puede probar de forma aislada registrando actividad en días
distintos y verificando el contador de racha y el porcentaje de avance.

**Acceptance Scenarios**:

1. **Given** una persona sin actividad previa, **When** completa su primera lección del
   día, **Then** su racha marca 1 día.
2. **Given** una racha de N días cuyo último estudio fue ayer, **When** estudia hoy,
   **Then** la racha marca N+1.
3. **Given** una racha cuyo último estudio fue hace dos días o más, **When** estudia hoy,
   **Then** la racha se reinicia en 1.
4. **Given** una racha ya contada hoy, **When** completa una segunda lección el mismo
   día, **Then** la racha no se incrementa dos veces.
5. **Given** progreso parcial en A1, **When** abre la pantalla de progreso, **Then** ve
   qué porcentaje del nivel lleva aprobado y cuántas palabras tiene en repaso.

---

### Edge Cases

- **Primer arranque sin conexión**: como la cuenta es obligatoria, una persona sin red no
  puede registrarse ni entrar la primera vez. La app MUST explicarlo con claridad y
  ofrecer reintentar, nunca quedarse en espera indefinida ni en una pantalla muerta.
- **Pérdida de conexión a mitad de la sesión**: tras el primer inicio de sesión, el
  estudio continúa sin red; la sincronización se reanuda sola al volver la conexión, sin
  pedirle nada a la persona.
- **La misma cuenta en dos dispositivos con progreso divergente**: al sincronizar se
  conserva el avance más favorable para la persona: el mejor puntaje de cada lección y
  examen, el XP y la racha más altos, y la unión de las colas de repaso tomando la fecha
  de vencimiento más próxima para cada palabra. Nunca se descarta progreso en silencio.
- **El almacenamiento del dispositivo falla o está lleno**: el progreso se degrada a
  memoria de la sesión y se avisa explícitamente de que no se está guardando. Nunca falla
  en silencio.
- **Permiso de micrófono denegado, revocado a mitad de sesión, o dispositivo sin
  micrófono**: todo ejercicio oral ofrece una alternativa que permite aprobar la lección.
- **Ruido ambiental o reconocimiento que falla repetidamente**: la persona puede
  continuar sin quedar atrapada en el ejercicio, y los fallos de reconocimiento no se
  cuentan como errores de contenido.
- **Audio sin conexión**: la pronunciación de vocabulario y ejemplos está disponible sin
  red; una lección no puede volverse incompletable por falta de conexión.
- **Dos veces el mismo día**: completar varias lecciones el mismo día suma XP pero no
  multiplica la racha.
- **Respuestas con variantes válidas**: en rellenar huecos más de una respuesta puede ser
  correcta (por ejemplo `is` y `'s`); todas las variantes declaradas cuentan como
  acierto, y las diferencias de mayúsculas o espacios sobrantes no penalizan.
- **Reintento de examen**: se conserva el mejor puntaje; un reintento peor no puede
  desaprobar un módulo ya aprobado.
- **Nivelación que ubica en un nivel sin contenido**: se informa que está en preparación y
  se ofrece repasar lo marcado como dominado.
- **Pantalla de 360 dp con fuente del sistema ampliada**: las explicaciones gramaticales
  largas y las tablas de conjugación siguen legibles y sin desbordes.
- **Cambio de modo claro a oscuro a mitad de una lección**: el estado de la lección no se
  reinicia.
- **Reinicio de progreso**: requiere confirmación explícita y se advierte que es
  irreversible.

## Requirements *(mandatory)*

### Functional Requirements

**Cuenta y acceso**

- **FR-001**: El sistema MUST requerir una cuenta de usuario para acceder al contenido
  de estudio.
- **FR-002**: El sistema MUST permitir crear una cuenta, iniciar sesión, cerrar sesión y
  restablecer la contraseña.
- **FR-003**: El sistema MUST mantener la sesión abierta entre aperturas de la app, de
  modo que la persona no tenga que autenticarse cada vez.
- **FR-004**: El sistema MUST explicar con un mensaje claro cualquier fallo de registro o
  de inicio de sesión, incluida la ausencia de conexión en el primer arranque, y MUST
  ofrecer reintentar sin perder lo ya escrito.
- **FR-005**: El sistema MUST advertir qué progreso quedaría sin respaldar y pedir
  confirmación explícita antes de cerrar sesión.
- **FR-006**: El sistema MUST tratar los datos de la cuenta como información personal:
  solo se solicita lo necesario para autenticar y sincronizar.

**Selección de idioma y catálogo**

- **FR-007**: El sistema MUST permitir elegir el idioma a aprender desde un catálogo de
  cursos, y MUST presentar inglés como disponible en esta entrega.
- **FR-008**: El sistema MUST estar estructurado de modo que agregar un idioma nuevo al
  catálogo no requiera modificar la lógica de aprendizaje ni las pantallas comunes.
- **FR-009**: El sistema MUST mostrar toda la interfaz en español, y MUST presentar el
  contenido del idioma estudiado en ese idioma con su apoyo en español.

**Estructura del contenido**

- **FR-010**: El sistema MUST organizar el curso en niveles del Marco Común Europeo de
  Referencia, y MUST entregar el nivel A1 completo con cuatro módulos: identidad y
  saludos, casa y ciudad, rutinas y horarios, y gustos y capacidades.
- **FR-011**: Cada módulo MUST declarar su objetivo funcional en formato "puedo hacer X",
  visible antes de empezarlo.
- **FR-012**: Cada módulo MUST incluir vocabulario con su traducción al español,
  explicación gramatical en español, ejemplos bilingües, un texto de lectura con
  preguntas de comprensión, ejercicios de construcción de frases y ejercicios de rellenar
  huecos.

**Destrezas orales**

- **FR-013**: El sistema MUST permitir escuchar la pronunciación en inglés de cada ítem
  de vocabulario y de cada ejemplo, y ese audio MUST estar disponible sin conexión.
- **FR-014**: El sistema MUST incluir, en cada módulo de A1, ejercicios de comprensión
  auditiva donde la persona escucha un audio y responde sobre lo que oyó, con la
  posibilidad de repetir el audio.
- **FR-015**: El sistema MUST incluir, en cada módulo de A1, ejercicios de pronunciación
  en los que la persona dice una frase objetivo y el sistema califica si lo dicho
  corresponde a esa frase.
- **FR-016**: El sistema MUST mostrar, al fallar un ejercicio de pronunciación, qué se
  entendió y qué se esperaba, y MUST permitir reintentar.
- **FR-017**: El sistema MUST solicitar el permiso de micrófono explicando para qué se
  usa, y MUST seguir funcionando si la persona lo niega.
- **FR-018**: El sistema MUST ofrecer, para todo ejercicio de escucha o de pronunciación,
  una alternativa accesible que permita aprobar la lección sin usar micrófono ni altavoz.
- **FR-019**: El sistema MUST permitir continuar la lección tras intentos de
  pronunciación fallidos, y los fallos de reconocimiento de voz MUST NOT contarse como
  errores de contenido.

**Evaluación y progresión**

- **FR-020**: El sistema MUST calificar cada lección y MUST considerarla aprobada con un
  70 % o más de respuestas correctas.
- **FR-021**: El sistema MUST considerar aprobado un examen de módulo o de nivel con un
  80 % o más de respuestas correctas.
- **FR-022**: El sistema MUST mantener bloqueado un módulo hasta que el anterior esté
  aprobado, y MUST explicar qué falta para desbloquearlo.
- **FR-023**: El sistema MUST mantener bloqueado el nivel A2 hasta que el examen de nivel
  de A1 esté aprobado, salvo cuando la prueba de nivelación lo haya desbloqueado según
  FR-034.
- **FR-024**: El sistema MUST mostrar, tras cada respuesta incorrecta, una explicación de
  por qué la respuesta correcta lo es.
- **FR-025**: El sistema MUST aceptar todas las variantes correctas declaradas en un
  ejercicio de rellenar huecos, y MUST ignorar diferencias de mayúsculas y espacios
  sobrantes al calificar.
- **FR-026**: El sistema MUST permitir reintentar lecciones y exámenes, y MUST conservar
  el mejor resultado obtenido sin degradar un módulo ya aprobado.

**Repetición espaciada**

- **FR-027**: El sistema MUST incorporar a una cola de repaso el vocabulario de cada
  módulo que la persona empieza.
- **FR-028**: El sistema MUST programar la siguiente revisión de cada palabra según
  intervalos crecientes de 1, 3, 7, 16, 35 y 90 días cuando la persona la recuerda, y
  MUST reiniciar el intervalo a 1 día cuando no la recuerda.
- **FR-029**: El sistema MUST mostrar en la pantalla principal cuántas palabras están
  vencidas hoy, y MUST indicar explícitamente cuando no hay ninguna pendiente.

**Motivación y progreso**

- **FR-030**: El sistema MUST otorgar XP por la actividad completada y MUST mostrar el XP
  acumulado.
- **FR-031**: El sistema MUST llevar una racha de días consecutivos con actividad, MUST
  incrementarla una sola vez por día y MUST reiniciarla cuando pasa un día completo sin
  actividad.
- **FR-032**: El sistema MUST ofrecer una pantalla de progreso con el porcentaje del
  nivel aprobado, los módulos superados y el tamaño de la cola de repaso.

**Nivelación**

- **FR-033**: El sistema MUST ofrecer una prueba de nivelación opcional al elegir el
  idioma, MUST permitir omitirla para empezar en A1 y MUST informar el nivel asignado al
  terminarla.
- **FR-034**: Cuando la nivelación asigne un nivel superior a A1, el sistema MUST marcar
  los niveles inferiores como dominados, MUST desbloquear el nivel asignado y MUST
  mantener los niveles dominados accesibles para repaso sin que repasarlos altere el
  nivel asignado.
- **FR-035**: Cuando el nivel asignado no tenga contenido disponible, el sistema MUST
  informarlo explícitamente y MUST ofrecer repasar el contenido marcado como dominado.

**Persistencia, funcionamiento sin conexión y sincronización**

- **FR-036**: El sistema MUST permitir completar lecciones, exámenes, audio y repasos sin
  conexión a internet, una vez iniciada la sesión por primera vez.
- **FR-037**: El sistema MUST conservar el progreso de la persona (nivel, módulos
  aprobados, cola de repaso, XP y racha) entre cierres y reaperturas de la app.
- **FR-038**: El sistema MUST sincronizar el progreso con la cuenta cuando haya conexión,
  sin requerir ninguna acción de la persona.
- **FR-039**: Al resolver diferencias entre dispositivos, el sistema MUST conservar el
  avance más favorable para la persona: el mejor puntaje de cada lección y examen, el XP
  y la racha más altos, y la unión de las colas de repaso con la fecha de vencimiento más
  próxima por palabra. El sistema MUST NOT descartar progreso en silencio.
- **FR-040**: El sistema MUST avisar explícitamente cuando no logre guardar el progreso,
  y MUST seguir usable durante esa sesión.
- **FR-041**: El sistema MUST versionar los datos guardados de modo que una versión futura
  de la app pueda leer el progreso creado por esta.
- **FR-042**: El sistema MUST permitir exportar e importar una copia de seguridad del
  progreso.
- **FR-043**: El sistema MUST pedir confirmación explícita antes de borrar el progreso.

**Presentación y accesibilidad**

- **FR-044**: El sistema MUST funcionar sin desbordes ni recortes en pantallas desde
  360 dp de ancho, y MUST respetar el tamaño de fuente configurado en el dispositivo.
- **FR-045**: El sistema MUST ofrecer modo claro y modo oscuro.
- **FR-046**: El sistema MUST exponer etiquetas descriptivas en todos los elementos
  interactivos para lectores de pantalla, y MUST usar objetivos táctiles de al menos
  48 dp.

### Key Entities

- **Cuenta de estudiante**: la identidad con la que la persona accede. Es el ancla del
  progreso sincronizado.
- **Curso**: un idioma ofrecido en el catálogo. Tiene nombre, idioma de estudio e idioma
  de apoyo, y agrupa niveles.
- **Nivel**: una etapa del Marco Común Europeo (A1 a C2). Tiene identificador, nombre,
  descripción, módulos y un examen de nivel. Conoce si está bloqueado, desbloqueado,
  superado o marcado como dominado por nivelación.
- **Módulo**: la unidad temática dentro de un nivel. Tiene orden, título, objetivo "puedo
  hacer X", vocabulario, explicación gramatical, ejemplos, lectura, ejercicios y un examen
  de módulo.
- **Ítem de vocabulario**: una palabra o expresión con su traducción al español, su forma
  pronunciable y una ayuda visual opcional.
- **Ejercicio**: un ítem evaluable. Tiene enunciado, tipo (opción múltiple, construcción
  de frase, rellenar huecos, comprensión auditiva, pronunciación), respuestas aceptadas,
  la explicación de por qué la correcta lo es y, cuando es oral, su alternativa accesible.
- **Examen**: un conjunto de ejercicios con umbral de aprobación del 80 %, asociado a un
  módulo o a un nivel.
- **Tarjeta de repaso**: la relación entre la persona y un ítem de vocabulario. Guarda en
  qué paso del intervalo está y cuándo vence su siguiente revisión.
- **Progreso del estudiante**: el estado acumulado. Guarda nivel actual, estado de cada
  nivel, lecciones y módulos aprobados con su mejor puntaje, XP, racha, último día con
  actividad, estado de sincronización y versión del esquema de datos.
- **Resultado de nivelación**: el nivel asignado por la prueba inicial, la fecha en que se
  obtuvo y qué niveles quedaron marcados como dominados.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Una persona que abre la app por primera vez puede crear su cuenta y estar
  respondiendo su primer ejercicio de inglés en menos de 3 minutos.
- **SC-002**: El 100 % del progreso registrado (lecciones aprobadas, XP, racha y cola de
  repaso) sobrevive al cierre completo de la app y al reinicio del dispositivo.
- **SC-003**: Tras el primer inicio de sesión, el flujo completo de estudio —incluido el
  audio de pronunciación— funciona con el dispositivo en modo avión, sin una sola pantalla
  bloqueada o vacía.
- **SC-004**: El progreso hecho en un dispositivo aparece en otro con la misma cuenta en
  menos de 30 segundos desde que hay conexión en ambos.
- **SC-005**: Ninguna combinación de progreso divergente entre dos dispositivos produce
  pérdida de avance: tras sincronizar, cada lección conserva su mejor puntaje.
- **SC-006**: Una persona puede completar una lección en 5 a 10 minutos, de modo que una
  sesión diaria quepa en un trayecto corto.
- **SC-007**: El 100 % de las respuestas incorrectas recibe una explicación de por qué la
  correcta lo es, verificable recorriendo todos los ejercicios de A1.
- **SC-008**: El 100 % de los ejercicios de escucha y de pronunciación se puede completar
  y aprobar con el micrófono denegado y el sonido apagado, usando la alternativa
  accesible.
- **SC-009**: Nadie llega al nivel A2 sin haber obtenido al menos 80 % en el examen de A1
  o sin haber sido ubicado ahí por la prueba de nivelación, verificable intentando todas
  las rutas de acceso.
- **SC-010**: Todas las pantallas se usan sin desbordes ni texto cortado a 360 dp de
  ancho y con el tamaño de fuente del sistema al 130 %.
- **SC-011**: Agregar un idioma nuevo al catálogo no exige modificar ningún archivo de la
  lógica de aprendizaje ni de las pantallas comunes, verificable añadiendo un curso de
  prueba con un solo módulo.
- **SC-012**: Una persona que estudia a diario durante una semana ve su racha en 7 sin
  interrupciones, y una que deja pasar un día la ve reiniciada en 1.

## Assumptions

- **Público objetivo**: personas hispanohablantes adultas, mayoritariamente principiantes
  absolutos en el idioma elegido. El español es el idioma de apoyo y de la interfaz.
- **Alcance del lanzamiento**: esta funcionalidad entrega únicamente el nivel A1 de
  inglés. Los niveles A2 a C2 y los idiomas francés y portugués quedan fuera, aunque la
  estructura debe admitirlos sin rediseño.
- **Cantidad de contenido**: A1 tiene cuatro módulos, cifra tomada de la ruta ya validada
  en `Study/ruta-de-ingles.html`, que mantiene cuatro módulos por nivel de A1 a C1.
- **Umbrales de aprobación**: 70 % para lecciones y 80 % para exámenes, heredados de la
  ruta de referencia y elevados a regla en la constitución del proyecto.
- **Intervalos de repaso**: la secuencia 1, 3, 7, 16, 35 y 90 días proviene de la misma
  ruta de referencia y se adopta sin recalibrar.
- **Fuente del contenido didáctico**: el vocabulario, la gramática, las lecturas y los
  ejercicios de A1 se derivan de `Study/ruta-de-ingles.html`, revisada previamente. No se
  inventa gramática nueva.
- **Cuenta obligatoria y primer arranque**: la cuenta exige conexión **una sola vez**, en
  el registro o el primer inicio de sesión. Desde entonces la app funciona sin red. Se
  asume que la persona tiene conexión en ese primer momento.
- **Nivelación por encima del contenido disponible**: en esta entrega solo A1 tiene
  contenido, así que quien sea ubicado en A2 o más arriba verá el nivel asignado "en
  preparación" y solo podrá repasar lo marcado como dominado. Se acepta como estado
  transitorio hasta que existan los niveles siguientes.
- **Calificación de la pronunciación**: se juzga si lo dicho se reconoce como la frase
  objetivo, no la calidad fonética fina. Acento y entonación no se puntúan en A1.
- **Un solo perfil por cuenta**: no se contemplan varios estudiantes compartiendo una
  misma cuenta, ni varios idiomas en curso simultáneo en esta entrega.
- **Sin elementos sociales**: tablas de clasificación, amigos, ligas y notificaciones push
  quedan fuera.
- **Sin monetización**: no hay suscripciones, compras ni límite de vidas o energía.
- **Día de la racha**: se cuenta por la fecha local del dispositivo. No se contempla
  manipulación del reloj del sistema.
- **Plataforma de verificación**: la entrega se valida en emulador de Android y en web;
  iOS y escritorio se mantienen compilables pero no se verifican visualmente.
