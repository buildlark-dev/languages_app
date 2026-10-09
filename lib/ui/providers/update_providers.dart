/// Si hay una versión nueva publicada.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_build.dart';
import '../../services/update/update_checker.dart';

/// El comprobador concreto. **Se sobrescribe en `main.dart`.**
///
/// Lanza si falta, como los demás proveedores de servicio. Esa regla se
/// adoptó después de que `settingsStoreProvider` cayera en silencio a una
/// implementación de pruebas durante cuatro revisiones: un olvido de cableado
/// debe fallar en el arranque, no funcionar casi bien.
final Provider<UpdateChecker> updateCheckerProvider = Provider<UpdateChecker>(
  (Ref ref) => throw UnimplementedError(
    'updateCheckerProvider debe sobrescribirse en main.dart',
  ),
);

/// Verdadero cuando lo publicado difiere de lo que se está ejecutando.
///
/// Se comprueba al construir y cada vez que la app vuelve a primer plano, que
/// es cuando alguien la abre. Es un [Notifier] y no un `FutureProvider` porque
/// la respuesta **cambia** durante la sesión: se publica algo mientras la app
/// está abierta, y es justo el caso que hay que cubrir en una PWA instalada
/// que nunca se cierra.
class UpdateAvailability extends Notifier<bool> {
  /// [every] es cada cuánto se vuelve a preguntar; [enabled] si se pregunta.
  ///
  /// Los dos son parámetros para poder probar la repetición sin esperar un
  /// cuarto de hora, y para que en pruebas y en `flutter run` no quede ningún
  /// temporizador vivo: sin identificador de compilación no hay nada que
  /// comparar.
  UpdateAvailability({
    this.every = const Duration(minutes: 15),
    bool? enabled,
  }) : _enabled = enabled ?? buildIsPublished;

  final Duration every;
  final bool _enabled;

  @override
  bool build() {
    if (!_enabled) return false;

    // Se pregunta cada tanto, además de al reanudar.
    //
    // Depender solo de «la app vuelve a primer plano» resultó frágil: en una
    // pestaña que nunca se oculta ese evento no llega nunca, y entonces el
    // aviso no aparece hasta que alguien cierra y abre. Un cuarto de hora es
    // una petición de doscientos bytes: no se nota, y cierra el caso de la
    // PWA que lleva días abierta.
    final Timer timer = Timer.periodic(every, (_) => check());
    ref.onDispose(timer.cancel);

    // Después de construir, no durante: `check` escribe `state`.
    Future<void>(() {
      if (ref.mounted) check();
    });
    return false;
  }

  Future<void> check() async {
    final bool available = await ref
        .read(updateCheckerProvider)
        .isUpdateAvailable();
    // El comprobador hace una petición de red, así que entre la pregunta y la
    // respuesta el contenedor puede haberse desechado.
    if (!ref.mounted) return;
    state = available;
  }

  /// Se queda con la versión publicada. En web no devuelve: recarga.
  Future<void> apply() => ref.read(updateCheckerProvider).apply();
}

final NotifierProvider<UpdateAvailability, bool> updateAvailableProvider =
    NotifierProvider<UpdateAvailability, bool>(UpdateAvailability.new);
