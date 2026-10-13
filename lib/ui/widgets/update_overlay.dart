/// Ofrece la versión nueva sin interrumpir lo que se está haciendo.
///
/// Va por encima de toda la app, no dentro de una pantalla, porque la versión
/// se publica en cualquier momento y el aviso tiene que llegar igual en una
/// lección, en un examen o en el mapa del curso.
///
/// **Ofrece, no recarga.** Recargar sola es lo que hace la mayoría de las PWA y
/// es un error aquí: perder el ejercicio a medias por una mejora de la app es
/// exactamente la clase de cosa que hace cerrarla y no volver. Quien decide
/// cuándo es el estudiante, y hasta que decida se puede descartar el aviso: si
/// no se pudiera, sería una interrupción con un botón, no una oferta.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/update_providers.dart';

class UpdateOverlay extends ConsumerStatefulWidget {
  const UpdateOverlay({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdateOverlay> createState() => _UpdateOverlayState();
}

class _UpdateOverlayState extends ConsumerState<UpdateOverlay>
    with WidgetsBindingObserver {
  /// Descartado para esta aparición. Vuelve a ofrecerse al reanudar.
  bool _dismissed = false;

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
    if (state != AppLifecycleState.resumed) return;
    // Volver a la app es cuando alguien la abre, y es el momento en que
    // interesa saber si hay algo nuevo. En una PWA instalada es además el
    // único momento: no hay arranque que detectarlo.
    _dismissed = false;
    ref.read(updateAvailableProvider.notifier).check();
  }

  @override
  Widget build(BuildContext context) {
    final bool available = ref.watch(updateAvailableProvider);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Stack(
      children: <Widget>[
        widget.child,
        if (available && !_dismissed)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Semantics(
                  liveRegion: true,
                  child: Material(
                    color: colors.inverseSurface,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      // Wrap y no Row: a 360 dp con la fuente al 130 % el
                      // texto y los dos botones no caben en una línea, y un
                      // aviso que desborda es un aviso que tapa el contenido.
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Hay una versión nueva de la app.',
                              style: TextStyle(color: colors.onInverseSurface),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _dismissed = true),
                            child: Text(
                              'Luego',
                              style: TextStyle(color: colors.onInverseSurface),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                ref.read(updateAvailableProvider.notifier).apply(),
                            child: Text(
                              'Actualizar',
                              style: TextStyle(color: colors.inversePrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
