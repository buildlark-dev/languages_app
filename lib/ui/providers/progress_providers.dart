/// Estado del progreso y de su sincronización.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/student_progress.dart';
import '../../core/sync_state.dart';
import '../../services/progress/progress_store.dart';
import '../../services/sync/sync_scheduler.dart';
import '../../services/sync/sync_service.dart';
import 'progress_controller.dart';
import 'scope_providers.dart';

/// El servicio concreto. **Se sobrescribe en `main.dart`.**
final Provider<SyncService> syncServiceProvider = Provider<SyncService>(
  (Ref ref) => throw UnimplementedError(
    'syncServiceProvider debe sobrescribirse en main.dart',
  ),
);

/// Si el almacenamiento local falló y el progreso no se está guardando.
///
/// Se decide al arrancar, en `main.dart`, y no cambia durante la sesión: si la
/// base no se pudo abrir, no se vuelve a intentar a mitad de una lección.
final Provider<bool> storageDegradedProvider = Provider<bool>(
  (Ref ref) => false,
);

/// Estado de la sincronización, para el aviso de la pantalla.
///
/// Arranca con el estado actual del servicio en lugar de esperar la primera
/// emisión, de modo que el aviso aparece desde el primer fotograma si ya había
/// algo que decir.
final StreamProvider<SyncState> syncStateProvider = StreamProvider<SyncState>((
  Ref ref,
) {
  final SyncService service = ref.watch(syncServiceProvider);
  return service.syncStatus;
});

/// Resumen de lo que la interfaz debe avisar.
enum SyncNotice {
  /// Nada que decir.
  none,

  /// Hay avance sin subir, o un empujón en curso.
  pending,

  /// El último intento falló. Se reintentará.
  failed,

  /// El almacenamiento local no funciona: esta sesión se perderá.
  storageDegraded,
}

/// Qué aviso corresponde ahora mismo.
///
/// El orden de prioridad importa: un almacenamiento roto es más grave que una
/// sincronización pendiente, porque lo primero pierde el avance de la sesión y lo
/// segundo solo lo retrasa.
final Provider<SyncNotice> syncNoticeProvider = Provider<SyncNotice>((Ref ref) {
  if (ref.watch(storageDegradedProvider)) return SyncNotice.storageDegraded;

  final SyncState? state = ref.watch(syncStateProvider).value;
  if (state == null) return SyncNotice.none;
  if (state.lastError != null) return SyncNotice.failed;
  if (state.hasPendingChanges) return SyncNotice.pending;
  return SyncNotice.none;
});

/// El almacén local de progreso. **Se sobrescribe en `main.dart`.**
final Provider<ProgressStore> progressStoreProvider = Provider<ProgressStore>(
  (Ref ref) => throw UnimplementedError(
    'progressStoreProvider debe sobrescribirse en main.dart',
  ),
);

/// La política de cuándo sincronizar.
///
/// Lee y escribe el progreso a través del controlador, no directamente, para que
/// lo fusionado que vuelve de la nube quede en pantalla además de en disco. Las
/// lecturas van dentro de las devoluciones de llamada y no en el cuerpo del
/// proveedor: así no hay ciclo entre el planificador y el progreso, que de otro
/// modo se construirían el uno al otro.
final Provider<SyncScheduler> syncSchedulerProvider = Provider<SyncScheduler>((
  Ref ref,
) {
  final SyncService service = ref.watch(syncServiceProvider);
  return SyncScheduler(
    push: service.pushMerged,
    readLocal: () => ref.read(studentProgressProvider).value,
    writeLocal: (StudentProgress merged) async {
      await ref.read(progressStoreProvider).save(merged);
      ref.read(studentProgressProvider.notifier).adopt(merged);
    },
  );
});

/// El documento remoto, escuchado en vivo mientras la app está abierta.
///
/// Es lo que hace alcanzable SC-004: un segundo dispositivo ocioso recibe el
/// avance en segundos **sin recargar ni reiniciar**. Sin esta suscripción,
/// todos los disparadores de sincronización son acciones locales y un
/// dispositivo inactivo nunca se enteraría de nada.
///
/// El servicio existía desde la Historia 1 y nadie lo escuchaba: el criterio
/// estaba construido y desconectado.
final StreamProvider<StudentProgress> remoteProgressProvider =
    StreamProvider<StudentProgress>((Ref ref) {
      final StudentScope? scope = ref.watch(studentScopeProvider);
      if (scope == null) return const Stream<StudentProgress>.empty();

      return ref
          .watch(syncServiceProvider)
          .remoteChanges(uid: scope.uid, courseId: scope.courseId);
    });
