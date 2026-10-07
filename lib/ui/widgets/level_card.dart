/// Tarjeta de un nivel con contenido.
library;

import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/level.dart';
import '../../core/level_state.dart';

class LevelCard extends StatelessWidget {
  const LevelCard({
    required this.level,
    required this.state,
    required this.completion,
    required this.passedModules,
    this.onTap,
    super.key,
  });

  final Level level;
  final LevelState state;

  /// Proporción del nivel aprobada, de 0.0 a 1.0.
  final double completion;

  final int passedModules;

  /// Nulo cuando el nivel está bloqueado.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    final (String label, Color color) = switch (state) {
      LevelState.locked => (l10n.levelLocked, colors.onSurfaceVariant),
      LevelState.unlocked => ('', colors.primary),
      LevelState.mastered => (l10n.levelMastered, colors.tertiary),
      LevelState.passed => (l10n.levelPassed, colors.primary),
    };

    return Card(
      child: ListTile(
        // Se informa del estado al lector de pantalla junto al nombre, en lugar
        // de dejarlo en un icono que no se anuncia.
        onTap: onTap,
        enabled: onTap != null,
        leading: _StateIcon(state: state, colors: colors),
        title: Text(level.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 4),
            Text(level.description),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Semantics(
                    label:
                        '$passedModules de ${level.modules.length} módulos '
                        'aprobados',
                    excludeSemantics: true,
                    child: LinearProgressIndicator(
                      value: completion,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$passedModules/${level.modules.length}'),
              ],
            ),
            if (label.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.state, required this.colors});

  final LevelState state;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => switch (state) {
    LevelState.locked => Icon(Icons.lock_outline, color: colors.onSurfaceVariant),
    LevelState.unlocked => Icon(Icons.play_circle_outline, color: colors.primary),
    LevelState.mastered => Icon(Icons.verified_outlined, color: colors.tertiary),
    LevelState.passed => Icon(Icons.check_circle, color: colors.primary),
  };
}
