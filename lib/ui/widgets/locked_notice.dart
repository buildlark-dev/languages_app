/// Explica **qué falta** para desbloquear algo.
///
/// FR-023 no pide un candado: pide decir qué hay que aprobar antes. Un candado sin
/// motivo es una pared, y deja a la persona adivinando si le falta algo o si la
/// app está rota.
library;

import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../engine/progression.dart';

class LockedNotice extends StatelessWidget {
  const LockedNotice({required this.reason, super.key});

  final LockReason reason;

  /// El texto que explica el bloqueo.
  String messageFor(AppLocalizations l10n) {
    if (reason.levelHasNoContent) return l10n.levelUpcomingDetail;
    final String? module = reason.moduleTitle;
    if (module != null) return 'Primero aprueba el módulo «$module».';
    final String? level = reason.levelName;
    if (level != null) return 'Primero supera el nivel $level.';
    return l10n.levelLocked;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.lock_outline, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          // Expanded para que un título de módulo largo se parta en lugar de
          // desbordar a 360 dp.
          Expanded(
            child: Text(
              messageFor(l10n),
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
