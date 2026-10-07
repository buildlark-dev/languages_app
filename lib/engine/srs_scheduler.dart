/// Cuándo volver a preguntar una palabra.
///
/// Es una función pura: recibe la tarjeta, cómo se recordó y la fecha de hoy, y
/// devuelve la tarjeta nueva. No consulta el reloj del sistema ni toca la base,
/// y por eso una prueba puede recorrer noventa días en milisegundos.
///
/// El calendario vive en `core/thresholds.dart` (`srsIntervals`), no aquí: es
/// una regla de producto, y los umbrales están centralizados.
library;

import '../core/clock.dart';
import '../core/review_card.dart';
import '../core/thresholds.dart';

/// Programa la próxima aparición de [card] tras calificarla con [grade].
///
/// Las tres calificaciones hacen cosas distintas a propósito:
///
/// * `hard` avanza **un** paso. Es el camino normal.
/// * `easy` avanza **dos**. Sin ese atajo, consolidar una palabra que ya se sabe
///   exigiría seis repasos, y el estudiante acabaría contestando en automático.
/// * `forgotten` **reinicia** al primer intervalo. No baja un paso: si la
///   palabra se fue de la memoria, el espaciado que la perdió no sirve, y bajar
///   de 35 a 16 días la volvería a perder.
///
/// Los dos avances topan en [maxSrsStep], así que una palabra consolidada
/// reaparece cada 90 días para siempre. Nunca sale de la cola: que algo se
/// supiera hace tres meses no garantiza que se sepa hoy.
ReviewCard gradeCard({
  required ReviewCard card,
  required RecallGrade grade,
  required DateTime today,
}) {
  final int requested = switch (grade) {
    RecallGrade.forgotten => 0,
    RecallGrade.hard => card.intervalStep + 1,
    RecallGrade.easy => card.intervalStep + 2,
  };

  final int step = requested.clamp(0, maxSrsStep);

  return card.copyWith(
    intervalStep: step,
    // La fecha se cuenta desde HOY, no desde el vencimiento anterior. Quien
    // abandona una semana y vuelve no encuentra la cola desfasada hacia atrás:
    // el repaso de hoy cuenta desde hoy.
    dueDate: addDays(today, srsIntervals[step]),
    lapses: grade == RecallGrade.forgotten ? card.lapses + 1 : card.lapses,
  );
}
