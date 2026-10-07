/// Tarjeta de un nivel anunciado pero sin contenido construido.
///
/// **No tiene `onTap`.** No es que se bloquee el toque: es que no hay nada a donde
/// ir, porque los niveles anunciados no son `Level` y no existe dato que pudiera
/// representar la entrada (FR-038).
///
/// Se muestra en lugar de ocultarse para que la persona vea que el camino sigue,
/// que es información distinta de «esto es todo lo que hay».
library;

import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';

class UpcomingLevelNotice extends StatelessWidget {
  const UpcomingLevelNotice({required this.levelId, super.key});

  final String levelId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      child: Opacity(
        // Atenuado para que se lea como «todavía no» y no como «bloqueado»: son
        // dos mensajes distintos.
        opacity: 0.7,
        child: ListTile(
          leading: Icon(Icons.schedule, color: colors.onSurfaceVariant),
          title: Text('$levelId · ${l10n.levelUpcoming}'),
          subtitle: Text(l10n.levelUpcomingDetail),
          // enabled: false deja claro al lector de pantalla que no es accionable.
          enabled: false,
        ),
      ),
    );
  }
}
