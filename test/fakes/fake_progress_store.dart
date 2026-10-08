/// Almacén de progreso en memoria.
library;

import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/services/progress/progress_store.dart';

class FakeProgressStore implements ProgressStore {
  FakeProgressStore({StudentProgress? initial}) {
    if (initial != null) _byKey['${initial.uid}|${initial.courseId}'] = initial;
  }

  final Map<String, StudentProgress> _byKey = <String, StudentProgress>{};

  /// Cada guardado, en orden. Sirve para comprobar **cuántas** veces se escribe
  /// y en qué orden respecto a la sincronización.
  final List<StudentProgress> saves = <StudentProgress>[];

  /// Si no es nulo, el siguiente guardado falla con esto.
  Object? failNextSave;

  StudentProgress? current(String uid, String courseId) =>
      _byKey['$uid|$courseId'];

  @override
  Future<StudentProgress?> load({
    required String uid,
    required String courseId,
  }) async => _byKey['$uid|$courseId'];

  @override
  Future<void> save(StudentProgress progress) async {
    final Object? failure = failNextSave;
    if (failure != null) {
      failNextSave = null;
      throw failure;
    }
    saves.add(progress);
    _byKey['${progress.uid}|${progress.courseId}'] = progress;
  }

  @override
  Future<void> wipe({required String uid, required String courseId}) async {
    _byKey.remove('$uid|$courseId');
  }
}
