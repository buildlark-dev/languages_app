/// Respaldo en JSON sobre el almacén local.
///
/// La pieza importante es [import]: usa `mergeProgress`, la **misma** fusión
/// monotónica que la sincronización entre dispositivos. Un respaldo es, para
/// este propósito, otro dispositivo que trae su versión del progreso, y la regla
/// del Principio IV vale igual aquí: nunca se retrocede.
///
/// Esto tiene una consecuencia que conviene decir en voz alta: importar un
/// respaldo **no** restaura el estado exacto del día en que se exportó. Si
/// después se avanzó, lo posterior se conserva. Es lo contrario de lo que la
/// palabra «restaurar» sugiere, y es lo correcto: nadie que importa un respaldo
/// quiere perder lo de esta semana.
library;

import 'dart:convert';

import '../../core/app_info.dart';
import '../../core/clock.dart';
import '../../core/student_progress.dart';
import '../../engine/progress_merger.dart';
import '../progress/progress_store.dart';
import 'backup_document.dart';
import 'backup_service.dart';

class JsonBackupService implements BackupService {
  const JsonBackupService(this._store, {required Clock clock}) : _clock = clock;

  final ProgressStore _store;

  /// El reloj llega inyectado para que `exportedAt` sea comprobable: una prueba
  /// de ida y vuelta con `DateTime.now()` dentro no puede afirmar nada sobre la
  /// fecha del archivo.
  final Clock _clock;

  @override
  Future<BackupDocument?> export({
    required String uid,
    required String courseId,
  }) async {
    final StudentProgress? progress = await _store.load(
      uid: uid,
      courseId: courseId,
    );
    // Nulo y no un respaldo vacío: ofrecer un archivo de alguien que no ha
    // estudiado nada es ofrecerle una falsa red de seguridad.
    if (progress == null) return null;

    return BackupDocument(
      courseId: courseId,
      exportedAt: _clock(),
      appVersion: appVersion,
      progress: progress,
    );
  }

  @override
  String serialize(BackupDocument document) => document.toJson();

  @override
  BackupParseResult parse(
    String raw, {
    required String uid,
    required String expectedCourseId,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      return BackupMalformed('No es un archivo JSON: ${error.message}');
    }

    if (decoded is! Map) {
      return const BackupMalformed(
        'El archivo no contiene un respaldo de progreso',
      );
    }

    final Map<String, Object?> map = decoded.map(
      (Object? key, Object? value) => MapEntry<String, Object?>('$key', value),
    );

    // El orden de las comprobaciones es deliberado: primero la versión del
    // sobre, porque si no se entiende el sobre no se puede confiar en nada de
    // dentro, ni siquiera en el nombre del curso.
    final Object? version = map['backupVersion'];
    if (version is! num) {
      return const BackupMalformed('Al archivo le falta la versión de formato');
    }
    if (version.toInt() > currentBackupVersion) {
      return BackupUnsupportedVersion(
        found: version.toInt(),
        supported: currentBackupVersion,
      );
    }

    final Object? courseId = map['courseId'];
    if (courseId is! String || courseId.isEmpty) {
      return const BackupMalformed('Al archivo le falta el idioma');
    }
    if (courseId != expectedCourseId) {
      return BackupWrongCourse(found: courseId, expected: expectedCourseId);
    }

    if (map['progress'] is! Map) {
      return const BackupMalformed('El archivo no contiene progreso');
    }

    return BackupValid(BackupDocument.fromMap(map, uid: uid));
  }

  @override
  Future<StudentProgress> import(
    BackupDocument document, {
    required String uid,
  }) async {
    final StudentProgress incoming = document.progress;
    final StudentProgress? existing = await _store.load(
      uid: uid,
      courseId: document.courseId,
    );

    // Sin nada local, el respaldo entra tal cual. Con algo local, se fusiona:
    // no hay rama que reemplace, y no la hay a propósito.
    final StudentProgress merged = existing == null
        ? incoming
        : mergeProgress(existing, incoming);

    await _store.save(merged);
    return merged;
  }

  @override
  Future<void> wipe({required String uid, required String courseId}) =>
      _store.wipe(uid: uid, courseId: courseId);
}
