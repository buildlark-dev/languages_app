/// Verifica que serializar y volver a leer no pierde nada.
///
/// Un error aquí no se nota al probar la app: el progreso viaja a la nube, vuelve
/// incompleto y el estudiante pierde avance sin que nada falle visiblemente.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/placement_result.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/services/sync/progress_document.dart';

StudentProgress fullProgress() => StudentProgress(
  uid: 'u1',
  courseId: 'en',
  currentLevelId: 'A1',
  xp: 530,
  streakCount: 12,
  lastActivityDate: DateTime(2026, 10, 6),
  levelStates: const <String, LevelState>{
    'A1': LevelState.passed,
    'A2': LevelState.mastered,
  },
  activityScores: <String, ActivityScore>{
    'A1M1L1': ActivityScore(
      kind: ActivityKind.lesson,
      bestScore: 0.85,
      attempts: 3,
      lastAttemptAt: DateTime(2026, 10, 5, 14, 30),
    ),
    'A1M1EX': ActivityScore(
      kind: ActivityKind.moduleExam,
      bestScore: 0.9,
      lastAttemptAt: DateTime(2026, 10, 6, 9),
    ),
    'A1EX': ActivityScore(
      kind: ActivityKind.levelExam,
      bestScore: 0.82,
      lastAttemptAt: DateTime(2026, 10, 6, 10),
    ),
  },
  reviewCards: <String, ReviewCard>{
    'A1M1|neighbour': ReviewCard(
      moduleId: 'A1M1',
      term: 'neighbour',
      translation: 'el vecino / la vecina',
      intervalStep: 4,
      dueDate: DateTime(2026, 11, 10),
      lapses: 2,
    ),
  },
  placement: PlacementResult(
    estimatedLevelId: 'B1',
    masteredLevelIds: const <String>['A1'],
    takenAt: DateTime(2026, 10, 1, 8),
  ),
);

void main() {
  test('ida y vuelta completa sin pérdida', () {
    final StudentProgress original = fullProgress();
    final StudentProgress restored = progressFromMap(
      progressToMap(original),
      uid: 'u1',
      courseId: 'en',
    );

    expect(restored.xp, original.xp);
    expect(restored.streakCount, original.streakCount);
    expect(restored.lastActivityDate, original.lastActivityDate);
    expect(restored.currentLevelId, original.currentLevelId);
    expect(restored.schemaVersion, original.schemaVersion);
    expect(restored.levelStates, original.levelStates);

    // El tipo de actividad tiene que viajar: de él depende el umbral que
    // decide si está aprobada.
    for (final String key in original.activityScores.keys) {
      final ActivityScore a = original.activityScores[key]!;
      final ActivityScore b = restored.activityScores[key]!;
      expect(b.kind, a.kind, reason: key);
      expect(b.bestScore, closeTo(a.bestScore, 1e-9), reason: key);
      expect(b.attempts, a.attempts, reason: key);
      expect(b.lastAttemptAt, a.lastAttemptAt, reason: key);
    }

    final ReviewCard cardA = original.reviewCards['A1M1|neighbour']!;
    final ReviewCard cardB = restored.reviewCards['A1M1|neighbour']!;
    expect(cardB.intervalStep, cardA.intervalStep);
    expect(cardB.dueDate, cardA.dueDate);
    expect(cardB.lapses, cardA.lapses);
    expect(cardB.translation, cardA.translation);

    expect(restored.placement!.estimatedLevelId, 'B1');
    expect(restored.placement!.masteredLevelIds, <String>['A1']);
    expect(restored.placement!.takenAt, original.placement!.takenAt);
    expect(restored.placement!.skipped, isFalse);
  });

  test('las tres clases de actividad se distinguen tras el viaje', () {
    final StudentProgress restored = progressFromMap(
      progressToMap(fullProgress()),
      uid: 'u1',
      courseId: 'en',
    );

    // Si el tipo se perdiera, un examen de nivel se evaluaría al 70 %.
    expect(restored.hasPassed('A1EX'), isTrue);
    expect(restored.scoreOf('A1EX')!.kind.passThreshold, 0.80);
    expect(restored.scoreOf('A1M1L1')!.kind.passThreshold, 0.70);
  });

  test('un progreso vacío sobrevive la ida y vuelta', () {
    final StudentProgress empty = StudentProgress.initial(
      uid: 'u1',
      courseId: 'en',
      firstLevelId: 'A1',
    );
    final StudentProgress restored = progressFromMap(
      progressToMap(empty),
      uid: 'u1',
      courseId: 'en',
    );

    expect(restored.xp, 0);
    expect(restored.streakCount, 0);
    expect(restored.lastActivityDate, isNull);
    expect(restored.placement, isNull);
    expect(restored.stateOf('A1'), LevelState.unlocked);
  });

  group('tolerancia a documentos de otras versiones', () {
    test('un campo ausente toma su valor por defecto', () {
      final StudentProgress restored = progressFromMap(
        <String, Object?>{'xp': 10},
        uid: 'u1',
        courseId: 'en',
      );
      expect(restored.xp, 10);
      expect(restored.currentLevelId, 'A1');
      expect(restored.streakCount, 0);
      expect(restored.levelStates, isEmpty);
    });

    test('un campo desconocido se ignora en lugar de romper', () {
      // El caso real: alguien actualiza un dispositivo y no el otro, y el viejo
      // lee un documento escrito por el nuevo.
      final Map<String, Object?> map = progressToMap(fullProgress())
        ..['futureFeature'] = <String, Object?>{'whatever': true};

      final StudentProgress restored = progressFromMap(
        map,
        uid: 'u1',
        courseId: 'en',
      );
      expect(restored.xp, 530);
    });

    test('un estado de nivel desconocido degrada a bloqueado', () {
      // Bloquear es seguro y recuperable; romper el arranque no lo es.
      final StudentProgress restored = progressFromMap(
        <String, Object?>{
          'levelStates': <String, Object?>{'C2': 99},
        },
        uid: 'u1',
        courseId: 'en',
      );
      expect(restored.stateOf('C2'), LevelState.locked);
    });

    test('una fecha ilegible se trata como ausente', () {
      final StudentProgress restored = progressFromMap(
        <String, Object?>{'lastActivityDate': 'no es una fecha'},
        uid: 'u1',
        courseId: 'en',
      );
      expect(restored.lastActivityDate, isNull);
    });

    test('un número que llega como texto se interpreta', () {
      // Firestore puede devolver enteros grandes como texto según el cliente.
      final StudentProgress restored = progressFromMap(
        <String, Object?>{'xp': '240'},
        uid: 'u1',
        courseId: 'en',
      );
      expect(restored.xp, 240);
    });
  });
}
