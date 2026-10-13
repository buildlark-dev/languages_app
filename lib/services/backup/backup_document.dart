/// Forma del archivo de respaldo.
///
/// El progreso va dentro con **la misma serialización** que el documento remoto
/// (`sync/progress_document.dart`). No es ahorro de código: significa que un
/// respaldo se puede comparar a ojo con lo que hay en Firestore, y que no existe
/// un segundo formato que pueda quedarse desfasado del primero.
///
/// Alrededor del progreso van cuatro campos de sobre:
///
/// * `backupVersion` — el formato del sobre. Sirve para **rechazar** un archivo
///   de una versión futura en lugar de interpretarlo mal.
/// * `appVersion` — qué versión lo escribió. Diagnóstico.
/// * `courseId` — para no importar el progreso de inglés en el curso de francés.
/// * `exportedAt` — cuándo se hizo. Se muestra al importar, porque «de hace tres
///   meses» es información que cambia la decisión.
///
/// `uid` **no** va en el archivo. Un respaldo es del estudiante que lo importa,
/// no del que lo exportó: guardar el identificador invitaría a comprobarlo, y
/// entonces alguien que rehiciera su cuenta no podría recuperar su propio
/// avance.
library;

import 'dart:convert';

import '../../core/student_progress.dart';
import '../sync/progress_document.dart';

/// Versión del formato del sobre que esta app escribe y entiende.
const int currentBackupVersion = 1;

class BackupDocument {
  const BackupDocument({
    required this.courseId,
    required this.exportedAt,
    required this.appVersion,
    required this.progress,
    this.backupVersion = currentBackupVersion,
  });

  final int backupVersion;
  final String appVersion;
  final String courseId;
  final DateTime exportedAt;
  final StudentProgress progress;

  Map<String, Object?> toMap() => <String, Object?>{
    'backupVersion': backupVersion,
    'appVersion': appVersion,
    'courseId': courseId,
    'exportedAt': exportedAt.toIso8601String(),
    'progress': progressToMap(progress),
  };

  /// JSON con sangría.
  ///
  /// Sangrado a propósito: el archivo lo puede abrir la persona que lo exportó,
  /// y un respaldo que se puede leer es un respaldo en el que se confía.
  String toJson() => const JsonEncoder.withIndent('  ').convert(toMap());

  /// Reconstruye un respaldo desde su mapa.
  ///
  /// Quien llama debe haber validado antes el sobre: aquí ya se asume que
  /// `backupVersion` es soportado y que `courseId` es el correcto. La validación
  /// está en `BackupService.parse` porque es ahí donde hay que poder explicar el
  /// motivo del rechazo sin haber tocado nada.
  static BackupDocument fromMap(
    Map<String, Object?> map, {
    required String uid,
  }) {
    final String courseId = map['courseId'] as String? ?? '';
    final Object? progress = map['progress'];

    return BackupDocument(
      backupVersion: (map['backupVersion'] as num?)?.toInt() ?? 0,
      appVersion: map['appVersion'] as String? ?? 'desconocida',
      courseId: courseId,
      exportedAt:
          DateTime.tryParse(map['exportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      progress: progressFromMap(
        progress is Map
            ? progress.map(
                (Object? k, Object? v) => MapEntry<String, Object?>('$k', v),
              )
            : <String, Object?>{},
        uid: uid,
        courseId: courseId,
      ),
    );
  }
}
