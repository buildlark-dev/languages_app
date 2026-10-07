/// Sincronización contra Cloud Firestore.
///
/// Dos obligaciones gobiernan este archivo:
///
/// 1. **Nunca sobrescribir.** [pushMerged] ejecuta una transacción que lee el
///    documento remoto, lo fusiona con el local mediante `mergeProgress` y
///    escribe el resultado. No hay ningún camino que haga un `set` directo.
/// 2. **Escuchar en vivo.** [remoteChanges] mantiene una suscripción al
///    documento, que es lo que hace cumplible SC-004 sin que nadie recargue.
///
/// Firestore no ofrece una operación `max` sobre campos —solo `increment`— y
/// `increment` sería **erróneo** aquí: dos dispositivos incrementando el XP de
/// forma independiente contarían dos veces la misma actividad. El máximo exige
/// leer antes de escribir, de ahí la transacción.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/student_progress.dart';
import '../../core/sync_state.dart';
import '../../engine/progress_merger.dart';
import 'progress_document.dart';
import 'sync_service.dart';

class FirestoreSyncService implements SyncService {
  FirestoreSyncService(this._firestore);

  final FirebaseFirestore _firestore;

  final StreamController<SyncState> _status =
      StreamController<SyncState>.broadcast();

  SyncState _currentStatus = const SyncState();

  DocumentReference<Map<String, dynamic>> _docFor(
    String uid,
    String courseId,
  ) => _firestore
      .collection('users')
      .doc(uid)
      .collection('courses')
      .doc(courseId);

  @override
  SyncState get currentStatus => _currentStatus;

  @override
  Stream<SyncState> get syncStatus => _status.stream;

  @override
  Future<StudentProgress?> pull({
    required String uid,
    required String courseId,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _docFor(
        uid,
        courseId,
      ).get();
      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) return null;
      return progressFromMap(data, uid: uid, courseId: courseId);
    } catch (error) {
      _emit(_currentStatus.copyWith(lastError: error.toString()));
      rethrow;
    }
  }

  @override
  Future<StudentProgress> pushMerged(StudentProgress local) async {
    final DocumentReference<Map<String, dynamic>> doc = _docFor(
      local.uid,
      local.courseId,
    );

    try {
      final StudentProgress written = await _firestore
          .runTransaction<StudentProgress>((Transaction transaction) async {
            final DocumentSnapshot<Map<String, dynamic>> snapshot =
                await transaction.get(doc);
            final Map<String, dynamic>? data = snapshot.data();

            final StudentProgress merged = data == null
                ? local
                : mergeProgress(
                    local,
                    progressFromMap(
                      data,
                      uid: local.uid,
                      courseId: local.courseId,
                    ),
                  );

            transaction.set(doc, progressToMap(merged));
            return merged;
          });

      _emit(SyncState(lastSyncedAt: DateTime.now()));
      return written;
    } catch (error) {
      // FR-043: el fallo tiene que ser visible. Queda pendiente de reintento.
      _emit(
        _currentStatus.copyWith(
          hasPendingChanges: true,
          lastError: error.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  Stream<StudentProgress> remoteChanges({
    required String uid,
    required String courseId,
  }) => _docFor(uid, courseId)
      .snapshots()
      .where(
        (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
            snapshot.data() != null,
      )
      .map(
        (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
            progressFromMap(snapshot.data()!, uid: uid, courseId: courseId),
      );

  void _emit(SyncState state) {
    _currentStatus = state;
    if (!_status.isClosed) _status.add(state);
  }

  Future<void> dispose() => _status.close();
}
