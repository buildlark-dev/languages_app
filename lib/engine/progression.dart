/// Qué puede estudiar el estudiante ahora mismo, y qué le falta para lo demás.
///
/// Dos invariantes gobiernan este archivo:
///
/// * **Nunca se retrocede.** Toda transición de estado de nivel es ascendente, y
///   [applyLevelState] rechaza las descendentes en lugar de aplicarlas.
/// * **Un nivel sin contenido no se desbloquea jamás.** No es una comprobación
///   añadida: los niveles anunciados no son `Level`, así que no existe dato que
///   pudiera representar su desbloqueo (FR-038).
library;

import '../core/activity_score.dart';
import '../core/course.dart';
import '../core/level.dart';
import '../core/level_state.dart';
import '../core/module.dart';
import '../core/student_progress.dart';

/// En qué situación está un módulo para este estudiante.
enum ModuleAvailability {
  /// El requisito previo no está cumplido.
  locked,

  /// Se puede estudiar, pero su examen no está aprobado.
  available,

  /// Su examen está aprobado.
  passed,
}

/// Por qué un módulo está bloqueado.
///
/// Existe para que la interfaz pueda explicar **qué falta** y no solo decir
/// «bloqueado» (FR-023). Un candado sin motivo es una pared.
class LockReason {
  const LockReason.previousModule(this.moduleTitle)
    : levelName = null,
      levelHasNoContent = false;

  const LockReason.previousLevel(this.levelName)
    : moduleTitle = null,
      levelHasNoContent = false;

  const LockReason.levelInPreparation()
    : moduleTitle = null,
      levelName = null,
      levelHasNoContent = true;

  /// Título del módulo que falta aprobar.
  final String? moduleTitle;

  /// Nombre del nivel que falta superar.
  final String? levelName;

  /// El nivel está anunciado pero su contenido no existe todavía.
  final bool levelHasNoContent;
}

/// Situación de un módulo.
ModuleAvailability moduleAvailability({
  required Course course,
  required StudentProgress progress,
  required Module module,
}) {
  final Level? level = course.levelOfModule(module.id);
  if (level == null) return ModuleAvailability.locked;

  if (progress.hasPassed(module.moduleExam.id)) {
    return ModuleAvailability.passed;
  }

  final LevelState levelState = progress.stateOf(level.id);
  if (!levelState.isOpen) return ModuleAvailability.locked;

  // Un nivel marcado como dominado por la nivelación queda abierto completo para
  // repaso: no tiene sentido pedirle a alguien que ya demostró el nivel que
  // recorra sus módulos en orden.
  if (levelState == LevelState.mastered || levelState == LevelState.passed) {
    return ModuleAvailability.available;
  }

  final int index = level.modules.indexWhere((Module m) => m.id == module.id);
  if (index <= 0) return ModuleAvailability.available;

  final Module previous = level.modules[index - 1];
  return progress.hasPassed(previous.moduleExam.id)
      ? ModuleAvailability.available
      : ModuleAvailability.locked;
}

/// Por qué está bloqueado, o nulo si no lo está.
LockReason? lockReasonFor({
  required Course course,
  required StudentProgress progress,
  required Module module,
}) {
  if (moduleAvailability(
        course: course,
        progress: progress,
        module: module,
      ) !=
      ModuleAvailability.locked) {
    return null;
  }

  final Level? level = course.levelOfModule(module.id);
  if (level == null) return const LockReason.levelInPreparation();

  if (!progress.stateOf(level.id).isOpen) {
    final int levelIndex = course.levels.indexWhere(
      (Level l) => l.id == level.id,
    );
    final Level? previousLevel = levelIndex > 0
        ? course.levels[levelIndex - 1]
        : null;
    return LockReason.previousLevel(previousLevel?.name ?? level.name);
  }

  final int index = level.modules.indexWhere((Module m) => m.id == module.id);
  if (index > 0) {
    return LockReason.previousModule(level.modules[index - 1].title);
  }
  return LockReason.previousLevel(level.name);
}

/// Si el examen de nivel se puede presentar.
///
/// Exige **todos** los módulos aprobados: el examen de nivel certifica el nivel
/// completo, no la parte que se recorrió.
bool isLevelExamAvailable({
  required StudentProgress progress,
  required Level level,
}) => level.modules.every(
  (Module m) => progress.hasPassed(m.moduleExam.id),
);

/// Cuántos módulos del nivel están aprobados.
int passedModuleCount({
  required StudentProgress progress,
  required Level level,
}) => level.modules
    .where((Module m) => progress.hasPassed(m.moduleExam.id))
    .length;

/// Proporción del nivel aprobada, de 0.0 a 1.0.
double levelCompletion({
  required StudentProgress progress,
  required Level level,
}) => level.modules.isEmpty
    ? 0
    : passedModuleCount(progress: progress, level: level) /
          level.modules.length;

/// Aplica un estado de nivel, **rechazando los descensos**.
///
/// Devuelve el progreso sin cambios si la transición retrocedería. No lanza: una
/// sincronización puede traer un estado más bajo de forma legítima, y lo correcto
/// es ignorarlo, no romper la app.
StudentProgress applyLevelState({
  required StudentProgress progress,
  required String levelId,
  required LevelState state,
}) {
  final LevelState current = progress.stateOf(levelId);
  if (state.rank <= current.rank) return progress;

  return progress.copyWith(
    levelStates: <String, LevelState>{...progress.levelStates, levelId: state},
  );
}

/// Aplica la aprobación de un examen de módulo: desbloquea el siguiente módulo.
///
/// El desbloqueo de módulo no necesita estado propio: se deriva de que el examen
/// anterior esté aprobado, que ya está en `activityScores`. Menos estado que
/// mantener coherente es menos estado que puede divergir.
StudentProgress applyModuleExamPassed({
  required Course course,
  required StudentProgress progress,
  required Module module,
}) {
  final Level? level = course.levelOfModule(module.id);
  if (level == null) return progress;

  // Si con este módulo se completó el nivel, no se asciende todavía: falta el
  // examen de nivel, que es la puerta de verdad (FR-024).
  return progress;
}

/// Aplica la aprobación del examen de nivel.
///
/// Marca el nivel como superado y desbloquea el siguiente **con contenido**. Si el
/// siguiente solo está anunciado, no hay nada que desbloquear: la interfaz lo
/// presenta como próximo (FR-038).
StudentProgress applyLevelExamPassed({
  required Course course,
  required StudentProgress progress,
  required Level level,
}) {
  StudentProgress updated = applyLevelState(
    progress: progress,
    levelId: level.id,
    state: LevelState.passed,
  );

  final Level? next = course.levelAfter(level.id);
  if (next == null) return updated;

  updated = applyLevelState(
    progress: updated,
    levelId: next.id,
    state: LevelState.unlocked,
  );

  return updated.copyWith(currentLevelId: next.id);
}

/// Clase de actividad que corresponde a un examen.
ActivityKind examKindFor({required Course course, required String examId}) {
  for (final Level level in course.levels) {
    if (level.levelExam.id == examId) return ActivityKind.levelExam;
    for (final Module module in level.modules) {
      if (module.moduleExam.id == examId) return ActivityKind.moduleExam;
    }
  }
  return ActivityKind.lesson;
}
