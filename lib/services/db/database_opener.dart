/// Apertura de la base con degradación controlada.
///
/// FR-043 prohíbe fallar en silencio: si el almacenamiento no funciona —disco
/// lleno, permisos, corrupción, navegación privada— el estudiante tiene que
/// poder seguir usando la app **y** enterarse de que su avance no se guarda.
///
/// Este archivo no importa nada específico de plataforma a propósito: recibe las
/// dos fábricas y así se puede compilar y probar en cualquier destino. Quien
/// elige la implementación concreta es la raíz de composición.
library;

import 'app_database.dart';

/// Resultado de intentar abrir el almacén.
class DatabaseOpenResult {
  const DatabaseOpenResult({
    required this.database,
    required this.degraded,
    this.error,
  });

  /// La base utilizable. Nunca es nula: si la primaria falla, es la de reserva.
  final AppDatabase database;

  /// True si se está usando la reserva volátil.
  ///
  /// Mientras sea true, lo que el estudiante haga en esta sesión se pierde al
  /// cerrar la app, y la interfaz debe decirlo.
  final bool degraded;

  /// Motivo del fallo, para mostrarlo y para diagnóstico.
  final String? error;
}

/// Abre el almacén, cayendo a [openFallback] si [openPrimary] no funciona.
///
/// No basta con que el constructor no lance: drift abre la base de forma
/// perezosa, así que una ruta sin permisos o un archivo corrupto no dan error
/// hasta la primera consulta. Por eso aquí se ejecuta una consulta trivial para
/// **probar** que la base responde antes de declararla buena.
Future<DatabaseOpenResult> openAppDatabase({
  required AppDatabase Function() openPrimary,
  required AppDatabase Function() openFallback,
}) async {
  AppDatabase? primary;
  try {
    primary = openPrimary();
    await primary.customSelect('SELECT 1').get();
    return DatabaseOpenResult(database: primary, degraded: false);
  } catch (error) {
    // Cerrar la primaria a medio abrir, si llegó a construirse, para no dejar
    // un descriptor de archivo colgando.
    if (primary != null) {
      try {
        await primary.close();
      } catch (_) {
        // Si tampoco se puede cerrar, no hay nada mejor que hacer: lo que
        // importa es seguir hacia la reserva.
      }
    }
    return DatabaseOpenResult(
      database: openFallback(),
      degraded: true,
      error: error.toString(),
    );
  }
}
