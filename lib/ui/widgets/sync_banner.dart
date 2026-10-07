/// Hace visible el estado de la sincronización y del almacenamiento.
///
/// Existe porque FR-043 prohíbe fallar en silencio. Un fallo al guardar que no se
/// ve es peor que un fallo que se ve: el estudiante sigue trabajando convencido de
/// que su avance está a salvo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../providers/progress_providers.dart';

class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SyncNotice notice = ref.watch(syncNoticeProvider);
    if (notice == SyncNotice.none) return const SizedBox.shrink();

    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;

    final (
      String message,
      IconData icon,
      Color background,
      Color foreground,
    ) = switch (notice) {
      SyncNotice.storageDegraded => (
        l10n.storageDegradedTitle,
        Icons.report_problem_outlined,
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      SyncNotice.failed => (
        l10n.syncFailed,
        Icons.cloud_off_outlined,
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      SyncNotice.pending => (
        l10n.syncPending,
        Icons.cloud_sync_outlined,
        colors.surfaceContainerHighest,
        colors.onSurface,
      ),
      SyncNotice.none => ('', Icons.check, colors.surface, colors.onSurface),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 12),
            // Expanded para que un mensaje largo se parta en varias líneas en
            // lugar de desbordar a 360 dp.
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
