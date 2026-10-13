/// Verifica la costura entre el motor, el almacén y la sincronización.
///
/// Lo que se comprueba aquí no es la lógica de aprendizaje —eso ya lo hacen
/// `progress_recorder_test.dart` y `placement_evaluator_test.dart`— sino el
/// **orden**: primero disco, después nube. Al revés, un empujón fallido dejaría
/// la lección aprobada solo en memoria.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/placement_result.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/engine/progress_recorder.dart';
import 'package:languages_app/engine/scoring.dart';
import 'package:languages_app/services/auth/auth_service.dart';
import 'package:languages_app/ui/providers/auth_providers.dart';
import 'package:languages_app/ui/providers/clock_providers.dart';
import 'package:languages_app/ui/providers/content_providers.dart';
import 'package:languages_app/ui/providers/progress_controller.dart';
import 'package:languages_app/ui/providers/progress_providers.dart';

import '../../fakes/fake_auth_service.dart';
import '../../fakes/fake_catalog.dart';
import '../../fakes/fake_progress_store.dart';
import '../../fakes/fake_sync_service.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 7);

  late FakeProgressStore store;
  late FakeSyncService sync;
  late ProviderContainer container;

  /// Arranca con el idioma ya elegido.
  ///
  /// Se sobrescribe el proveedor en lugar de llamar a `select()`: así el ámbito
  /// está resuelto desde la primera lectura y la prueba no depende del orden en
  /// que se observen los proveedores.
  ProviderContainer makeContainer({StudentProgress? stored}) {
    store = FakeProgressStore(initial: stored);
    sync = FakeSyncService();
    final ProviderContainer made = ProviderContainer(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        syncServiceProvider.overrideWithValue(sync),
        clockProvider.overrideWithValue(fixedClock(today)),
        courseCatalogProvider.overrideWithValue(const FakeCatalog()),
        selectedCourseIdProvider.overrideWith(PreselectedCourse.new),
        authServiceProvider.overrideWithValue(
          FakeAuthService(
            initialUser: const StudentIdentity(
              uid: 'u1',
              email: 'ana@example.com',
            ),
          ),
        ),
      ],
    );

    // Hay que escuchar el proveedor, no solo leerlo.
    //
    // En Riverpod 3 un proveedor sin oyentes se desecha, y uno asíncrono
    // desechado a mitad de su `build` nunca resuelve su futuro: la espera se
    // queda colgada treinta segundos y la prueba muere por tiempo. En la app lo
    // sostiene el widget que lo observa; aquí hay que sostenerlo a mano.
    made.listen(studentProgressProvider, (_, _) {});
    return made;
  }

  setUp(() => container = makeContainer());
  tearDown(() => container.dispose());

  StudentProgress storedProgress() => const StudentProgress(
    uid: 'u1',
    courseId: 'xx',
    currentLevelId: 'A1',
    xp: 40,
    levelStates: <String, LevelState>{'A1': LevelState.unlocked},
  );

  ScoreResult passing() => const ScoreResult(
    correct: 5,
    answered: 5,
    unavailable: 0,
    ratio: 1,
    passed: true,
  );

  group('carga', () {
    test('devuelve el progreso guardado', () async {
      container.dispose();
      container = makeContainer(stored: storedProgress());

      final StudentProgress? loaded = await container.read(
        studentProgressProvider.future,
      );

      expect(loaded!.xp, 40);
      // Cargar no escribe: el progreso del disco ya es el bueno.
      expect(store.saves, isEmpty);
    });

    test('en el primer arranque lo crea y lo persiste', () async {
      final StudentProgress? created = await container.read(
        studentProgressProvider.future,
      );

      expect(created!.currentLevelId, 'A1');
      expect(created.levelStates['A1'], LevelState.unlocked);
      // Se guarda de inmediato: si se quedara en memoria, el primer nivel
      // aparecería abierto y al cerrar la app volvería a estar bloqueado.
      expect(store.saves, hasLength(1));
      expect(store.current('u1', 'xx')!.currentLevelId, 'A1');
    });
  });

  group('registrar una actividad', () {
    test('aplica el motor, guarda y devuelve lo que cambió', () async {
      container.dispose();
      container = makeContainer(stored: storedProgress());
      await container.read(studentProgressProvider.future);

      final RecordedActivity? recorded = await container
          .read(studentProgressProvider.notifier)
          .recordResult(
            activityId: 'XXM1L1',
            kind: ActivityKind.lesson,
            result: passing(),
          );

      expect(recorded!.xpGained, greaterThan(0));
      expect(recorded.progress.activityScores['XXM1L1']!.bestScore, 1.0);
      expect(store.current('u1', 'xx')!.activityScores, hasLength(1));
      // Dos escrituras, no una: la del motor y la de lo que vuelve fusionado de
      // la nube. La segunda es la que mantiene los dos lados iguales tras cada
      // sincronización, y está documentada en `SyncScheduler`.
      expect(store.saves, hasLength(2));
    });

    test('el estado de la interfaz queda con lo guardado', () async {
      container.dispose();
      container = makeContainer(stored: storedProgress());
      await container.read(studentProgressProvider.future);

      await container
          .read(studentProgressProvider.notifier)
          .recordResult(
            activityId: 'XXM1L1',
            kind: ActivityKind.lesson,
            result: passing(),
          );

      final StudentProgress? inUi = container
          .read(studentProgressProvider)
          .value;
      expect(inUi!.activityScores['XXM1L1'], isNotNull);
      expect(inUi.xp, greaterThan(40));
    });

    test('guarda en disco ANTES de pedir sincronización', () async {
      container.dispose();
      container = makeContainer(stored: storedProgress());
      await container.read(studentProgressProvider.future);

      await container
          .read(studentProgressProvider.notifier)
          .recordResult(
            activityId: 'XXM1L1',
            kind: ActivityKind.lesson,
            result: passing(),
          );

      // El empujón ocurrió y encontró en disco lo que debía empujar.
      expect(sync.pushCount, 1);
      expect(sync.remote!.activityScores['XXM1L1'], isNotNull);
      expect(store.saves, isNotEmpty);
    });

    test('sin red, el avance local sobrevive', () async {
      container.dispose();
      container = makeContainer(stored: storedProgress());
      await container.read(studentProgressProvider.future);
      sync.offline = true;

      await container
          .read(studentProgressProvider.notifier)
          .recordResult(
            activityId: 'XXM1L1',
            kind: ActivityKind.lesson,
            result: passing(),
          );

      // FR-039: el almacén local es la fuente de verdad, la nube es respaldo.
      expect(store.current('u1', 'xx')!.activityScores, hasLength(1));
      expect(
        container.read(studentProgressProvider).value!.activityScores,
        hasLength(1),
      );
    });

    test('un toque antes de cargar no rompe ni inventa progreso', () async {
      // El progreso todavía se está leyendo del disco. Devolver nulo en lugar de
      // lanzar evita que una pulsación temprana rompa la pantalla, y sobre todo
      // evita registrar una actividad sobre un progreso que no es el guardado.
      final RecordedActivity? recorded = await container
          .read(studentProgressProvider.notifier)
          .recordResult(
            activityId: 'XXM1L1',
            kind: ActivityKind.lesson,
            result: passing(),
          );

      expect(recorded, isNull);

      await container.read(studentProgressProvider.future);
      expect(store.current('u1', 'xx')!.activityScores, isEmpty);
    });
  });

  group('aplicar la nivelación', () {
    test('marca lo dominado y persiste', () async {
      container.dispose();
      container = makeContainer(stored: storedProgress());
      await container.read(studentProgressProvider.future);

      await container
          .read(studentProgressProvider.notifier)
          .applyPlacementResult(
            PlacementResult(
              estimatedLevelId: 'B1',
              masteredLevelIds: const <String>['A1'],
              takenAt: today,
            ),
          );

      final StudentProgress saved = store.current('u1', 'xx')!;
      expect(saved.levelStates['A1'], LevelState.mastered);
      expect(saved.placement!.estimatedLevelId, 'B1');
      expect(sync.pushCount, 1);
    });

    test('omitirla deja constancia sin marcar nada', () async {
      container.dispose();
      container = makeContainer(stored: storedProgress());
      await container.read(studentProgressProvider.future);

      await container
          .read(studentProgressProvider.notifier)
          .applyPlacementResult(PlacementResult.skippedAt(today));

      final StudentProgress saved = store.current('u1', 'xx')!;
      expect(saved.placement!.skipped, isTrue);
      expect(saved.levelStates['A1'], LevelState.unlocked);
    });
  });

  group('adoptar lo fusionado', () {
    test('no dispara otra sincronización', () async {
      container.dispose();
      container = makeContainer(stored: storedProgress());
      await container.read(studentProgressProvider.future);

      container
          .read(studentProgressProvider.notifier)
          .adopt(storedProgress().copyWith(xp: 999));

      expect(container.read(studentProgressProvider).value!.xp, 999);
      // Si adoptar escribiera, cada empujón provocaría otro empujón.
      expect(sync.pushCount, 0);
      expect(store.saves, isEmpty);
    });
  });
}

/// Idioma preseleccionado para las pruebas.
class PreselectedCourse extends SelectedCourse {
  @override
  String? build() => 'xx';
}
