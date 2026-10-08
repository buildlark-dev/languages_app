/// Los puntos de experiencia acumulados.
///
/// Opcionalmente muestra lo que acaba de ganarse. Esa cifra viene de
/// `RecordedActivity.xpGained`, que es la que el motor concedió de verdad: en un
/// reintento sin mejora son cero, y mostrar «+20» cuando el total no se movió
/// sería un número que no cuadra con el de al lado.
library;

import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';

class XpBadge extends StatelessWidget {
  const XpBadge({required this.xp, this.justGained, super.key});

  final int xp;

  /// XP que la última actividad añadió, si se está mostrando un resultado.
  final int? justGained;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int? gained = justGained;
    final bool showGain = gained != null && gained > 0;

    return Semantics(
      label: showGain
          ? '${l10n.xpTotal(xp)}, $gained nuevos'
          : l10n.xpTotal(xp),
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          Icon(Icons.bolt, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            l10n.xpTotal(xp),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (showGain) ...<Widget>[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$gained',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
