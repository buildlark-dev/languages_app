/// Estado del progreso y de su sincronización.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync_state.dart';
import '../../services/sync/sync_service.dart';

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
