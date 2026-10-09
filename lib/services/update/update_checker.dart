/// Contrato de «¿hay una versión nueva publicada?».
///
/// ## Por qué existe
///
/// La app desplegada quedó congelada en los dispositivos que ya la tenían: las
/// cabeceras de caché declaraban `immutable` sobre archivos que Flutter **no**
/// versiona por contenido, así que el navegador no volvía a pedirlos en un año.
/// Arreglar las cabeceras es necesario y no es suficiente: una PWA instalada no
/// se cierra nunca, y el navegador solo cambia de versión cuando se cierran
/// todas las ventanas.
///
/// De ahí este contrato: la app pregunta, y cuando hay algo nuevo **lo ofrece**
/// en lugar de recargar sola. Recargar sola tiraría a alguien a mitad de
/// lección, y perder un ejercicio por una mejora de la app es exactamente el
/// tipo de cosa que hace abandonar.
///
/// En Android no aplica: allí la versión la cambia la tienda o el APK, así que
/// la implementación de esa plataforma contesta siempre que no hay nada.
library;

abstract interface class UpdateChecker {
  /// Si lo publicado ahora mismo es distinto de lo que se está ejecutando.
  ///
  /// Nunca lanza: sin conexión, sin respuesta o sin identificador devuelve
  /// `false`. No saberlo no es una actualización.
  Future<bool> isUpdateAvailable();

  /// Se queda con la versión publicada.
  ///
  /// Borra lo guardado y recarga, así que **no devuelve el control** en web.
  Future<void> apply();
}

/// La implementación de las plataformas donde la app no se actualiza sola.
///
/// Devolver «no hay nada» es la respuesta correcta en Android y en escritorio,
/// no una carencia: allí el paquete lo reemplaza el sistema.
class NoUpdateChecker implements UpdateChecker {
  const NoUpdateChecker();

  @override
  Future<bool> isUpdateAvailable() async => false;

  @override
  Future<void> apply() async {}
}
