/// La racha diaria, con su estado de hoy.
///
/// Recibe el [StreakPoint] y la fecha, no un número ya cocinado. Es deliberado:
/// el contador solo se actualiza al estudiar, así que un widget que recibiera
/// `streakCount` a secas diría «5 días seguidos» a quien no estudia desde el mes
/// pasado. La decisión de si la racha sigue viva es del motor, y aquí se
/// consulta, no se reimplementa.
library;

import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../engine/streak_tracker.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({required this.streak, required this.today, super.key});

  final StreakPoint streak;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int shown = streak.displayCountOn(today);
    final bool alive = shown > 0;
    final bool doneToday = streak.includesToday(today);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return _Badge(
      // Apagado cuando no hay racha: una llama encendida sobre «sin racha
      // todavía» es una contradicción que hay que leer dos veces.
      icon: alive
          ? Icons.local_fire_department
          : Icons.local_fire_department_outlined,
      iconColor: alive ? colors.primary : colors.onSurfaceVariant,
      label: l10n.streakDays(shown),
      // Distinguir «llevas 3 días» de «llevas 3 días y hoy ya está hecho» es la
      // diferencia entre un recordatorio y una felicitación.
      detail: alive && !doneToday ? 'Estudia hoy para no perderla' : null,
    );
  }
}

/// Insignia con icono, cifra y un detalle opcional.
///
/// Está aquí y no en un archivo propio porque es la forma de **esta** insignia;
/// la de XP tiene la suya, y compartir un widget de dos campos entre ambas solo
/// añadiría un parámetro de configuración por cada diferencia futura.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.detail,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) => Semantics(
    // El lector de pantalla recibe una sola frase en lugar de icono, número y
    // nota por separado.
    label: detail == null ? label : '$label. $detail',
    excludeSemantics: true,
    child: Row(
      children: <Widget>[
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              if (detail != null)
                Text(detail!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}
