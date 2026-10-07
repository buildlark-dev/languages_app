/// Explica el primer arranque sin conexión y ofrece reintentar.
///
/// Es el caso borde que la cuenta obligatoria introduce: sin red no se puede
/// registrar ni entrar la primera vez. FR-004 exige explicarlo con claridad y
/// dejarlo reintentable, nunca quedarse en espera indefinida ni en una pantalla
/// muerta.
library;

import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';

class OfflineNotice extends StatelessWidget {
  const OfflineNotice({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.wifi_off_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.offlineFirstRunTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // El detalle dice que después se puede estudiar sin internet. Es
            // información que evita que alguien abandone creyendo que la app
            // exige conexión siempre.
            Text(l10n.offlineFirstRunBody),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
