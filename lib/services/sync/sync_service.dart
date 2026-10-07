/// Contrato de sincronización.
///
/// Obligación central: **no existe ninguna operación que reemplace el progreso
/// remoto.** Solo [SyncService.pushMerged], que lee, fusiona y escribe dentro de
/// una transacción. Que el contrato no ofrezca un `set` directo es deliberado:
/// así no se puede perder progreso ni por descuido (FR-042).
library;

import '../../core/student_progress.dart';
import '../../core/sync_state.dart';

abstract interface class SyncService {
  /// Lee el progreso remoto, o nulo si el estudiante no tiene documento.
  Future<StudentProgress?> pull({
    required String uid,
    required String courseId,
  });

  /// Transacción: lee el remoto, lo fusiona con [local] y escribe el resultado.
  ///
  /// Devuelve lo escrito, que quien llama debe guardar en la base local para que
  /// ambos lados queden iguales.
  Future<StudentProgress> pushMerged(StudentProgress local);

  /// Escucha en vivo el documento remoto mientras la app está en primer plano.
  ///
  /// Es lo que hace cumplible SC-004: un segundo dispositivo abierto y ocioso
  /// recibe el avance en segundos **sin recargar ni reiniciar**. Sin esto, todos
  /// los disparadores de escritura son acciones locales y un dispositivo
  /// inactivo nunca se enteraría de nada.
  ///
  /// Como la fusión es idempotente, volver a recibir algo ya fusionado no tiene
  /// efecto, así que no hace falta llevar registro de qué emisión se procesó.
  Stream<StudentProgress> remoteChanges({
    required String uid,
    required String courseId,
  });

  /// Estado de la sincronización, para que la interfaz pueda mostrarlo.
  ///
  /// FR-043 prohíbe fallar en silencio: todo fallo llega aquí con su motivo.
  Stream<SyncState> get syncStatus;

  /// Estado actual, sin esperar al flujo.
  SyncState get currentStatus;
}
