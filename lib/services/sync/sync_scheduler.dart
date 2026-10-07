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
  /// Usa la misma ruta que un empujón, no una lógica paralela: por eso recibe el
  /// remoto como si fuera local y deja que `pushMerged` haga la fusión. Como la
  /// fusión es idempotente, recibir algo ya fusionado no tiene efecto.
  Future<void> applyRemote(StudentProgress remote) async {
    final StudentProgress? local = _readLocal();
    if (local == null) {
      await _writeLocal(remote);
      return;
    }
    try {
      await _writeLocal(await _push(remote));
    } catch (_) {
      // Si no se puede confirmar contra la nube, al menos no se pierde lo
      // recibido: se guarda la fusión local.
      await _writeLocal(remote);
    }
  }
}
