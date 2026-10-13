/// Implementación de [ProgressStore] sobre la base local.
///
/// Delgada a propósito: la transacción que hace atómico el guardado vive en
/// [ProgressDao.save], donde ya tiene su prueba de atomicidad.
library;

import '../../core/student_progress.dart';
import '../db/progress_dao.dart';
import 'progress_store.dart';

class DriftProgressStore implements ProgressStore {
  const DriftProgressStore(this._dao);

  final ProgressDao _dao;

  @override
  Future<StudentProgress?> load({
    required String uid,
    required String courseId,
  }) => _dao.load(uid: uid, courseId: courseId);

  @override
  Future<void> save(StudentProgress progress) => _dao.save(progress);

  @override
  Future<void> wipe({required String uid, required String courseId}) =>
      _dao.wipe(uid: uid, courseId: courseId);
}
