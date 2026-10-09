/// Identificador de la compilación que se está ejecutando.
///
/// No es la versión de la app —eso es `appVersion` en `app_info.dart`, y cambia
/// cuando cambia el producto—, sino **qué build concreto** se está ejecutando:
/// cambia en cada publicación aunque no cambie una sola línea de contenido.
///
/// Lo inyecta el script de despliegue con `--dart-define=BUILD_ID=...`, y el
/// mismo valor queda escrito en `build-id.json` junto al paquete. Comparar los
/// dos es cómo la app sabe que hay una versión nueva, y hace falta porque una
/// PWA instalada no se cierra nunca: sin cerrarla, el navegador no cambia de
/// versión por su cuenta y el estudiante se queda con la de hace semanas.
///
/// El valor por defecto `dev` es deliberado: en `flutter run` y en las pruebas
/// no hay nada publicado con qué comparar, y la comprobación debe quedarse
/// callada en lugar de inventarse una actualización.
library;

const String appBuildId = String.fromEnvironment(
  'BUILD_ID',
  defaultValue: 'dev',
);

/// Si tiene sentido preguntar por versiones nuevas.
///
/// Sin identificador de compilación no hay comparación posible.
bool get buildIsPublished => appBuildId != 'dev' && appBuildId.isNotEmpty;
