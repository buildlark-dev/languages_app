# Specification Quality Checklist: Núcleo del curso de inglés A1

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-10-06
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

**Estado: 15 de 15 ítems pasan. Listo para `/speckit-plan`.**

### Iteración 1 — redacción inicial

- Se eliminaron referencias a rutas de código (`lib/content/en/`) de los requisitos
  funcionales, presentes en la descripción original. FR-008 expresa el mismo requisito
  como propiedad observable, verificable por SC-011 sin nombrar estructura de archivos.
- Se reformularon "360 dp" y "modo claro y oscuro" como requisitos de experiencia
  (FR-044, FR-045).
- La cantidad de módulos de A1 no venía en la descripción. Se fijó en cuatro a partir de
  la ruta de referencia ya validada, y se documentó en Assumptions.
- Quedaron 3 marcadores `[NEEDS CLARIFICATION]`, los tres de alcance.

### Iteración 2 — clarificaciones resueltas (2026-10-06)

Las tres preguntas se resolvieron con la opción C en cada caso. Consecuencias aplicadas
a la especificación:

**Destrezas orales completas (escucha + habla con micrófono)**

- Nueva Historia 4 (P2) con 6 escenarios de aceptación.
- Nuevos FR-013 a FR-019: audio offline, comprensión auditiva, ejercicios de
  pronunciación, permiso de micrófono explicado, alternativa accesible obligatoria y
  continuidad tras fallos de reconocimiento.
- Nuevo SC-008: el 100 % de los ejercicios orales se puede aprobar con micrófono denegado
  y sonido apagado. Esto hace cumplir el Principio VII ("el audio es apoyo, no
  requisito") de forma verificable.
- A1 ahora cubre las cuatro destrezas, con lo que el Principio III queda satisfecho sin
  deuda diferida.
- Nueva suposición: la pronunciación se juzga por reconocimiento de la frase objetivo, no
  por calidad fonética fina. Acento y entonación no se puntúan en A1.

**Cuenta obligatoria con sincronización en la nube**

- Nueva Historia 1 (P1) con 7 escenarios, incluida la recuperación en un segundo
  dispositivo.
- Nuevos FR-001 a FR-006 (ciclo de cuenta) y FR-036 a FR-039 (offline tras el primer
  inicio de sesión, sincronización automática y resolución de conflictos).
- **Conflicto detectado y resuelto**: SC-001 decía "sin crear cuenta ni configurar nada",
  incompatible con la decisión. Se reescribió a "crear su cuenta y estar respondiendo su
  primer ejercicio en menos de 3 minutos".
- **Tensión detectada y resuelta**: cuenta obligatoria contra funcionamiento sin
  conexión. Se acotó explícitamente: la conexión se exige **una sola vez**, en el
  registro o primer inicio de sesión; desde entonces el estudio es offline (FR-036,
  SC-003). El primer arranque sin red quedó como caso borde con mensaje claro y reintento
  (FR-004).
- **Riesgo cubierto**: la fusión de progreso entre dispositivos se especificó con una
  regla concreta y favorable al estudiante (FR-039) y un criterio verificable (SC-005),
  en lugar de dejarla al criterio de la implementación.

**Salto de niveles por nivelación**

- Historia 6 sube de P3 a P2: con el salto habilitado, la nivelación deja de ser un
  extra y pasa a determinar el estado inicial de toda la ruta.
- Nuevos FR-034 y FR-035: los niveles inferiores al asignado se marcan como dominados y
  quedan accesibles para repaso; repasarlos no altera el nivel asignado.
- FR-023 se ajustó para admitir el desbloqueo por nivelación como excepción explícita al
  bloqueo de A2, y SC-009 se reformuló en consecuencia.
- **Hueco cubierto**: en esta entrega solo A1 tiene contenido, así que quien sea ubicado
  más arriba llegaría a un nivel vacío. FR-035 y el escenario 5 de la Historia 6 exigen
  informar que el nivel está "en preparación" y ofrecer repaso, en lugar de mostrar una
  pantalla vacía. Queda registrado en Assumptions como estado transitorio aceptado.

### Iteración 3 — remediación tras `/speckit-analyze` (2026-10-06)

El análisis cruzado encontró 15 hallazgos: 1 CRITICAL, 3 HIGH, 7 MEDIUM, 4 LOW. Cero
duplicaciones. Resueltos:

**C1 · CRITICAL — FR-045 y FR-046 sin cobertura de diseño.** La exportación e importación de
respaldo es un MUST del Principio IV y no tenía ni contrato ni archivo. Se añadió
`BackupService` con formato versionado, validación previa (`BackupParseResult`) e importación
que **fusiona** en lugar de reemplazar, más `services/backup/` en el árbol, su prueba y su
paso de validación manual.

**F1 · HIGH — nivelación por encima de A1 inalcanzable.** Resuelto con decisión del
responsable del proyecto: A2 en adelante son **aviso de interfaz**. Se separó **nivel
estimado** (cualquier nivel MCER) de **nivel asignado** (el más alto con contenido), se añadió
`Course.upcomingLevelIds` en lugar de niveles vacíos —que violarían las invariantes 6 y 9— y
se reescribieron FR-034 a FR-038. El nivel asignado es **derivado, no almacenado**: el día que
exista A2, quien tenga estimado B1 pasa a estudiar ahí sin migración alguna.

**F2 · HIGH — SC-004 sin mecanismo.** Los seis disparadores de sincronización eran acciones
locales, así que un segundo dispositivo ocioso nunca se habría enterado; el propio quickstart
decía "recargar". Se añadió `SyncService.remoteChanges`, escucha en vivo del documento remoto,
y SC-004 ahora exige explícitamente que no haga falta recargar.

**F3 · HIGH — la fusión podía resucitar una racha caducada.** Fusionar por máximo daba "racha
de 7 días" a quien no estudió el martes ni el miércoles, incumpliendo FR-031 de forma
observable. FR-031 y las reglas de fusión ahora exigen fusionar la racha **junto a su fecha**,
como el par `(lastActivityDate, streakCount)`. La primera redacción decía «recalcular tras
fusionar», y al implementarlo resultó que eso rompe la asociatividad: el recálculo necesita la
fecha a la que pertenecía la racha mayor, y la fusión ya la descartó.

**V1 · MEDIUM** — accesibilidad sin verificación: nuevo paso de quickstart con TalkBack,
área táctil de 48 dp y contraste WCAG AA en ambos modos.

**U1 · MEDIUM** — nuevo FR-013: las preguntas de la lectura cuentan como ejercicios de la
lección y participan del umbral del 70 %; el vocabulario, la gramática y los ejemplos no se
puntúan. Antes colgaban del módulo y habrían quedado fuera de toda calificación.

**A1 · MEDIUM** — FR-014 ya no afirma el audio sin conexión de forma incondicional: lo
condiciona a que el dispositivo tenga voz en inglés, con la alternativa accesible como
respaldo.

**D1 · MEDIUM** — el plan declara dónde encaja `services` (`ui → services → engine → core`),
hueco que el Principio II no cubre. Pendiente de enmienda constitucional.

**U2 · MEDIUM** — regla de división de archivos de contenido, con la medición que la motiva:
el módulo de referencia ocupa ~5 KB, estimados en 250–450 líneas de Dart.

**A2 · MEDIUM** — FR-006 enumera ahora los campos permitidos (correo y contraseña) y prohíbe
el resto.

**D2 · MEDIUM** — `.gitignore` corregido: se quitaron `google-services.json` y
`GoogleService-Info.plist`, que son configuración pública de cliente y cuya exclusión rompía
la compilación Android de un clon nuevo.

**U3, F4, F5, A3 · LOW** — invariante 22 sobre orales en exámenes; `firebase_options.dart`,
`l10n.yaml` y `google-services.json` añadidos al árbol; glosario con "actividad", "nivel
estimado" y "nivel asignado"; metas de rendimiento marcadas como internas salvo SC-004.

**Consecuencia de numeración**: la especificación pasó de 46 a 49 requisitos funcionales por
las inserciones de FR-013 y FR-035 a FR-038. Se renumeró en bloque y se remapearon todas las
referencias cruzadas de los siete documentos de diseño.

### Nota de gobernanza

La protección de rama sobre `main` quedó descartada por decisión del responsable del
proyecto. La regla de la constitución ("no se hace commit directo a la rama por
defecto") sigue vigente como convención sostenida por disciplina, sin refuerzo
mecánico. No se enmendó la constitución: la regla no cambió, solo su forma de
cumplimiento.
