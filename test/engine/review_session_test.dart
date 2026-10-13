/// Verifica la mecánica de una tanda de repaso, sin montar widgets.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/engine/review_session.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 7);

  ReviewCard cardFor(String term) => ReviewCard(
    moduleId: 'A1M1',
    term: term,
    translation: 'traducción de $term',
    intervalStep: 0,
    dueDate: today,
  );

  List<ReviewCard> queueOf(int n) => <ReviewCard>[
    for (int i = 1; i <= n; i++) cardFor('palabra$i'),
  ];

  test('empieza en la primera tarjeta', () {
    final ReviewSession session = ReviewSession.start(queue: queueOf(3));

    expect(session.currentIndex, 0);
    expect(session.totalCount, 3);
    expect(session.currentCard!.term, 'palabra1');
    expect(session.isComplete, isFalse);
    expect(session.progress, 0);
  });

  test('calificar avanza y devuelve la tarjeta reprogramada', () {
    final ReviewSession session = ReviewSession.start(queue: queueOf(3));

    final ReviewCard graded = session.grade(RecallGrade.hard, today);

    expect(graded.term, 'palabra1');
    expect(graded.intervalStep, 1, reason: 'la reprogramó el planificador');
    expect(session.currentCard!.term, 'palabra2');
    expect(session.currentIndex, 1);
  });

  test('una tarjeta olvidada no reaparece en la misma tanda', () {
    // Reinsertarla al final convertiría un repaso de tres en uno de cuatro
    // justo el día en que la persona va peor.
    final ReviewSession session = ReviewSession.start(queue: queueOf(3));

    session.grade(RecallGrade.forgotten, today);
    session.grade(RecallGrade.hard, today);
    session.grade(RecallGrade.easy, today);

    expect(session.isComplete, isTrue);
    expect(session.totalCount, 3);
  });

  test('cuenta recordadas y olvidadas por separado', () {
    final ReviewSession session = ReviewSession.start(queue: queueOf(4));

    session.grade(RecallGrade.easy, today);
    session.grade(RecallGrade.forgotten, today);
    session.grade(RecallGrade.hard, today);
    session.grade(RecallGrade.forgotten, today);

    expect(session.recalledCount, 2);
    expect(session.forgottenCount, 2);
    // No hay porcentaje ni veredicto: un repaso no se aprueba ni se suspende.
    expect(session.isComplete, isTrue);
  });

  test('el progreso recorre de 0 a 1', () {
    final ReviewSession session = ReviewSession.start(queue: queueOf(4));
    final List<double> seen = <double>[session.progress];

    while (!session.isComplete) {
      session.grade(RecallGrade.hard, today);
      seen.add(session.progress);
    }

    expect(seen, <double>[0, 0.25, 0.5, 0.75, 1]);
  });

  test('una cola vacía nace completa y no se queda al 0 %', () {
    // La pantalla no debería abrirse así (FR-030), pero si lo hace, un
    // indicador de progreso clavado en cero parece una app colgada.
    final ReviewSession session = ReviewSession.start(
      queue: const <ReviewCard>[],
    );

    expect(session.isComplete, isTrue);
    expect(session.currentCard, isNull);
    expect(session.progress, 1);
  });

  test('calificar una tanda terminada es un error de programación', () {
    final ReviewSession session = ReviewSession.start(queue: queueOf(1));
    session.grade(RecallGrade.hard, today);

    expect(() => session.grade(RecallGrade.hard, today), throwsStateError);
  });

  test('la cola recibida no se puede alterar desde fuera', () {
    // Si la pantalla mutara la lista que pasó, el contador «3 de 10» mentiría.
    final List<ReviewCard> original = queueOf(2);
    final ReviewSession session = ReviewSession.start(queue: original);

    original.add(cardFor('intrusa'));

    expect(session.totalCount, 2);
  });
}
