/// Cola de repaso en memoria.
///
/// Reproduce las dos propiedades del contrato que importan para la interfaz: la
/// siembra es **idempotente** y `dueCards` solo devuelve lo que vence hoy o
/// antes. Un doble más permisivo que el real dejaría pasar pruebas que fallan en
/// producción, que es exactamente lo que ocurrió con el doble de voz.
library;

import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/vocabulary_item.dart';
import 'package:languages_app/services/review/review_store.dart';

class FakeReviewStore implements ReviewStore {
  FakeReviewStore({List<ReviewCard> cards = const <ReviewCard>[]}) {
    for (final ReviewCard card in cards) {
      _cards['${card.moduleId}|${card.term}'] = card;
    }
  }

  final Map<String, ReviewCard> _cards = <String, ReviewCard>{};

  /// Claves de los módulos sembrados, en orden, con repeticiones.
  ///
  /// Se guardan las llamadas y no solo el resultado para poder comprobar que
  /// abrir un módulo bloqueado **no** siembra nada.
  final List<String> seedCalls = <String>[];

  /// Tarjetas guardadas tras calificarlas, en orden.
  final List<ReviewCard> saved = <ReviewCard>[];

  List<ReviewCard> get allCards => _cards.values.toList(growable: false);

  @override
  Future<void> seedModule({
    required String uid,
    required String courseId,
    required String moduleId,
    required List<VocabularyItem> vocabulary,
    required DateTime today,
  }) async {
    seedCalls.add(moduleId);
    for (final VocabularyItem item in vocabulary) {
      final String key = '$moduleId|${item.term}';
      // Idempotente: lo que ya existe no se toca, igual que el `insertOrIgnore`
      // de la base.
      _cards.putIfAbsent(
        key,
        () => ReviewCard(
          moduleId: moduleId,
          term: item.term,
          translation: item.translation,
          intervalStep: 0,
          dueDate: dateOnly(today),
        ),
      );
    }
  }

  @override
  Future<List<ReviewCard>> dueCards({
    required String uid,
    required String courseId,
    required DateTime today,
  }) async =>
      (_cards.values.where((ReviewCard c) => c.isDue(today)).toList()..sort(
            (ReviewCard a, ReviewCard b) => a.dueDate.compareTo(b.dueDate),
          ))
          .toList(growable: false);

  @override
  Future<int> dueCount({
    required String uid,
    required String courseId,
    required DateTime today,
  }) async => _cards.values.where((ReviewCard c) => c.isDue(today)).length;

  @override
  Future<void> save({
    required String uid,
    required String courseId,
    required ReviewCard card,
  }) async {
    saved.add(card);
    _cards[card.key] = card;
  }

  @override
  Future<int> totalCount({
    required String uid,
    required String courseId,
  }) async => _cards.length;
}
