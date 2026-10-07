/// Resultado de la prueba de nivelación.
///
/// La distinción entre **nivel estimado** y **nivel asignado** es lo que hace
/// honesta la nivelación. Si alguien da B1 en la prueba, se le dice que su nivel
/// estimado es B1 —información verdadera y útil— aunque el nivel donde puede
/// estudiar se limite a lo que existe construido.
library;

class PlacementResult {
  const PlacementResult({
    required this.estimatedLevelId,
    required this.masteredLevelIds,
    required this.takenAt,
    this.skipped = false,
  });

  /// La persona omitió la prueba y empieza desde el principio.
  const PlacementResult.skippedAt(this.takenAt)
    : estimatedLevelId = 'A1',
      masteredLevelIds = const <String>[],
      skipped = true;

  /// Nivel que la prueba estima. Cualquier nivel MCER, incluso sin contenido.
  final String estimatedLevelId;

  /// Niveles **con contenido** que quedan marcados como dominados.
  final List<String> masteredLevelIds;

  final DateTime takenAt;

  /// True si la persona omitió la prueba en lugar de presentarla.
  final bool skipped;

  /// El resultado más reciente de dos.
  ///
  /// Regla de fusión: gana el de fecha más nueva, porque una nivelación
  /// posterior refleja mejor el estado actual del estudiante.
  static PlacementResult? merge(PlacementResult? a, PlacementResult? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.takenAt.isAfter(b.takenAt) ? a : b;
  }
}
