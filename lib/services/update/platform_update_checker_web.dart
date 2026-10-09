/// Comprobación de versión en el navegador.
///
/// Toda la parte de JavaScript vive en `web/index.html`, y eso es deliberado:
/// quien hace la comprobación puede ser el paquete **viejo**, así que el
/// mecanismo tiene que seguir existiendo aunque el Dart que se está ejecutando
/// sea de hace semanas. Dejarlo en el HTML lo mantiene fuera del paquete que
/// caduca.
///
/// Aquí solo queda la decisión: comparar lo publicado con lo compilado y
/// contestar. Si algo falla —sin red, sin `build-id.json`, sin `appUpdate`—, la
/// respuesta es «no hay nada nuevo». No saberlo nunca debe presentarse como una
/// actualización disponible.
library;

import 'dart:js_interop';

import '../../core/app_build.dart';
import 'update_checker.dart';

@JS('appUpdate')
external JSObject? get _appUpdate;

@JS('appUpdate.currentBuildId')
external JSPromise<JSString> _currentBuildId();

@JS('appUpdate.apply')
external JSPromise<JSAny?> _applyUpdate();

class WebUpdateChecker implements UpdateChecker {
  const WebUpdateChecker();

  @override
  Future<bool> isUpdateAvailable() async {
    // Sin identificador de compilación no hay comparación: pasa en
    // `flutter run` y en cualquier build hecho sin el script de despliegue.
    if (!buildIsPublished || _appUpdate == null) return false;

    try {
      final String published = (await _currentBuildId().toDart).toDart;
      return published.isNotEmpty && published != appBuildId;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> apply() async {
    if (_appUpdate == null) return;
    try {
      await _applyUpdate().toDart;
    } catch (_) {
      // La recarga es lo último que hace `apply` en JavaScript, así que llegar
      // aquí significa que no recargó. No queda nada que intentar desde Dart.
    }
  }
}

UpdateChecker createUpdateChecker() => const WebUpdateChecker();
