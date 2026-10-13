/// Doble de [SyncService] que simula red caída, documento ausente y emisiones
/// en vivo.
///
/// Fusiona con la **misma** `mergeProgress` que la implementación real, para que
/// las pruebas que lo usan ejerciten el comportamiento verdadero y no una
/// aproximación.
library;

import 'dart:async';

import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/core/sync_state.dart';
import 'package:languages_app/engine/progress_merger.dart';
import 'package:languages_app/services/sync/sync_service.dart';

class FakeSyncService implements SyncService {
  FakeSyncService({StudentProgress? remote, this.offline = false})
    : _remote = remote;

  /// Si es true, toda operación de red falla.
  bool offline;

  StudentProgress? _remote;

  final StreamController<StudentProgress> _remoteChanges =
      StreamController<StudentProgress>.broadcast();
  final StreamController<SyncState> _status =
      StreamController<SyncState>.broadcast();

  SyncState _currentStatus = const SyncState();

  /// Cuántas veces se empujó, para comprobar la idempotencia desde fuera.
  int pushCount = 0;

  /// El documento remoto actual, para inspeccionarlo en las aserciones.
  StudentProgress? get remote => _remote;

  @override
  SyncState get currentStatus => _currentStatus;

  @override
  Stream<SyncState> get syncStatus => _status.stream;

  @override
  Stream<StudentProgress> remoteChanges({
    required String uid,
    required String courseId,
  }) => _remoteChanges.stream;

  @override
  Future<StudentProgress?> pull({
    required String uid,
    required String courseId,
  }) async {
    if (offline) throw StateError('sin conexión');
    return _remote;
  }

  @override
  Future<StudentProgress> pushMerged(StudentProgress local) async {
    pushCount++;
    if (offline) {
      _emitStatus(
        _currentStatus.copyWith(
          hasPendingChanges: true,
          lastError: 'sin conexión',
        ),
      );
      throw StateError('sin conexión');
    }

    final StudentProgress? current = _remote;
    final StudentProgress merged = current == null
        ? local
        : mergeProgress(local, current);
    _remote = merged;
    _emitStatus(SyncState(lastSyncedAt: DateTime.now()));
    return merged;
  }

  /// True si el documento remoto se borró.
  bool remoteDeleted = false;

  @override
  Future<void> deleteRemote({
    required String uid,
    required String courseId,
  }) async {
    if (offline) throw StateError('sin conexión');
    remoteDeleted = true;
    _remote = null;
    _emitStatus(SyncState(lastSyncedAt: DateTime.now()));
  }

  /// Simula que otro dispositivo escribió en la nube.
  void emitRemoteChange(StudentProgress progress) {
    _remote = progress;
    _remoteChanges.add(progress);
  }

  void _emitStatus(SyncState state) {
    _currentStatus = state;
    _status.add(state);
  }

  Future<void> dispose() async {
    await _remoteChanges.close();
    await _status.close();
  }
}
