/// Relación de **este dispositivo** con la nube.
///
/// No se sincroniza nunca: describe el estado local, no el progreso del
/// estudiante. Si viajara, un dispositivo le contaría a otro sus propios
/// errores de red, que no significan nada allí.
library;

class SyncState {
  const SyncState({
    this.lastSyncedAt,
    this.hasPendingChanges = false,
    this.lastError,
    this.storageDegraded = false,
  });

  /// Nulo si nunca se ha sincronizado.
  final DateTime? lastSyncedAt;

  /// Hay progreso local que todavía no llegó a la nube.
  final bool hasPendingChanges;

  /// Motivo del último fallo de sincronización, para mostrarlo.
  ///
  /// Existe porque FR-043 prohíbe fallar en silencio: si no se pudo guardar o
  /// sincronizar, el estudiante tiene que poder enterarse.
  final String? lastError;

  /// El almacenamiento local falló y se está usando memoria volátil.
  ///
  /// Mientras sea true, el avance de esta sesión se pierde al cerrar la app, y
  /// la interfaz debe decirlo con claridad.
  final bool storageDegraded;

  /// Si hay algo que el estudiante deba saber.
  bool get needsAttention => storageDegraded || lastError != null;

  SyncState copyWith({
    DateTime? lastSyncedAt,
    bool? hasPendingChanges,
    String? lastError,
    bool clearError = false,
    bool? storageDegraded,
  }) => SyncState(
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
    lastError: clearError ? null : (lastError ?? this.lastError),
    storageDegraded: storageDegraded ?? this.storageDegraded,
  );
}
