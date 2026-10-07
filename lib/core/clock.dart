/// Fuente de tiempo inyectable.
///
/// El motor NUNCA llama a `DateTime.now()` directamente. Recibe un [Clock] y lo
/// consulta a través de él.
///
/// El motivo es que la racha diaria y los intervalos de repetición espaciada son
/// lógica de fechas: probar "deja pasar un día y la racha se reinicia" con el
/// reloj real exigiría esperar un día o manipular el reloj del sistema. Con el
/// reloj inyectado, una prueba recorre noventa días en milisegundos.
library;

/// Devuelve el instante actual.
typedef Clock = DateTime Function();

/// Reloj de producción: el del sistema operativo.
DateTime systemClock() => DateTime.now();

/// Crea un reloj fijo, para pruebas.
Clock fixedClock(DateTime instant) => () => instant;

/// Trunca un instante a su fecha, descartando la hora.
///
/// La cola de repaso y la racha razonan en días, no en instantes: una palabra
/// vence "el 9 de octubre", no "el 9 de octubre a las 14:32".
DateTime dateOnly(DateTime instant) =>
    DateTime(instant.year, instant.month, instant.day);

/// Días completos entre dos fechas, ignorando la hora.
///
/// Se calcula sobre fechas truncadas a UTC a propósito: restar `DateTime`
/// locales cruza mal los cambios de horario de verano, donde un día puede
/// durar 23 o 25 horas y la diferencia en días sale fraccionaria.
int daysBetween(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  return end.difference(start).inDays;
}
