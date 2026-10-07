/// Todo lo que el estudiante ha conseguido. El agregado raíz del progreso.
///
/// Cada campo lleva anotada su regla de fusión, porque de ellas depende que
/// nadie pierda avance al sincronizar dos dispositivos (FR-042). Todas son
/// máximos sobre un orden total o uniones de conjuntos, lo que hace que la
/// fusión sea conmutativa, asociativa e idempotente.
///
/// La fusión en sí vive en `engine/progress_merger.dart`: esta capa define los
/// datos, no las operaciones.
library;

import 'level_state.dart';
import 'placement_result.dart';
import 'review_card.dart';
import 'sync_state.dart';

/// Versión del esquema de datos persistidos.
///
/// Sube cuando cambia la forma del progreso, y cada subida obliga a una
/// migración que lo preserve (Principio IV).
const int currentProgressSchemaVersion = 1;

class StudentProgress {
  const StudentProgress({
    required this.uid,
    required this.courseId,
    required this.currentLevelId,
    this.schemaVersion = currentProgressSchemaVersion,
    this.xp = 0,
    this.streakCount = 0,
    this.lastActivityDate,
    this.levelStates = const <String, LevelState>{},
    this.activityScores = const <String, double>{},
    this.reviewCards = const <String, ReviewCard>{},
    this.placement,
    this.syncState = const SyncState(),
  });

  /// Estudiante vacío al empezar un curso.
  factory StudentProgress.initial({
    required String uid,
    required String courseId,
    required String firstLevelId,
  }) => StudentProgress(
    uid: uid,
    courseId: courseId,
    currentLevelId: firstLevelId,
    levelStates: <String, LevelState>{firstLevelId: LevelState.unlocked},
  );

  /// Clave. No se fusiona.
  final String uid;

  /// Clave. No se fusiona.
  final String courseId;

  /// Fusión: el mayor.
  final int schemaVersion;

  /// Fusión: el nivel más avanzado.
  final String currentLevelId;

  /// Fusión: **máximo**.
  final int xp;

  /// Fusión: máximo, y después **recalculado** contra [lastActivityDate].
  ///
  /// El máximo a secas resucitaría rachas caducadas: racha 7 del lunes fusionada
  /// con racha 1 del jueves daría "siete días seguidos" a quien no estudió el
  /// martes ni el miércoles, incumpliendo FR-032 de forma observable. El
  /// recálculo lo hace `streak_tracker.dart`.
  final int streakCount;

  /// Fusión: la más reciente.
  final DateTime? lastActivityDate;

  /// Fusión: por clave, el estado más avanzado.
  ///
  /// Solo contiene niveles **con contenido**: los anunciados no tienen estado.
  final Map<String, LevelState> levelStates;

  /// Mejor puntaje de cada actividad, de 0.0 a 1.0.
  ///
  /// "Actividad" cubre lecciones y exámenes, porque las tres comparten la regla
  /// de conservar solo el mejor intento. Guardar únicamente el máximo es lo que
  /// hace imposible que un reintento peor desapruebe algo ya aprobado (FR-027):
  /// no es una comprobación en el código, es la forma del dato.
  ///
  /// Fusión: **máximo** por clave, unión de claves.
  final Map<String, double> activityScores;

  /// Cola de repetición espaciada, indexada por `moduleId|term`.
  ///
  /// Fusión: unión de claves; cada tarjeta se fusiona con su propia regla.
  final Map<String, ReviewCard> reviewCards;

  /// Fusión: el de fecha más reciente.
  final PlacementResult? placement;

  /// **No se fusiona**: es estado de este dispositivo.
  final SyncState syncState;

  /// Estado de un nivel, con [LevelState.locked] como ausencia.
  LevelState stateOf(String levelId) =>
      levelStates[levelId] ?? LevelState.locked;

  /// Mejor puntaje de una actividad, o nulo si nunca se presentó.
  double? scoreOf(String activityId) => activityScores[activityId];

  /// Si una actividad alcanzó el umbral dado.
  bool hasPassed(String activityId, double threshold) {
    final double? score = activityScores[activityId];
    return score != null && score >= threshold;
  }

  /// Tarjetas que vencen en la fecha dada o antes.
  List<ReviewCard> dueCards(DateTime today) => reviewCards.values
      .where((ReviewCard card) => card.isDue(today))
      .toList(growable: false);

  StudentProgress copyWith({
    int? schemaVersion,
    String? currentLevelId,
    int? xp,
    int? streakCount,
    DateTime? lastActivityDate,
    Map<String, LevelState>? levelStates,
    Map<String, double>? activityScores,
    Map<String, ReviewCard>? reviewCards,
    PlacementResult? placement,
    SyncState? syncState,
  }) => StudentProgress(
    uid: uid,
    courseId: courseId,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    currentLevelId: currentLevelId ?? this.currentLevelId,
    xp: xp ?? this.xp,
    streakCount: streakCount ?? this.streakCount,
    lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    levelStates: levelStates ?? this.levelStates,
    activityScores: activityScores ?? this.activityScores,
    reviewCards: reviewCards ?? this.reviewCards,
    placement: placement ?? this.placement,
    syncState: syncState ?? this.syncState,
  );
}
