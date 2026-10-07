/// Verifica las garantías del contrato de sincronización.
///
/// **Qué cubre y qué no**, para no dar una impresión falsa de cobertura:
///
/// * **Cubre** el comportamiento que el contrato promete —nunca sobrescribir,
///   idempotencia, visibilidad del fallo— ejercitado sobre un doble que fusiona
///   con la **misma** `mergeProgress` que la implementación real.
/// * **No cubre** el código de la transacción de Firestore ni las reglas de
///   seguridad: eso necesita el emulador y se verifica en el paso de quickstart
///   correspondiente. `cloud_firestore` no funciona en una prueba de VM, porque
///   depende de canales de plataforma.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/student_progress.dart';

import '../../fakes/fake_sync_service.dart';

StudentProgress progress({
  int xp = 0,
  Map<String, LevelState> levels = const <String, LevelState>{},
  Map<String, ActivityScore> scores = const <String, ActivityScore>{},
}) => StudentProgress(
  uid: 'u1',
  courseId: 'en',
  currentLevelId: 'A1',
  xp: xp,
  levelStates: levels,
  activityScores: scores,
);

ActivityScore score(double value) => ActivityScore(
  kind: ActivityKind.lesson,
  bestScore: value,
  lastAttemptAt: DateTime(2026, 10, 6),
);

void main() {
  late FakeSyncService sync;

  setUp(() => sync = FakeSyncService());
  tearDown(() => sync.dispose());

  test('sin documento remoto, el primer empujón escribe lo local', () async {
    final StudentProgress written = await sync.pushMerged(progress(xp: 50));
    expect(written.xp, 50);
    expect(sync.remote!.xp, 50);
  });

  test('pushMerged NUNCA sobrescribe: el resultado conserva lo remoto', () async {
    sync = FakeSyncService(
      remote: progress(
        xp: 500,
        levels: <String, LevelState>{'A1': LevelState.passed},
        scores: <String, ActivityScore>{'L1': score(0.95)},
      ),
    );

    // Un dispositivo con menos avance empuja.
    final StudentProgress written = await sync.pushMerged(
      progress(
        xp: 20,
        levels: <String, LevelState>{'A1': LevelState.unlocked},
        scores: <String, ActivityScore>{'L2': score(0.7)},
      ),
    );

    // Nada de lo remoto se perdió, y lo local se añadió.
    expect(written.xp, 500);
    expect(written.stateOf('A1'), LevelState.passed);
    expect(written.activityScores['L1']!.bestScore, closeTo(0.95, 1e-9));
    expect(written.activityScores['L2']!.bestScore, closeTo(0.7, 1e-9));
  });

  test('empujar dos veces lo mismo no cambia el resultado', () async {
    final StudentProgress local = progress(
      xp: 120,
      scores: <String, ActivityScore>{'L1': score(0.8)},
    );

    final StudentProgress first = await sync.pushMerged(local);
    final StudentProgress second = await sync.pushMerged(local);

    expect(second.xp, first.xp);
    expect(second.activityScores.length, first.activityScores.length);
    expect(sync.pushCount, 2, reason: 'Se intentó dos veces de verdad');
  });

  test('aplicar una emisión ya fusionada no tiene efecto', () async {
    // Es lo que permite no llevar registro de qué emisión se procesó: la fusión
    // es idempotente.
    await sync.pushMerged(progress(xp: 300));
    final StudentProgress fromCloud = sync.remote!;

    final StudentProgress again = await sync.pushMerged(fromCloud);
    expect(again.xp, 300);
  });

  test('el orden de los dispositivos no altera el resultado', () async {
    final StudentProgress phone = progress(
      xp: 100,
      scores: <String, ActivityScore>{'L1': score(0.9)},
    );
    final StudentProgress laptop = progress(
      xp: 250,
      scores: <String, ActivityScore>{'L2': score(0.6)},
    );

    final FakeSyncService a = FakeSyncService();
    await a.pushMerged(phone);
    await a.pushMerged(laptop);

    final FakeSyncService b = FakeSyncService();
    await b.pushMerged(laptop);
    await b.pushMerged(phone);

    expect(a.remote!.xp, b.remote!.xp);
    expect(
      a.remote!.activityScores.keys.toSet(),
      b.remote!.activityScores.keys.toSet(),
    );

    await a.dispose();
    await b.dispose();
  });

  test('un fallo de red deja el motivo visible y marca lo pendiente', () async {
    sync.offline = true;

    await expectLater(
      () => sync.pushMerged(progress(xp: 10)),
      throwsA(isA<StateError>()),
    );

    // FR-043: el fallo no puede ser silencioso.
    expect(sync.currentStatus.hasPendingChanges, isTrue);
    expect(sync.currentStatus.lastError, isNotNull);
  });

  test('remoteChanges emite lo que otro dispositivo escribió', () async {
    final Future<StudentProgress> next = sync
        .remoteChanges(uid: 'u1', courseId: 'en')
        .first;

    sync.emitRemoteChange(progress(xp: 777));

    expect((await next).xp, 777);
  });
}
