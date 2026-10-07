/// Verifica que un almacenamiento roto degrada en vez de romper la app.
library;

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/services/db/app_database.dart';
import 'package:languages_app/services/db/database_opener.dart';
import 'package:languages_app/services/db/progress_dao.dart';

/// Ejecutor que falla en la primera consulta.
///
/// Reproduce el caso real: drift abre de forma perezosa, así que un disco lleno o
/// una ruta sin permisos no dan error al construir, sino al consultar. Un opener
/// que solo mirara el constructor daría la base por buena.
class _BrokenExecutor extends drift.QueryExecutor {
  @override
  drift.QueryExecutor beginExclusive() => this;

  @override
  drift.TransactionExecutor beginTransaction() =>
      throw UnsupportedError('almacenamiento no disponible');

  @override
  Future<bool> ensureOpen(drift.QueryExecutorUser user) async =>
      throw StateError('disco lleno');

  @override
  Future<void> runBatched(drift.BatchedStatements statements) async =>
      throw StateError('disco lleno');

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async =>
      throw StateError('disco lleno');

  @override
  Future<int> runDelete(String statement, List<Object?> args) async =>
      throw StateError('disco lleno');

  @override
  Future<int> runInsert(String statement, List<Object?> args) async =>
      throw StateError('disco lleno');

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async => throw StateError('disco lleno');

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async =>
      throw StateError('disco lleno');

  @override
  Future<void> close() async {}

  @override
  drift.SqlDialect get dialect => drift.SqlDialect.sqlite;
}

void main() {
  test('un almacenamiento sano no degrada', () async {
    final DatabaseOpenResult result = await openAppDatabase(
      openPrimary: () => AppDatabase.withExecutor(NativeDatabase.memory()),
      openFallback: () =>
          fail('No debe recurrir a la reserva si la primaria funciona'),
    );

    expect(result.degraded, isFalse);
    expect(result.error, isNull);
    await result.database.close();
  });

  test(
    'un almacenamiento roto degrada a la reserva y conserva el motivo',
    () async {
      final DatabaseOpenResult result = await openAppDatabase(
        openPrimary: () => AppDatabase.withExecutor(_BrokenExecutor()),
        openFallback: () => AppDatabase.withExecutor(NativeDatabase.memory()),
      );

      expect(result.degraded, isTrue);
      expect(
        result.error,
        contains('disco lleno'),
        reason:
            'El motivo debe llegar a la interfaz: FR-043 prohíbe el silencio',
      );

      await result.database.close();
    },
  );

  test('la app sigue usable sobre la reserva', () async {
    final DatabaseOpenResult result = await openAppDatabase(
      openPrimary: () => AppDatabase.withExecutor(_BrokenExecutor()),
      openFallback: () => AppDatabase.withExecutor(NativeDatabase.memory()),
    );

    // Lo que importa de la degradación: el estudiante puede seguir estudiando.
    final ProgressDao dao = ProgressDao(result.database);
    await dao.save(
      StudentProgress.initial(uid: 'u1', courseId: 'en', firstLevelId: 'A1'),
    );

    final StudentProgress? loaded = await dao.load(uid: 'u1', courseId: 'en');
    expect(loaded, isNotNull);
    expect(loaded!.currentLevelId, 'A1');

    await result.database.close();
  });
}
