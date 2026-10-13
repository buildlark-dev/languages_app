/// Una sesión de repaso en curso.
///
/// Es el equivalente de `lesson_session.dart` para la cola de repetición
/// espaciada, y existe por el mismo motivo: la pantalla no debe llevar la cuenta
/// de en qué tarjeta va ni de cuántas se recordaron. Aquí no hay widgets, así
/// que la mecánica completa se prueba sin montar nada.
///
/// Diferencia importante con una lección: **un repaso no se aprueba ni se
/// suspende.** No hay umbral del 70 %. Una tarjeta fallada no es un suspenso,
/// es una tarjeta que vuelve mañana. Por eso esta sesión no produce un
/// `ScoreResult` y no toca el progreso del curso.
library;

import '../core/review_card.dart';
import 'srs_scheduler.dart';

class ReviewSession {
  ReviewSession.start({required List<ReviewCard> queue})
    : _queue = List<ReviewCard>.unmodifiable(queue);

  final List<ReviewCard> _queue;

  int _index = 0;
  int _recalled = 0;
  int _forgotten = 0;

  /// La tarjeta que toca ahora, o nulo si ya se terminó.
  ReviewCard? get currentCard => isComplete ? null : _queue[_index];

  int get currentIndex => _index;

  int get totalCount => _queue.length;

  bool get isComplete => _index >= _queue.length;

  /// Cuántas se recordaron, con esfuerzo o con facilidad.
  int get recalledCount => _recalled;

  /// Cuántas se olvidaron y vuelven mañana.
  int get forgottenCount => _forgotten;

  /// Fracción recorrida, de 0 a 1.
  double get progress => _queue.isEmpty ? 1 : _index / _queue.length;

  /// Califica la tarjeta en curso, avanza, y devuelve la tarjeta reprogramada.
  ///
  /// Quien llama es responsable de persistirla: la sesión es pura y no conoce la
  /// base. Devolverla en lugar de guardarla es lo que permite probar el recorrido
  /// completo sin almacén.
  ///
  /// Una tarjeta olvidada **no vuelve a aparecer en esta misma sesión**. Es
  /// deliberado: reinsertarla al final convertiría un repaso de diez palabras en
  /// uno de veinte justo el día en que la persona va peor, que es el día en que
  /// más fácil es abandonar. El planificador ya la trae mañana.
  ReviewCard grade(RecallGrade grade, DateTime today) {
    final ReviewCard? card = currentCard;
    if (card == null) {
      throw StateError('No hay tarjeta por calificar: la sesión ya terminó');
    }

    if (grade == RecallGrade.forgotten) {
      _forgotten++;
    } else {
      _recalled++;
    }
    _index++;

    return gradeCard(card: card, grade: grade, today: today);
  }
}
