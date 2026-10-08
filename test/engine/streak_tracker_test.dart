/// Recorre la racha diaria con el reloj inyectado.
///
/// El último grupo es el importante: comprueba que la fusión de rachas es
/// conmutativa, asociativa e idempotente, y **demuestra con un contraejemplo**
/// que encadenar rachas de días consecutivos rompería la asociatividad. Ese
/// contraejemplo está en la prueba y no solo en un comentario para que nadie
/// reintente el recálculo posterior creyendo que es una mejora.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/engine/streak_tracker.dart';

void main() {
  final DateTime day1 = DateTime(2026, 10, 7);

  StreakPoint pointOn(DateTime date, int count) =>
      StreakPoint(date: date, count: count);

  group('avance diario', () {
    test('la primera actividad da 1', () {
      final StreakAdvance advance = advanceStreak(
        current: StreakPoint.none,
        today: day1,
      );

      expect(advance.point.count, 1);
      expect(advance.point.date, day1);
      expect(advance.increased, isTrue);
    });

    test('un día consecutivo da N+1', () {
      final StreakAdvance advance = advanceStreak(
        current: pointOn(day1, 4),
        today: addDays(day1, 1),
      );

      expect(advance.point.count, 5);
      expect(advance.increased, isTrue);
    });

    test('dos lecciones el mismo día NO incrementan dos veces', () {
      // Si contara, la racha sería un contador de lecciones con otro nombre.
      final StreakAdvance first = advanceStreak(
        current: StreakPoint.none,
        today: day1,
      );
      final StreakAdvance second = advanceStreak(
        current: first.point,
        today: day1,
      );

      expect(second.point.count, 1);
      expect(second.increased, isFalse);
    });

    test('la hora del día no cuenta como día distinto', () {
      final StreakAdvance advance = advanceStreak(
        current: pointOn(day1, 3),
        today: DateTime(2026, 10, 7, 23, 59),
      );

      expect(advance.point.count, 3);
      expect(advance.increased, isFalse);
      expect(advance.point.date, day1, reason: 'la fecha queda sin hora');
    });

    test('dos días sin actividad reinicia a 1, no a 0', () {
      // A 1 porque hoy sí se estudió: empezar en cero no contaría el día en
      // curso.
      final StreakAdvance advance = advanceStreak(
        current: pointOn(day1, 12),
        today: addDays(day1, 2),
      );

      expect(advance.point.count, 1);
      expect(advance.increased, isTrue);
    });

    test('un mes sin actividad también reinicia a 1', () {
      final StreakAdvance advance = advanceStreak(
        current: pointOn(day1, 30),
        today: addDays(day1, 45),
      );

      expect(advance.point.count, 1);
    });

    test('una fecha con contador en cero cuenta como hoy', () {
      // Puede llegar así de un progreso importado. Mostrar cero a quien acaba de
      // estudiar sería un cero visiblemente falso.
      final StreakAdvance advance = advanceStreak(
        current: pointOn(day1, 0),
        today: day1,
      );

      expect(advance.point.count, 1);
    });
  });

  group('cambio de mes y de año', () {
    test('del 31 al 1 del mes siguiente es consecutivo', () {
      final StreakAdvance advance = advanceStreak(
        current: pointOn(DateTime(2026, 10, 31), 6),
        today: DateTime(2026, 11, 1),
      );

      expect(advance.point.count, 7);
    });

    test('del 28 de febrero al 1 de marzo, año no bisiesto', () {
      final StreakAdvance advance = advanceStreak(
        current: pointOn(DateTime(2026, 2, 28), 2),
        today: DateTime(2026, 3, 1),
      );

      expect(advance.point.count, 3);
    });

    test(
      'del 28 de febrero al 1 de marzo en año bisiesto NO es consecutivo',
      () {
        // 2028 tiene 29 de febrero: ese día se perdió.
        final StreakAdvance advance = advanceStreak(
          current: pointOn(DateTime(2028, 2, 28), 2),
          today: DateTime(2028, 3, 1),
        );

        expect(advance.point.count, 1);
      },
    );

    test('del 31 de diciembre al 1 de enero es consecutivo', () {
      final StreakAdvance advance = advanceStreak(
        current: pointOn(DateTime(2026, 12, 31), 9),
        today: DateTime(2027, 1, 1),
      );

      expect(advance.point.count, 10);
    });

    test('un recorrido de 40 días seguidos cruza dos meses sin desviarse', () {
      StreakPoint point = StreakPoint.none;
      DateTime today = DateTime(2026, 11, 20);

      for (int i = 0; i < 40; i++) {
        point = advanceStreak(current: point, today: today).point;
        today = addDays(today, 1);
      }

      expect(point.count, 40);
      expect(point.date, DateTime(2026, 12, 29));
    });
  });

  group('lo que se muestra hoy', () {
    test('la racha vive el mismo día y el siguiente', () {
      final StreakPoint point = pointOn(day1, 5);

      expect(point.isAliveOn(day1), isTrue);
      expect(point.isAliveOn(addDays(day1, 1)), isTrue);
      expect(point.isAliveOn(addDays(day1, 2)), isFalse);
    });

    test('una racha rota se muestra como cero, no como su último valor', () {
      // El contador solo se toca al estudiar, así que sin esto la pantalla diría
      // «5 días seguidos» a quien no estudia desde el mes pasado.
      final StreakPoint point = pointOn(day1, 5);

      expect(point.displayCountOn(addDays(day1, 1)), 5);
      expect(point.displayCountOn(addDays(day1, 30)), 0);
    });

    test('sin ninguna actividad no hay racha', () {
      expect(StreakPoint.none.isAliveOn(day1), isFalse);
      expect(StreakPoint.none.displayCountOn(day1), 0);
    });

    test('distingue si hoy ya cuenta', () {
      final StreakPoint point = pointOn(day1, 3);

      expect(point.includesToday(day1), isTrue);
      expect(point.includesToday(addDays(day1, 1)), isFalse);
    });
  });

  group('fusión entre dispositivos', () {
    test('gana el dispositivo que estudió más recientemente', () {
      // Racha 7 del lunes contra racha 1 del jueves: gana el jueves. Decir
      // «siete días seguidos» a quien faltó dos sería incumplir FR-032 de forma
      // visible.
      final StreakPoint merged = mergeStreak(
        pointOn(day1, 7),
        pointOn(addDays(day1, 3), 1),
      );

      expect(merged.count, 1);
      expect(merged.date, addDays(day1, 3));
    });

    test('en empate de fecha gana el contador mayor', () {
      final StreakPoint merged = mergeStreak(
        pointOn(day1, 2),
        pointOn(day1, 9),
      );

      expect(merged.count, 9);
    });

    test('un dispositivo sin actividad no borra la racha del otro', () {
      expect(mergeStreak(StreakPoint.none, pointOn(day1, 4)).count, 4);
      expect(mergeStreak(pointOn(day1, 4), StreakPoint.none).count, 4);
    });

    test('es conmutativa, asociativa e idempotente', () {
      final List<StreakPoint> points = <StreakPoint>[
        StreakPoint.none,
        pointOn(day1, 1),
        pointOn(day1, 7),
        pointOn(addDays(day1, 1), 2),
        pointOn(addDays(day1, 5), 1),
      ];

      for (final StreakPoint a in points) {
        expect(mergeStreak(a, a), a, reason: 'idempotente');

        for (final StreakPoint b in points) {
          expect(mergeStreak(a, b), mergeStreak(b, a), reason: 'conmutativa');

          for (final StreakPoint c in points) {
            expect(
              mergeStreak(mergeStreak(a, b), c),
              mergeStreak(a, mergeStreak(b, c)),
              reason: 'asociativa',
            );
          }
        }
      }
    });

    test('encadenar días consecutivos rompería la asociatividad', () {
      // El contraejemplo que descarta el «recálculo tras fusionar» del plan
      // original. Tres dispositivos con racha 1 en días consecutivos:
      final StreakPoint p1 = pointOn(day1, 1);
      final StreakPoint p2 = pointOn(addDays(day1, 1), 1);
      final StreakPoint p3 = pointOn(addDays(day1, 2), 1);

      /// Fusión hipotética que SÍ encadena rachas consecutivas.
      StreakPoint chaining(StreakPoint a, StreakPoint b) {
        if (a.date == null) return b;
        if (b.date == null) return a;
        final int gap = daysBetween(a.date!, b.date!);
        if (gap == 1) {
          final int chained = a.count + 1;
          return StreakPoint(
            date: b.date,
            count: chained > b.count ? chained : b.count,
          );
        }
        if (gap > 0) return b;
        if (gap < 0) return a;
        return a.count >= b.count ? a : b;
      }

      // Agrupando por la izquierda encadena los tres días; por la derecha, el
      // primero queda a dos días del resultado y se descarta.
      expect(chaining(chaining(p1, p2), p3).count, 3);
      expect(chaining(p1, chaining(p2, p3)).count, 2);

      // La fusión de verdad no tiene ese problema porque no encadena.
      expect(
        mergeStreak(mergeStreak(p1, p2), p3),
        mergeStreak(p1, mergeStreak(p2, p3)),
      );
    });
  });
}
