/// Forma serializada del progreso.
///
/// Una sola serialización sirve al documento remoto y al archivo de respaldo,
/// que es lo que el contrato de servicios pedía: así no hay dos formatos que
/// mantener sincronizados, y un respaldo se puede comparar a ojo con lo que hay
/// en Firestore.
///
/// Las fechas se guardan como texto ISO 8601 y no como `Timestamp` de Firestore,
/// precisamente para que el mismo mapa valga como JSON de respaldo sin
/// conversiones.
///
/// **Corrección respecto al diseño inicial**: `contracts/firestore.md` describía
/// dos mapas separados, `lessonResults` y `examResults`. Se unifican en
/// `activities`, con la clase de actividad dentro de cada entrada, porque el
/// modelo necesita distinguir examen de módulo de examen de nivel y la división
/// en dos mapas solo guardaba «lección o examen». Una regla de fusión en lugar de
/// dos, y el umbral viaja con el dato.
library;

import '../../core/activity_score.dart';
import '../../core/level_state.dart';
import '../../core/placement_result.dart';
import '../../core/review_card.dart';
import '../../core/student_progress.dart';

/// Convierte el progreso en un mapa serializable.
Map<String, Object?> progressToMap(
  StudentProgress progress,
) => <String, Object?>{
  'schemaVersion': progress.schemaVersion,
  'currentLevelId': progress.currentLevelId,
  'xp': progress.xp,
  'streakCount': progress.streakCount,
  'lastActivityDate': _dateToIso(progress.lastActivityDate),
  'levelStates': <String, Object?>{
    for (final MapEntry<String, LevelState> e in progress.levelStates.entries)
      e.key: e.value.rank,
  },
  'activities': <String, Object?>{
    for (final MapEntry<String, ActivityScore> e
        in progress.activityScores.entries)
      e.key: <String, Object?>{
        'kind': e.value.kind.code,
        'bestScore': e.value.bestScore,
        'attempts': e.value.attempts,
        'lastAttemptAt': _dateToIso(e.value.lastAttemptAt),
      },
  },
  'reviewCards': <String, Object?>{
    for (final MapEntry<String, ReviewCard> e in progress.reviewCards.entries)
      e.key: <String, Object?>{
        'moduleId': e.value.moduleId,
        'term': e.value.term,
        'translation': e.value.translation,
        'intervalStep': e.value.intervalStep,
        'dueDate': _dateToIso(e.value.dueDate),
        'lapses': e.value.lapses,
      },
  },
  if (progress.placement != null)
    'placement': <String, Object?>{
      'estimatedLevelId': progress.placement!.estimatedLevelId,
      'masteredLevelIds': progress.placement!.masteredLevelIds,
      'skipped': progress.placement!.skipped,
      'takenAt': _dateToIso(progress.placement!.takenAt),
    },
  'updatedAt': _dateToIso(DateTime.now()),
};

/// Reconstruye el progreso desde un mapa.
///
/// Es tolerante con lo que falta y con lo que sobra: un campo ausente toma su
/// valor por defecto y uno desconocido se ignora. Eso es lo que permite que una
/// versión vieja de la app lea un documento escrito por una nueva sin romperse,
/// que es el caso real cuando alguien actualiza un dispositivo y no el otro.
StudentProgress progressFromMap(
  Map<String, Object?> map, {
  required String uid,
  required String courseId,
}) {
  final Map<String, Object?> levelStates = _asMap(map['levelStates']);
  final Map<String, Object?> activities = _asMap(map['activities']);
  final Map<String, Object?> reviewCards = _asMap(map['reviewCards']);
  final Map<String, Object?> placement = _asMap(map['placement']);

  return StudentProgress(
    uid: uid,
    courseId: courseId,
    schemaVersion: _asInt(map['schemaVersion'], currentProgressSchemaVersion),
    currentLevelId: map['currentLevelId'] as String? ?? 'A1',
    xp: _asInt(map['xp'], 0),
    streakCount: _asInt(map['streakCount'], 0),
    lastActivityDate: _dateFromIso(map['lastActivityDate']),
    levelStates: <String, LevelState>{
      for (final MapEntry<String, Object?> e in levelStates.entries)
        e.key: LevelState.fromRank(_asInt(e.value, 0)),
    },
    activityScores: <String, ActivityScore>{
      for (final MapEntry<String, Object?> e in activities.entries)
        e.key: _activityFromMap(_asMap(e.value)),
    },
    reviewCards: <String, ReviewCard>{
      for (final MapEntry<String, Object?> e in reviewCards.entries)
        e.key: _cardFromMap(_asMap(e.value)),
    },
    placement: placement.isEmpty
        ? null
        : PlacementResult(
            estimatedLevelId: placement['estimatedLevelId'] as String? ?? 'A1',
            masteredLevelIds: _asStringList(placement['masteredLevelIds']),
            takenAt: _dateFromIso(placement['takenAt']) ?? DateTime.now(),
            skipped: placement['skipped'] as bool? ?? false,
          ),
  );
}

ActivityScore _activityFromMap(Map<String, Object?> map) => ActivityScore(
  kind: ActivityKind.fromCode(_asInt(map['kind'], 0)),
  bestScore: _asDouble(map['bestScore'], 0),
  attempts: _asInt(map['attempts'], 1),
  lastAttemptAt: _dateFromIso(map['lastAttemptAt']) ?? DateTime.now(),
);

ReviewCard _cardFromMap(Map<String, Object?> map) => ReviewCard(
  moduleId: map['moduleId'] as String? ?? '',
  term: map['term'] as String? ?? '',
  translation: map['translation'] as String? ?? '',
  intervalStep: _asInt(map['intervalStep'], 0),
  dueDate: _dateFromIso(map['dueDate']) ?? DateTime.now(),
  lapses: _asInt(map['lapses'], 0),
);

String? _dateToIso(DateTime? date) => date?.toIso8601String();

DateTime? _dateFromIso(Object? value) {
  if (value is String) return DateTime.tryParse(value);
  // Un documento escrito por una versión que usara Timestamp llegaría como un
  // mapa o un objeto no reconocible: se trata como ausente en lugar de romper.
  return null;
}

Map<String, Object?> _asMap(Object? value) => value is Map
    ? value.map(
        (Object? key, Object? v) => MapEntry<String, Object?>('$key', v),
      )
    : <String, Object?>{};

int _asInt(Object? value, int fallback) => value is num
    ? value.toInt()
    : (value is String ? int.tryParse(value) ?? fallback : fallback);

double _asDouble(Object? value, double fallback) =>
    value is num ? value.toDouble() : fallback;

List<String> _asStringList(Object? value) => value is List
    ? value.map((Object? e) => '$e').toList(growable: false)
    : const <String>[];
