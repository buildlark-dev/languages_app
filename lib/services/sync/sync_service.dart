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

  /// Borra el documento remoto del estudiante en este curso (FR-046).
  ///
  /// Es la **única** operación destructiva del contrato, y rompe a propósito la
  /// regla que encabeza este archivo. La diferencia con un `set` está en quién
  /// decide: un reemplazo silencioso pierde progreso por descuido del programa,
  /// mientras que esto solo ocurre cuando la persona pulsa «borrar» y después
  /// confirma un diálogo que le dice que no tiene vuelta atrás.
  ///
  /// Sin ella, borrar no borra: el documento sobrevive en la nube y la primera
  /// sincronización lo trae de vuelta, con la app habiendo dicho ya que el
  /// progreso se eliminó.
  ///
  /// Lanza si no se pudo borrar, y eso importa: quien llama **no debe** borrar
  /// lo local si esto falló, porque entonces la nube restauraría todo y el
  /// borrado volvería a ser mentira.
  Future<void> deleteRemote({required String uid, required String courseId});

  /// Estado actual, sin esperar al flujo.
  SyncState get currentStatus;
}
