/// La racha diaria: cuántos días seguidos se ha estudiado.
///
/// Está en su propio archivo porque la consumen **dos** sitios con necesidades
/// distintas: `progress_recorder.dart`, que la avanza al terminar una actividad,
/// y `progress_merger.dart`, que tiene que decidir qué racha sobrevive cuando
/// dos dispositivos traen la suya. Tenerla repartida entre los dos era tener la
/// regla de FR-032 en dos sitios.
///
/// ## Por qué NO hay recálculo tras fusionar
///
/// El plan original decía «fusionar la racha por máximo y después recalcularla
/// contra la fecha de última actividad». Al escribirlo resultó imposible de
/// hacer bien, y conviene dejar el contraejemplo escrito para que nadie lo
/// reintente:
///
/// Tres dispositivos estudian en días consecutivos, cada uno con racha 1.
/// Si al fusionar se encadenaran las rachas consecutivas:
///
///     (d1,1) ∘ (d2,1) = (d2,2)   y luego  (d2,2) ∘ (d3,1) = (d3,3)
///     (d2,1) ∘ (d3,1) = (d3,2)   y luego  (d1,1) ∘ (d3,2) = (d3,2)
///
/// Tres contra dos: **el resultado depende del orden de sincronización**, y eso
/// es perder la asociatividad, que es justo la propiedad que hace que varios
/// dispositivos converjan. El motivo de fondo es que encadenar necesita saber a
/// qué fecha pertenecía cada racha, y la fusión conserva una sola fecha.
///
/// La regla vigente, [mergeStreak], trata la racha y su fecha como **un par** y
/// toma el máximo lexicográfico. Sigue siendo un máximo, así que conserva las
/// tres propiedades, y respeta FR-032 porque una racha caducada no revive.
///
/// El precio es conocido y se acepta: alguien que estudia el lunes en el
/// teléfono y el martes en el PC sin que se hayan sincronizado entre medias verá
/// racha 1 el martes, no 2. Subestimar la racha de alguien es un disgusto;
/// decirle «siete días seguidos» cuando faltó dos es mentirle, y lo segundo es
/// lo que FR-032 prohíbe.
library;

import '../core/clock.dart';

/// Una racha junto a la fecha a la que pertenece.
///
/// Van juntas porque por separado no significan nada: «racha 7» sin saber de
/// qué día es no permite decidir si sigue viva.
class StreakPoint {
  const StreakPoint({required this.date, required this.count});

  /// Punto de partida de quien no ha estudiado nunca.
  static const StreakPoint none = StreakPoint(date: null, count: 0);

  /// Día de la última actividad, sin hora. Nulo si no hay ninguna.
  final DateTime? date;

  final int count;

  /// Si la racha sigue viva en [today].
  ///
  /// Vive el mismo día y el día siguiente. Al segundo día sin actividad ya está
  /// rota, aunque el contador todavía no se haya tocado: el contador solo se
  /// actualiza al estudiar, así que la interfaz **debe** preguntar por esto
  /// antes de mostrar un número.
  bool isAliveOn(DateTime today) {
    final DateTime? last = date;
    if (last == null) return false;
    return daysBetween(last, today) <= 1;
  }

  /// Lo que se le debe mostrar al estudiante hoy.
  ///
  /// Cero si la racha ya se rompió. Mostrar el último valor conocido sería
  /// decirle que lleva cinco días seguidos a quien no estudia desde el mes
  /// pasado.
  int displayCountOn(DateTime today) => isAliveOn(today) ? count : 0;

  /// Si hoy ya cuenta para la racha.
  ///
  /// Sirve para distinguir «llevas 3 días» de «llevas 3 días, y hoy ya está
  /// hecho», que es la diferencia entre un recordatorio y una felicitación.
  bool includesToday(DateTime today) =>
      date != null && daysBetween(date!, today) == 0;

  @override
  bool operator ==(Object other) =>
      other is StreakPoint && other.date == date && other.count == count;

  @override
  int get hashCode => Object.hash(date, count);
}

/// Lo que una actividad de hoy le hace a la racha.
class StreakAdvance {
  const StreakAdvance({required this.point, required this.increased});

  final StreakPoint point;

  /// Si la racha subió con esta actividad. Falso al repetir el mismo día.
  final bool increased;
}

/// Avanza la racha porque hubo actividad en [today].
///
/// Tres casos, y los tres importan:
///
/// * **Mismo día**: no sube. Completar dos lecciones el martes no son dos días
///   seguidos, y contarlo así convertiría la racha en un contador de lecciones.
/// * **Día siguiente**: sube uno.
/// * **Hueco de dos días o más**: vuelve a 1. No a 0: hoy sí se estudió, y
///   empezar de nuevo desde cero sería no contar el día en curso.
StreakAdvance advanceStreak({
  required StreakPoint current,
  required DateTime today,
}) {
  final DateTime day = dateOnly(today);
  final DateTime? last = current.date;

  if (last == null) {
    return StreakAdvance(
      point: StreakPoint(date: day, count: 1),
      increased: true,
    );
  }

  final int gap = daysBetween(last, day);

  if (gap == 0) {
    // La racha de hoy ya está contada. El `max(1, …)` cubre un progreso
    // importado con fecha pero sin contador, que de otro modo mostraría cero
    // habiendo estudiado hoy.
    final int count = current.count == 0 ? 1 : current.count;
    return StreakAdvance(
      point: StreakPoint(date: day, count: count),
      increased: false,
    );
  }

  if (gap == 1) {
    return StreakAdvance(
      point: StreakPoint(date: day, count: current.count + 1),
      increased: true,
    );
  }

  // Hueco: se perdió al menos un día completo.
  return StreakAdvance(
    point: StreakPoint(date: day, count: 1),
    increased: true,
  );
}

/// Fusiona dos rachas de dos dispositivos.
///
/// Máximo sobre el orden lexicográfico `(date, count)`: gana quien estudió más
/// recientemente, porque su racha es la que refleja el estado actual; en empate
/// de fecha gana el contador mayor, que favorece al estudiante cuando ambos
/// dispositivos se usaron el mismo día.
///
/// Es conmutativa, asociativa e idempotente. El encabezado de este archivo
/// explica por qué no encadena rachas de días consecutivos aunque sería más
/// generoso.
StreakPoint mergeStreak(StreakPoint a, StreakPoint b) {
  if (a.date == null) return b.date == null ? _higherCount(a, b) : b;
  if (b.date == null) return a;

  final int gap = daysBetween(a.date!, b.date!);
  if (gap > 0) return b;
  if (gap < 0) return a;
  return _higherCount(a, b);
}

StreakPoint _higherCount(StreakPoint a, StreakPoint b) =>
    a.count >= b.count ? a : b;
