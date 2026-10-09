/// Plataformas que no se actualizan desde dentro de la app.
///
/// Android y escritorio reciben la versión nueva por su propio canal —la
/// tienda, el APK, el instalador—, así que aquí no hay nada que comprobar y
/// decirlo con un `NoUpdateChecker` es más honesto que un aviso que nunca
/// aparecería.
library;

import 'update_checker.dart';

UpdateChecker createUpdateChecker() => const NoUpdateChecker();
