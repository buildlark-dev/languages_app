/// Decide **cuándo** se sincroniza.
///
/// Está separado de [SyncService] a propósito: el servicio sabe *cómo* fusionar y
/// escribir, y este sabe en qué momentos vale la pena hacerlo. Mezclarlos
/// obligaría a probar la política de disparo contra Firestore.
///
/// Dos obligaciones:
///
/// * **Nunca bloquear la interfaz.** Un empujón que falla se registra y se
///   reintenta; no detiene la lección ni muestra un diálogo.
/// * **Coalescer.** Terminar tres ejercicios seguidos no debe producir tres
///   transacciones. Si ya hay un empujón en vuelo, se marca que hace falta otro y
///   se hace uno solo al terminar.
library;

import 'dart:async';

import '../../core/student_progress.dart';
import '../../engine/progress_merger.dart';

/// Por qué se sincroniza. Sirve para diagnóstico y para las pruebas.
enum SyncTrigger {
  signIn,
  activityFinished,
  reviewFinished,
  connectivityRestored,
  appBackgrounded,
}

class SyncScheduler {
  SyncScheduler({
    required Future<StudentProgress> Function(StudentProgress) push,
    required StudentProgress? Function() readLocal,
    required Future<void> Function(StudentProgress) writeLocal,
  }) : _push = push,
       _readLocal = readLocal,
       _writeLocal = writeLocal;

  final Future<StudentProgress> Function(StudentProgress) _push;
  final StudentProgress? Function() _readLocal;
  final Future<void> Function(StudentProgress) _writeLocal;

  bool _inFlight = false;
  bool _pending = false;

  /// Los disparadores atendidos, en orden. Para inspeccionarlo en las pruebas.
  final List<SyncTrigger> handled = <SyncTrigger>[];

  /// Solicita una sincronización.
  ///
  /// No lanza nunca: un fallo de red no es un error del que la interfaz tenga
  /// que ocuparse en ese momento. El motivo queda en `SyncService.syncStatus`,
  /// que es lo que el aviso de la pantalla observa.
  Future<void> request(SyncTrigger trigger) async {
    handled.add(trigger);

    if (_inFlight) {
      // Ya hay uno en vuelo: basta con recordar que al terminar hace falta otro.
      _pending = true;
      return;
    }

    _inFlight = true;
    try {
      do {
        _pending = false;
        final StudentProgress? local = _readLocal();
        if (local == null) break;
        try {
          final StudentProgress merged = await _push(local);
          // El resultado se escribe en la base local para que ambos lados queden
          // iguales tras cada sincronización.
          await _writeLocal(merged);
        } catch (_) {
          // Queda pendiente. El reintento llega con el siguiente disparador,
          // normalmente connectivityRestored.
          break;
        }
      } while (_pending);
    } finally {
      _inFlight = false;
    }
  }

  /// Aplica un cambio recibido de la nube fusionándolo con lo local.
  ///
  /// **Corregido**: la primera versión pasaba el remoto a `pushMerged` «como si
  /// fuera local», confiando en que esa ruta hiciera la fusión. No la hace:
  /// `pushMerged` fusiona su argumento con **la nube**, no con lo local, así
  /// que recibir una emisión por detrás del progreso de este dispositivo
  /// escribía esa emisión encima y se perdía el avance local. La fusión es
  /// idempotente, sí, pero nunca llegaba a incluir lo local.
  ///
  /// Ahora se fusiona aquí, explícitamente, y lo primero que se hace es
  /// guardarlo en local: si la red se cae a mitad, lo recibido ya está a salvo
  /// junto con lo que había.
  Future<void> applyRemote(StudentProgress remote) async {
    final StudentProgress? local = _readLocal();
    final StudentProgress merged = local == null
        ? remote
        : mergeProgress(local, remote);

    await _writeLocal(merged);

    // Devolver la fusión a la nube solo cuando lo local aportaba algo. Sin esa
    // condición, cada emisión provocaría una escritura, que provocaría otra
    // emisión: un ida y vuelta que converge pero no para.
    if (local == null || !_addsSomething(merged, remote)) return;

    try {
      await _writeLocal(await _push(merged));
    } catch (_) {
      // Queda pendiente. Lo recibido ya está guardado arriba, así que no se
      // pierde nada por no poder confirmar ahora.
    }
  }

  /// Si [merged] tiene algo que [remote] no tenía.
  ///
  /// Compara los escalares monotónicos en lugar de los objetos enteros porque
  /// `StudentProgress` no define igualdad, y porque aquí basta con una señal:
  /// equivocarse de más solo cuesta un empujón idempotente.
  bool _addsSomething(StudentProgress merged, StudentProgress remote) =>
      merged.xp != remote.xp ||
      merged.streakCount != remote.streakCount ||
      merged.lastActivityDate != remote.lastActivityDate ||
      merged.currentLevelId != remote.currentLevelId ||
      merged.levelStates.length != remote.levelStates.length ||
      merged.activityScores.length != remote.activityScores.length ||
      merged.reviewCards.length != remote.reviewCards.length;
}
