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

import 'activity_score.dart';
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
    this.activityScores = const <String, ActivityScore>{},
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

  /// Mejor resultado de cada actividad, indexado por su identificador.
  ///
  /// Fusión: por clave, el [ActivityScore.mergeWith] de ambos; unión de claves.
  final Map<String, ActivityScore> activityScores;

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

  /// Resultado de una actividad, o nulo si nunca se presentó.
  ActivityScore? scoreOf(String activityId) => activityScores[activityId];

  /// Si una actividad está aprobada según el umbral de su propia clase.
  ///
  /// Quien pregunta no necesita saber si era lección (70 %) o examen (80 %): el
  /// umbral viaja con [ActivityKind].
  bool hasPassed(String activityId) =>
      activityScores[activityId]?.isPassed ?? false;

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
    Map<String, ActivityScore>? activityScores,
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
