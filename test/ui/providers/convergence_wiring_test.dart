/// Comprueba que las piezas **se llaman**, no solo que existan.
///
/// Es la prueba que faltaba cuando `/speckit-converge` encontró seis servicios
/// construidos, probados y nunca invocados. Cada caso de aquí monta la app por
/// sus proveedores reales y afirma que la llamada ocurre sola, sin que ninguna
/// pantalla concreta tenga que acordarse de hacerla.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/app.dart';
import 'package:languages_app/services/settings/settings_store.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/services/auth/auth_service.dart';
import 'package:languages_app/services/backup/json_backup_service.dart';
import 'package:languages_app/ui/providers/auth_providers.dart';
import 'package:languages_app/ui/providers/backup_providers.dart';
import 'package:languages_app/ui/providers/clock_providers.dart';
import 'package:languages_app/ui/providers/content_providers.dart';
import 'package:languages_app/ui/providers/progress_controller.dart';
import 'package:languages_app/ui/providers/progress_providers.dart';
import 'package:languages_app/ui/providers/review_providers.dart';
import 'package:languages_app/ui/providers/speech_providers.dart';

import '../../fakes/fake_auth_service.dart';
import '../../fakes/fake_catalog.dart';
import '../../fakes/fake_progress_store.dart';
import '../../fakes/fake_review_store.dart';
import '../../fakes/fake_stt_service.dart';
import '../../fakes/fake_sync_service.dart';
import '../../fakes/fake_tts_service.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 8);

  late FakeProgressStore store;
  late FakeSyncService sync;
  late FakeTtsService tts;
  late FakeSttService stt;

  StudentProgress stored({int xp = 50}) => StudentProgress(
    uid: 'u1',
    courseId: 'xx',
    currentLevelId: 'A1',
    xp: xp,
    levelStates: const <String, LevelState>{'A1': LevelState.unlocked},
  );

  /// Contenedor con curso elegido y sesión abierta.
  ///
  /// `withCourse: false` deja el catálogo sin elegir, que es el estado de la
  /// pantalla de acceso.
  ProviderContainer makeContainer({
    StudentProgress? progress,
    bool withCourse = true,
  }) {
    store = FakeProgressStore(initial: progress);
    sync = FakeSyncService();
    tts = FakeTtsService();
    stt = FakeSttService();

    final ProviderContainer container = ProviderContainer(
      overrides: [
        progressStoreProvider.overrideWithValue(store),
        backupServiceProvider.overrideWithValue(
          JsonBackupService(store, clock: fixedClock(today)),
        ),
        reviewStoreProvider.overrideWithValue(FakeReviewStore()),
        syncServiceProvider.overrideWithValue(sync),
        ttsServiceProvider.overrideWithValue(tts),
        sttServiceProvider.overrideWithValue(stt),
        // Preparar la voz aplica ahora la velocidad guardada, así que el
        // almacén de preferencias hace falta: antes se perdía en cada
        // arranque porque nadie la volvía a aplicar.
        settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
        clockProvider.overrideWithValue(fixedClock(today)),
        courseCatalogProvider.overrideWithValue(const FakeCatalog()),
        if (withCourse)
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
    addTearDown(container.dispose);
    return container;
  }

  /// Deja correr las tareas diferidas que disparan el cableado.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('T181 · la voz se prepara sola', () {
    test('con un curso abierto, el audio queda disponible', () async {
      // Antes, `prepare()` no se llamaba desde ningún sitio y la app no
      // reproducía audio nunca, con el motor de voz entero detrás.
      final ProviderContainer container = makeContainer();
      final ProviderSubscription<Object?> sub = container.listen(
        speechAvailabilityProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await settle();

      expect(tts.initializedWith, 'xx-XX', reason: 'el idioma del curso');
      expect(container.read(speechAvailabilityProvider).canPlayAudio, isTrue);
    });

    test('sin curso elegido no se prepara nada', () async {
      // En la pantalla de acceso no hay idioma que preparar, y consultar las
      // voces del sistema allí solo retrasaría el primer fotograma.
      final ProviderContainer container = makeContainer(withCourse: false);
      final ProviderSubscription<Object?> sub = container.listen(
        speechAvailabilityProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await settle();

      expect(tts.initializedWith, isNull);
      expect(container.read(speechAvailabilityProvider).canPlayAudio, isFalse);
    });
  });

  group('T183 · se sincroniza al entrar', () {
    test(
      'cargar el progreso pide una sincronización sin esperar actividad',
      () async {
        // Antes había que completar una actividad para que la primera fusión
        // ocurriera: una instalación nueva mostraba el progreso vacío hasta
        // entonces.
        final ProviderContainer container = makeContainer(progress: stored());
        final ProviderSubscription<Object?> sub = container.listen(
          studentProgressProvider,
          (_, _) {},
        );
        addTearDown(sub.close);

        await container.read(studentProgressProvider.future);
        await settle();

        expect(sync.pushCount, greaterThanOrEqualTo(1));
      },
    );

    test('trae lo que ya había en la nube', () async {
      final ProviderContainer container = makeContainer(progress: stored());
      sync.emitRemoteChange(stored(xp: 900));
      final ProviderSubscription<Object?> sub = container.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await container.read(studentProgressProvider.future);
      await settle();
      await settle();

      expect(container.read(studentProgressProvider).value!.xp, 900);
      expect(store.current('u1', 'xx')!.xp, 900);
    });
  });

  group('T184 · se escucha el documento remoto (SC-004)', () {
    test('un cambio del otro dispositivo llega sin recargar', () async {
      final ProviderContainer container = makeContainer(progress: stored());
      final ProviderSubscription<Object?> sub = container.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await container.read(studentProgressProvider.future);
      await settle();
      expect(container.read(studentProgressProvider).value!.xp, 50);

      // El otro dispositivo escribe en la nube mientras este está ocioso.
      sync.emitRemoteChange(stored(xp: 400));
      await settle();
      await settle();

      expect(
        container.read(studentProgressProvider).value!.xp,
        400,
        reason: 'sin recargar ni reiniciar',
      );
      expect(store.current('u1', 'xx')!.xp, 400, reason: 'y queda en disco');
    });

    test('lo que llega se fusiona, no reemplaza', () async {
      // Un remoto con menos XP no puede hacer retroceder al local.
      final ProviderContainer container = makeContainer(
        progress: stored(xp: 500),
      );
      final ProviderSubscription<Object?> sub = container.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await container.read(studentProgressProvider.future);
      await settle();

      sync.emitRemoteChange(stored(xp: 10));
      await settle();
      await settle();

      expect(
        container.read(studentProgressProvider).value!.xp,
        greaterThanOrEqualTo(500),
      );
    });
  });

  group('T186 · los disparadores que faltaban', () {
    test('volver del segundo plano reintenta', () async {
      final ProviderContainer container = makeContainer(progress: stored());
      final ProviderSubscription<Object?> sub = container.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(studentProgressProvider.future);
      await settle();

      // El empujón de entrada falló porque no había red; al volver sí la hay.
      final int before = sync.pushCount;
      await container.read(studentProgressProvider.notifier).syncOnResume();

      expect(sync.pushCount, greaterThan(before));
    });

    test('pasar a segundo plano empuja lo pendiente', () async {
      final ProviderContainer container = makeContainer(progress: stored());
      final ProviderSubscription<Object?> sub = container.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(studentProgressProvider.future);
      await settle();

      final int before = sync.pushCount;
      await container.read(studentProgressProvider.notifier).syncOnPause();

      expect(sync.pushCount, greaterThan(before));
    });

    test('un fallo sin red no rompe nada y el avance local sigue', () async {
      sync = FakeSyncService();
      final ProviderContainer container = makeContainer(progress: stored());
      sync.offline = true;
      final ProviderSubscription<Object?> sub = container.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await container.read(studentProgressProvider.future);
      await settle();
      await container.read(studentProgressProvider.notifier).syncOnResume();

      expect(container.read(studentProgressProvider).value!.xp, 50);
      expect(store.current('u1', 'xx')!.xp, 50);
    });
  });
  group('T187 · borrar el progreso permanece (FR-046)', () {
    /// Deja correr la sincronización de entrada que sigue al borrado.
    Future<void> settleSync() async {
      await settle();
      await settle();
      await settle();
    }

    test('tras borrar, la sincronización NO lo devuelve', () async {
      // La regresión que introdujo T183: el documento remoto sobrevivía al
      // borrado, el progreso se reconstruía, pedía la sincronización de
      // entrada y volvía entero. La pantalla ya había dicho que se borró.
      final ProviderContainer container = makeContainer(
        progress: stored(xp: 777),
      );
      sync.emitRemoteChange(stored(xp: 777));
      final ProviderSubscription<Object?> sub = container.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await container.read(studentProgressProvider.future);
      await settleSync();
      expect(container.read(studentProgressProvider).value!.xp, 777);

      await container.read(backupControllerProvider.notifier).wipe();
      await container.read(studentProgressProvider.future);
      await settleSync();

      expect(sync.remoteDeleted, isTrue, reason: 'también en la nube');
      expect(
        container.read(studentProgressProvider).value!.xp,
        0,
        reason: 'y no vuelve',
      );
      expect(store.current('u1', 'xx')!.xp, 0);
    });

    test('sin red no se borra nada y se dice por qué', () async {
      // Quedarse a medias —local vacío, nube llena— es el estado que produce
      // justo el engaño que esto corrige.
      final ProviderContainer container = makeContainer(
        progress: stored(xp: 777),
      );
      final ProviderSubscription<Object?> sub = container.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(studentProgressProvider.future);
      await settleSync();

      sync.offline = true;
      await container.read(backupControllerProvider.notifier).wipe();

      expect(
        container.read(backupControllerProvider).lastAction,
        BackupAction.wipeFailed,
      );
      expect(sync.remoteDeleted, isFalse);
      expect(store.current('u1', 'xx')!.xp, 777, reason: 'lo local intacto');
    });

    test('el borrado deja el curso listo para empezar de nuevo', () async {
      final ProviderContainer container = makeContainer(
        progress: stored(xp: 777),
      );
      final ProviderSubscription<Object?> sub = container.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(studentProgressProvider.future);
      await settleSync();

      await container.read(backupControllerProvider.notifier).wipe();
      final StudentProgress? after = await container.read(
        studentProgressProvider.future,
      );

      expect(after!.currentLevelId, 'A1');
      expect(after.levelStates['A1'], LevelState.unlocked);
      expect(after.activityScores, isEmpty);
    });
  });

  group('T188 · el alcance real del borrado', () {
    test('otro dispositivo con copia local vuelve a subir lo suyo', () async {
      // Fija la limitación elegida, en lugar de dejarla sin escribir. La
      // fusión monotónica no distingue «esto se borró» de «a ese dispositivo
      // le falta esto», así que el borrado no se propaga. El diálogo lo dice y
      // explica qué hacer; esta prueba es la que avisará si alguien cambia el
      // comportamiento sin cambiar el texto.
      final FakeProgressStore otherStore = FakeProgressStore(
        initial: stored(xp: 777),
      );
      final FakeSyncService cloud = FakeSyncService(remote: stored(xp: 777));

      final ProviderContainer otherDevice = ProviderContainer(
        overrides: [
          progressStoreProvider.overrideWithValue(otherStore),
          reviewStoreProvider.overrideWithValue(FakeReviewStore()),
          syncServiceProvider.overrideWithValue(cloud),
          ttsServiceProvider.overrideWithValue(FakeTtsService()),
          sttServiceProvider.overrideWithValue(FakeSttService()),
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
      addTearDown(otherDevice.dispose);
      final ProviderSubscription<Object?> sub = otherDevice.listen(
        studentProgressProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await otherDevice.read(studentProgressProvider.future);
      await settle();

      // Este dispositivo borra: la nube queda vacía.
      await cloud.deleteRemote(uid: 'u1', courseId: 'xx');
      expect(cloud.remote, isNull);

      // El otro vuelve del segundo plano y sube su copia.
      await otherDevice.read(studentProgressProvider.notifier).syncOnResume();
      await settle();

      expect(
        cloud.remote?.xp,
        777,
        reason:
            'comportamiento conocido y declarado en el diálogo: hay que '
            'borrar también en el otro dispositivo',
      );
    });
  });
}

/// Idioma preseleccionado.
class PreselectedCourse extends SelectedCourse {
  @override
  String? build() => 'xx';
}
