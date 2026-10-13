/// Contrato de respaldo, importación y borrado (FR-045, FR-046).
///
/// Dos obligaciones que el contrato impone por su propia forma:
///
/// 1. **Importar fusiona, nunca reemplaza.** No existe una operación que
///    sobrescriba el progreso con el del archivo. Un respaldo de hace tres meses
///    no puede hacer retroceder a quien ya avanzó más, y la única forma de
///    garantizarlo es no ofrecer la operación que lo permitiría. Es la misma
///    decisión que en `SyncService`, por el mismo motivo.
/// 2. **Validar antes de tocar nada.** [BackupService.parse] no escribe: separa
///    el archivo bueno del malo y, cuando es malo, dice por qué. Solo lo que
///    pasa por ahí llega a [BackupService.import].
library;

import '../../core/student_progress.dart';
import 'backup_document.dart';

abstract interface class BackupService {
  /// Arma el respaldo del progreso actual, o nulo si no hay nada que respaldar.
  Future<BackupDocument?> export({
    required String uid,
    required String courseId,
  });

  /// El archivo, listo para guardar.
  String serialize(BackupDocument document);

  /// Valida un archivo **sin aplicar nada**.
  ///
  /// [expectedCourseId] es el curso abierto: un respaldo de otro idioma se
  /// rechaza aquí, no después de haber mezclado vocabulario inglés en el
  /// progreso de francés.
  BackupParseResult parse(
    String raw, {
    required String uid,
    required String expectedCourseId,
  });

  /// Fusiona el respaldo con el progreso existente y guarda el resultado.
  ///
  /// Devuelve lo fusionado, que es lo que la interfaz debe adoptar.
  Future<StudentProgress> import(
    BackupDocument document, {
    required String uid,
  });

  /// Borra el progreso local del estudiante en un curso (FR-046).
  Future<void> wipe({required String uid, required String courseId});
}

/// Resultado de validar un archivo de respaldo.
///
/// Es una jerarquía `sealed` y no un enum con un mensaje porque cada caso lleva
/// datos distintos —el documento, la versión encontrada, el curso ajeno— y
/// porque un `switch` exhaustivo obliga a la pantalla a dar un mensaje a cada
/// uno. Un enum con un `String` dejaría que alguien mostrara «error» a los
/// cuatro.
sealed class BackupParseResult {
  const BackupParseResult();
}

/// El archivo es válido y se puede importar.
class BackupValid extends BackupParseResult {
  const BackupValid(this.document);

  final BackupDocument document;
}

/// El formato del sobre es más nuevo que el que esta app entiende.
///
/// Se rechaza en lugar de intentarlo: interpretar un formato desconocido con
/// reglas viejas es la forma de corromper el progreso creyendo que se recupera.
class BackupUnsupportedVersion extends BackupParseResult {
  const BackupUnsupportedVersion({
    required this.found,
    required this.supported,
  });

  final int found;
  final int supported;
}

/// No es un respaldo: no es JSON, o no tiene la forma de uno.
class BackupMalformed extends BackupParseResult {
  const BackupMalformed(this.reason);

  /// Motivo técnico, para el mensaje y para diagnóstico.
  final String reason;
}

/// Es un respaldo válido, pero de otro idioma.
class BackupWrongCourse extends BackupParseResult {
  const BackupWrongCourse({required this.found, required this.expected});

  final String found;
  final String expected;
}
