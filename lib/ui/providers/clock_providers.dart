/// El reloj, inyectado también en la interfaz.
///
/// El motor ya recibe su [Clock] por parámetro (Principio V), pero las pantallas
/// también razonan en días: cuántas palabras vencen **hoy**, si la racha sigue
/// viva. Si llamaran a `DateTime.now()` directamente, una prueba de widget no
/// podría situarse en una fecha concreta y tendría que montar la pantalla con lo
/// que el reloj de la máquina dijera ese día, que es como se escriben las
/// pruebas que fallan el 31 de diciembre.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';

/// Reloj de la interfaz. En producción es el del sistema; las pruebas lo
/// sobrescriben con [fixedClock].
final Provider<Clock> clockProvider = Provider<Clock>((Ref ref) => systemClock);
