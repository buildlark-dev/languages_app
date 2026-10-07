/// Estado de un nivel para un estudiante concreto.
///
/// El valor entero no es decorativo: **es el orden de avance**. Por eso la
/// fusión entre dos dispositivos puede ser un simple máximo, en Dart y en SQL
/// (`MAX(state)`), y por eso el estado se guarda como entero en la base de
/// datos y en el documento remoto.
library;

enum LevelState {
  /// El requisito previo no está cumplido.
  locked(0),

  /// Accesible y en curso.
  unlocked(1),

  /// Marcado como dominado por la prueba de nivelación.
  ///
  /// Abierto para repaso; repasarlo no lo degrada ni lo asciende.
  mastered(2),

  /// Examen de nivel aprobado con el umbral exigido.
  passed(3);

  const LevelState(this.rank);

  /// Posición en el orden de avance. Mayor es más avanzado.
  final int rank;

  /// Reconstruye el estado desde su entero almacenado.
  ///
  /// Un valor desconocido degrada a [locked] en lugar de lanzar: si una versión
  /// futura introdujera un estado nuevo y el progreso llegara por
  /// sincronización a una versión vieja de la app, bloquear es seguro y perder
  /// el acceso es recuperable; romper el arranque no lo es.
  static LevelState fromRank(int rank) => LevelState.values.firstWhere(
    (LevelState state) => state.rank == rank,
    orElse: () => LevelState.locked,
  );

  /// El más avanzado de dos estados.
  ///
  /// Esta es la regla de fusión del Principio IV: ante dos dispositivos, nunca
  /// se retrocede.
  static LevelState merge(LevelState a, LevelState b) => a.rank >= b.rank ? a : b;

  /// Si el nivel se puede estudiar.
  bool get isOpen => this != LevelState.locked;

  /// Si el estudiante ya demostró dominio del nivel, por examen o por
  /// nivelación.
  bool get isCleared =>
      this == LevelState.mastered || this == LevelState.passed;
}
