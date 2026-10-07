/// Recorre el calendario de repetición espaciada con el reloj inyectado.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/thresholds.dart';
import 'package:languages_app/engine/srs_scheduler.dart';

void main() {
  final DateTime day1 = DateTime(2026, 1, 1);

  ReviewCard freshCard({int step = 0, int lapses = 0}) => ReviewCard(
    moduleId: 'A1M1',
    term: 'name',
    translation: 'el nombre',
    intervalStep: step,
    dueDate: day1,
    lapses: lapses,
  );

  group('avance de intervalo', () {
    test('recordada con esfuerzo avanza un paso', () {
      final ReviewCard graded = gradeCard(
        card: freshCard(),
        grade: RecallGrade.hard,
        today: day1,
      );

      expect(graded.intervalStep, 1);
      // srsIntervals[1] == 3
      expect(graded.dueDate, DateTime(2026, 1, 4));
      expect(graded.lapses, 0);
    });

    test('recordada con facilidad avanza dos pasos', () {
      final ReviewCard graded = gradeCard(
        card: freshCard(),
        grade: RecallGrade.easy,
        today: day1,
      );

      expect(graded.intervalStep, 2);
      // srsIntervals[2] == 7
      expect(graded.dueDate, DateTime(2026, 1, 8));
    });

    test('la fecha se cuenta desde hoy, no desde el vencimiento anterior', () {
      // La tarjeta venció el 1 y el estudiante vuelve el 20. Si el intervalo se
      // sumara al vencimiento, la fecha nueva ya estaría en el pasado y la
      // palabra reaparecería de inmediato.
      final DateTime late = DateTime(2026, 1, 20);
      final ReviewCard graded = gradeCard(
        card: freshCard(),
        grade: RecallGrade.hard,
        today: late,
      );

      expect(graded.dueDate, DateTime(2026, 1, 23));
      expect(graded.isDue(late), isFalse);
    });
  });

  group('reinicio al fallar', () {
    test('no recordada vuelve al primer intervalo y cuenta el fallo', () {
      final ReviewCard graded = gradeCard(
        card: freshCard(step: 4, lapses: 2),
        grade: RecallGrade.forgotten,
        today: day1,
      );

      expect(graded.intervalStep, 0);
      expect(graded.dueDate, DateTime(2026, 1, 2), reason: 'hoy mas un dia');
      expect(graded.lapses, 3);
    });

    test('no baja un paso, reinicia', () {
      // Bajar de 35 a 16 días conservaría el espaciado que ya falló.
      final ReviewCard graded = gradeCard(
        card: freshCard(step: maxSrsStep),
        grade: RecallGrade.forgotten,
        today: day1,
      );

      expect(graded.intervalStep, 0);
      expect(srsIntervals[graded.intervalStep], 1);
    });

    test('acertar no incrementa los fallos acumulados', () {
      final ReviewCard graded = gradeCard(
        card: freshCard(lapses: 5),
        grade: RecallGrade.easy,
        today: day1,
      );

      expect(graded.lapses, 5);
    });
  });

  group('tope en el último intervalo', () {
    test('con esfuerzo desde el último paso se queda en el último', () {
      final ReviewCard graded = gradeCard(
        card: freshCard(step: maxSrsStep),
        grade: RecallGrade.hard,
        today: day1,
      );

      expect(graded.intervalStep, maxSrsStep);
      expect(daysBetween(day1, graded.dueDate), 90);
    });

    test('con facilidad desde el penúltimo no se desborda', () {
      final ReviewCard graded = gradeCard(
        card: freshCard(step: maxSrsStep - 1),
        grade: RecallGrade.easy,
        today: day1,
      );

      expect(graded.intervalStep, maxSrsStep);
    });

    test('una palabra consolidada nunca sale de la cola', () {
      // El tope son 90 días, no «nunca más»: saber algo en marzo no garantiza
      // saberlo en junio.
      ReviewCard card = freshCard(step: maxSrsStep);
      for (int i = 0; i < 10; i++) {
        card = gradeCard(
          card: card,
          grade: RecallGrade.easy,
          today: card.dueDate,
        );
        expect(card.intervalStep, maxSrsStep);
      }
    });
  });

  group('recorrido con el reloj inyectado', () {
    test('acertando siempre con esfuerzo se recorre la escalera completa', () {
      ReviewCard card = freshCard();
      DateTime today = day1;
      final List<int> gaps = <int>[];

      // Seis repasos: cinco para subir del paso 0 al 5, y uno más ya en el tope.
      for (int i = 0; i < srsIntervals.length; i++) {
        card = gradeCard(card: card, grade: RecallGrade.hard, today: today);
        gaps.add(daysBetween(today, card.dueDate));
        // El estudiante repasa el día exacto en que vence.
        today = card.dueDate;
      }

      expect(gaps, <int>[3, 7, 16, 35, 90, 90]);
      expect(card.intervalStep, maxSrsStep);
      // Los seis saltos acumulados: 3+7+16+35+90+90 = 241 días. El quinto
      // repaso cae en el día 151, cuando la palabra ya alcanzó el tope, y de
      // ahí en adelante reaparece cada 90 días.
      expect(daysBetween(day1, today), 241);
    });

    test('un fallo a mitad de la escalera devuelve al día siguiente', () {
      ReviewCard card = freshCard();
      DateTime today = day1;

      for (int i = 0; i < 3; i++) {
        card = gradeCard(card: card, grade: RecallGrade.hard, today: today);
        today = card.dueDate;
      }
      expect(card.intervalStep, 3);

      card = gradeCard(card: card, grade: RecallGrade.forgotten, today: today);

      expect(card.intervalStep, 0);
      expect(daysBetween(today, card.dueDate), 1);
      expect(card.isDue(addDays(today, 1)), isTrue);
    });

    test('la identidad de la tarjeta sobrevive a todo el recorrido', () {
      ReviewCard card = freshCard();
      DateTime today = day1;
      const List<RecallGrade> walk = <RecallGrade>[
        RecallGrade.hard,
        RecallGrade.easy,
        RecallGrade.forgotten,
        RecallGrade.hard,
        RecallGrade.easy,
      ];

      for (final RecallGrade grade in walk) {
        card = gradeCard(card: card, grade: grade, today: today);
        today = card.dueDate;
      }

      // La clave es lo que une la tarjeta local con la remota: si cambiara, la
      // fusión crearía una tarjeta nueva y el estudiante perdería su memoria.
      expect(card.key, 'A1M1|name');
      expect(card.translation, 'el nombre');
      expect(card.lapses, 1);
    });
  });

  group('higiene de fechas', () {
    test('la fecha de vencimiento siempre es una medianoche', () {
      final ReviewCard graded = gradeCard(
        card: freshCard(),
        grade: RecallGrade.hard,
        // Una hora cualquiera de la tarde, como la de un repaso real.
        today: DateTime(2026, 1, 1, 14, 32, 9),
      );

      expect(graded.dueDate, DateTime(2026, 1, 4));
      expect(graded.dueDate, dateOnly(graded.dueDate));
    });

    test('cruzar fin de mes y fin de año no se desvía', () {
      final ReviewCard graded = gradeCard(
        card: freshCard(step: 4),
        grade: RecallGrade.hard,
        today: DateTime(2026, 12, 20),
      );

      // 20 de diciembre más 90 días son el 20 de marzo de 2027.
      expect(graded.dueDate, DateTime(2027, 3, 20));
    });
  });
}
