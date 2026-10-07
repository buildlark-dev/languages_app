/// Entrada de un módulo en el mapa de un nivel.
///
/// Muestra el objetivo «puedo hacer X» antes de entrar (FR-011): es lo que
/// convierte una lista de módulos en una promesa concreta.
library;

import 'package:flutter/material.dart';

import '../../core/module.dart';
import '../../engine/progression.dart';
import 'locked_notice.dart';

class ModuleTile extends StatelessWidget {
  const ModuleTile({
    required this.module,
    required this.availability,
    this.lockReason,
    this.onTap,
    super.key,
  });

  final Module module;
  final ModuleAvailability availability;

  /// Por qué está bloqueado. Nulo si no lo está.
  final LockReason? lockReason;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool locked = availability == ModuleAvailability.locked;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: <Widget>[
            ListTile(
              onTap: locked ? null : onTap,
              enabled: !locked,
              leading: _Leading(availability: availability, colors: colors),
              title: Text('${module.order}. ${module.title}'),
              // El objetivo funcional, visible antes de empezar.
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(module.canDo),
              ),
            ),
            if (locked && lockReason != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: LockedNotice(reason: lockReason!),
              ),
          ],
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.availability, required this.colors});

  final ModuleAvailability availability;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => switch (availability) {
    ModuleAvailability.locked => Icon(
      Icons.lock_outline,
      color: colors.onSurfaceVariant,
    ),
    ModuleAvailability.available => Icon(
      Icons.play_circle_outline,
      color: colors.primary,
    ),
    ModuleAvailability.passed => Icon(
      Icons.check_circle,
      color: colors.primary,
    ),
  };
}
