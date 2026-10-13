/// Calla la voz al cambiar de pantalla.
///
/// Reportado al verificar: un texto largo seguía sonando después de pasar al
/// ejercicio siguiente o de salir a otra pantalla. Y no es un detalle estético:
/// quien toca «escuchar» en una lectura y se va al ejercicio se queda con una
/// voz hablando encima de lo que intenta leer, sin ningún control a mano para
/// pararla —el botón que la arrancó ya no está en pantalla—.
///
/// ## Por qué un observador de rutas y no una llamada en cada pantalla
///
/// Porque la lista de pantallas que reproducen audio crece, y la que se olvide
/// de llamar a `stop` reaparece el fallo. Un observador lo resuelve **una vez**
/// para toda la app: cualquier `push`, `pop` o `replace` calla lo que estuviera
/// sonando, incluidas las rutas que todavía no existen.
///
/// Es el mismo razonamiento que hizo que la disponibilidad de voz se preparase
/// al abrir el curso y no desde cada pantalla: lo que depende de que alguien se
/// acuerde, falla el día que alguien no se acuerda.
library;

import 'package:flutter/widgets.dart';

class SpeechRouteObserver extends NavigatorObserver {
  SpeechRouteObserver(this._stop);

  /// Qué hacer para callar. Se recibe como función y no como servicio para que
  /// el observador no dependa de Riverpod ni de una implementación concreta.
  final VoidCallback _stop;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) =>
      _stop();

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) => _stop();

  @override
  void didReplace({Route<Object?>? newRoute, Route<Object?>? oldRoute}) =>
      _stop();

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) =>
      _stop();
}
