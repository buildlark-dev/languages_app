/// Una tarjeta de la cola de repetición espaciada.
///
/// Es la relación entre un estudiante y un ítem de vocabulario: qué sabe de él y
/// cuándo conviene volver a preguntárselo.
library;

import 'clock.dart';
import 'thresholds.dart';

class ReviewCard {
  const ReviewCard({
    required this.moduleId,
    required this.term,
    required this.translation,
    required this.intervalStep,
    required this.dueDate,
    this.lapses = 0,
  });

  /// Parte de la clave compuesta.
  final String moduleId;

  /// Parte de la clave compuesta.
  final String term;

  final String translation;

  /// Índice en [srsIntervals], de 0 a [maxSrsStep].
  final int intervalStep;

  /// Fecha en que vuelve a tocar, sin hora.
  final DateTime dueDate;

  /// Cuántas veces se ha fallado. Diagnóstico, no afecta la programación.
  final int lapses;

  /// Clave estable de la tarjeta.
  String get key => '$moduleId|$term';

  /// Si toca repasarla en la fecha dada.
  bool isDue(DateTime today) => !dateOnly(dueDate).isAfter(dateOnly(today));

  ReviewCard copyWith({
    int? intervalStep,
    DateTime? dueDate,
    int? lapses,
    String? translation,
  }) => ReviewCard(
    moduleId: moduleId,
    term: term,
    translation: translation ?? this.translation,
    intervalStep: intervalStep ?? this.intervalStep,
    dueDate: dueDate ?? this.dueDate,
    lapses: lapses ?? this.lapses,
  );

  /// Fusiona dos versiones de la misma tarjeta.
  ///
  /// Toma el paso de intervalo mayor y la **fecha de vencimiento más próxima**.
  /// Lo segundo es deliberado y va en contra de la intuición de "conservar lo
  /// más avanzado": ante la duda se repasa antes, porque repasar de más cuesta
  /// treinta segundos y no repasar lo que se estaba olvidando cuesta el
  /// aprendizaje.
  ReviewCard mergeWith(ReviewCard other) {
    assert(key == other.key, 'Solo se fusionan tarjetas de la misma clave');
    final DateTime earlier = dueDate.isBefore(other.dueDate)
        ? dueDate
        : other.dueDate;
    return ReviewCard(
      moduleId: moduleId,
      term: term,
      translation: translation,
      intervalStep: intervalStep > other.intervalStep
          ? intervalStep
          : other.intervalStep,
      dueDate: earlier,
      lapses: lapses > other.lapses ? lapses : other.lapses,
    );
  }
}

/// Cómo recordó el estudiante una palabra.
///
/// Tres grados en lugar de acierto o fallo: distinguir "me costó" de "fue
/// inmediato" permite espaciar más rápido lo que ya está consolidado, sin
/// obligar al estudiante a repasar noventa veces lo que ya sabe.
enum RecallGrade {
  /// No la recordó. Reinicia el intervalo.
  forgotten,

  /// La recordó con esfuerzo. Avanza un paso.
  hard,

  /// La recordó de inmediato. Avanza dos pasos.
  easy,
}
