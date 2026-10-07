/// Consultas propias de la cola de repetición espaciada.
///
/// Están aparte del progreso completo porque la cola se consulta de otra forma:
/// el resto del progreso se carga entero al arrancar, mientras que de la cola
/// solo interesa "qué vence hoy", y eso debe resolverse con un índice en lugar
/// de trayendo miles de filas a memoria.
library;

import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../core/review_card.dart';
import '../../core/vocabulary_item.dart';
import 'app_database.dart';

class ReviewDao {
  ReviewDao(this._db);

  final AppDatabase _db;

  /// Tarjetas que vencen hoy o antes.
  ///
  /// La condición usa `dueDate <= hoy`, que es exactamente el prefijo del índice
  /// `idx_review_due (uid, course_id, due_date)`. Sin ese índice la consulta
  /// degrada a recorrido completo de tabla.
  Future<List<ReviewCard>> dueOn({
    required String uid,
    required String courseId,
    required DateTime today,
  }) async {
    final DateTime cutoff = dateOnly(today);
    final List<ReviewCardRow> rows =
        await (_db.select(_db.reviewCards)
              ..where(
                (t) =>
                    t.uid.equals(uid) &
                    t.courseId.equals(courseId) &
                    t.dueDate.isSmallerOrEqualValue(cutoff),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.dueDate),
              ]))
            .get();

    return rows.map(_toCard).toList(growable: false);
  }

  /// Cuántas tarjetas vencen hoy.
  ///
  /// Cuenta en la base en lugar de traer las filas y medir la lista: la pantalla
  /// principal solo necesita el número.
  Future<int> dueCountOn({
    required String uid,
    required String courseId,
    required DateTime today,
  }) async {
    final DateTime cutoff = dateOnly(today);
    final Expression<int> count = _db.reviewCards.term.count();
    final query =
        _db.selectOnly(_db.reviewCards)
          ..addColumns(<Expression<Object>>[count])
          ..where(
            _db.reviewCards.uid.equals(uid) &
                _db.reviewCards.courseId.equals(courseId) &
                _db.reviewCards.dueDate.isSmallerOrEqualValue(cutoff),
          );
    final TypedResult row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Siembra la cola con el vocabulario de un módulo.
  ///
  /// Las tarjetas que ya existan **no se tocan**: volver a entrar en un módulo no
  /// puede reiniciar el progreso de memoria ya construido. Por eso es
  /// `insertOnConflictUpdate` sobre la fila nueva solo cuando no había ninguna,
  /// resuelto con `DoNothing`.
  Future<void> seed({
    required String uid,
    required String courseId,
    required String moduleId,
    required List<VocabularyItem> vocabulary,
    required DateTime today,
  }) async {
    final DateTime due = dateOnly(today);
    await _db.batch((Batch batch) {
      batch.insertAll(
        _db.reviewCards,
        <ReviewCardRow>[
          for (final VocabularyItem item in vocabulary)
            ReviewCardRow(
              uid: uid,
              courseId: courseId,
              moduleId: moduleId,
              term: item.term,
              translation: item.translation,
              intervalStep: 0,
              dueDate: due,
              lapses: 0,
            ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  /// Guarda el nuevo estado de una tarjeta tras calificarla.
  Future<void> upsert({
    required String uid,
    required String courseId,
    required ReviewCard card,
  }) async {
    await _db.into(_db.reviewCards).insertOnConflictUpdate(
      ReviewCardRow(
        uid: uid,
        courseId: courseId,
        moduleId: card.moduleId,
        term: card.term,
        translation: card.translation,
        intervalStep: card.intervalStep,
        dueDate: card.dueDate,
        lapses: card.lapses,
      ),
    );
  }

  /// Cuántas tarjetas tiene el estudiante en total, vencidas o no.
  Future<int> totalCount({
    required String uid,
    required String courseId,
  }) async {
    final Expression<int> count = _db.reviewCards.term.count();
    final query =
        _db.selectOnly(_db.reviewCards)
          ..addColumns(<Expression<Object>>[count])
          ..where(
            _db.reviewCards.uid.equals(uid) &
                _db.reviewCards.courseId.equals(courseId),
          );
    final TypedResult row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  static ReviewCard _toCard(ReviewCardRow row) => ReviewCard(
    moduleId: row.moduleId,
    term: row.term,
    translation: row.translation,
    intervalStep: row.intervalStep,
    dueDate: row.dueDate,
    lapses: row.lapses,
  );
}
