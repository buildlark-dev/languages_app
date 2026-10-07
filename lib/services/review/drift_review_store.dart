/// Implementación de [ReviewStore] sobre la base local.
///
/// Es deliberadamente delgada: todas las consultas y el índice `idx_review_due`
/// viven en [ReviewDao], y aquí solo se cumple el contrato. Esa delgadez es la
/// que hace que cambiar de almacén no obligue a tocar la interfaz.
library;

import '../../core/review_card.dart';
import '../../core/vocabulary_item.dart';
import '../db/review_dao.dart';
import 'review_store.dart';

class DriftReviewStore implements ReviewStore {
  const DriftReviewStore(this._dao);

  final ReviewDao _dao;

  @override
  Future<void> seedModule({
    required String uid,
    required String courseId,
    required String moduleId,
    required List<VocabularyItem> vocabulary,
    required DateTime today,
  }) => _dao.seed(
    uid: uid,
    courseId: courseId,
    moduleId: moduleId,
    vocabulary: vocabulary,
    today: today,
  );

  @override
  Future<List<ReviewCard>> dueCards({
    required String uid,
    required String courseId,
    required DateTime today,
  }) => _dao.dueOn(uid: uid, courseId: courseId, today: today);

  @override
  Future<int> dueCount({
    required String uid,
    required String courseId,
    required DateTime today,
  }) => _dao.dueCountOn(uid: uid, courseId: courseId, today: today);

  @override
  Future<void> save({
    required String uid,
    required String courseId,
    required ReviewCard card,
  }) => _dao.upsert(uid: uid, courseId: courseId, card: card);

  @override
  Future<int> totalCount({required String uid, required String courseId}) =>
      _dao.totalCount(uid: uid, courseId: courseId);
}
