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

### Nota de gobernanza

La protección de rama sobre `main` quedó descartada por decisión del responsable del
proyecto. La regla de la constitución ("no se hace commit directo a la rama por
defecto") sigue vigente como convención sostenida por disciplina, sin refuerzo
mecánico. No se enmendó la constitución: la regla no cambió, solo su forma de
cumplimiento.
