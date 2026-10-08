/// Sincroniza al cambiar el estado de la app.
///
/// Envuelve el árbol y observa el ciclo de vida. Dos momentos:
///
/// * **Al pasar a segundo plano**, se empuja lo pendiente. Es el último
///   instante garantizado antes de que el sistema pueda matar el proceso.
/// * **Al volver a primer plano**, se reintenta. Es lo más cerca de «se
///   recuperó la conexión» que se detecta sin añadir una dependencia: volver a
///   la app es el momento en que la red suele estar de vuelta.
///
/// Pedir una sincronización de más no cuesta nada: el planificador coalesce y
/// la fusión es idempotente. Lo que sí costaba era no pedirla: un empujón que
/// fallaba sin red esperaba a la siguiente actividad, que podía no llegar hasta
/// el día siguiente.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/providers/progress_controller.dart';

class SyncLifecycle extends ConsumerStatefulWidget {
  const SyncLifecycle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SyncLifecycle> createState() => _SyncLifecycleState();
}

class _SyncLifecycleState extends ConsumerState<SyncLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sin sesión o sin curso no hay nada que sincronizar, y el controlador lo
    // resuelve solo devolviendo pronto: no hace falta comprobarlo aquí.
    final StudentProgressController progress = ref.read(
      studentProgressProvider.notifier,
    );

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        progress.syncOnPause();
      case AppLifecycleState.resumed:
        progress.syncOnResume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Transitorios: una llamada entrante o el conmutador de apps. Pedir
        // una sincronización en cada uno sería ruido sin información nueva.
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
