/// Cierre de sesión con advertencia previa.
///
/// FR-005: antes de cerrar sesión hay que advertir **qué quedaría sin respaldar**
/// y pedir confirmación explícita. El mensaje cambia según haya o no cambios
/// pendientes, porque una advertencia idéntica en los dos casos se vuelve ruido
/// que la gente aprende a ignorar.
///
/// El servicio de autenticación no borra la base local, así que cerrar sesión por
/// error no destruye nada: lo que se pierde es solo lo que no llegó a la nube.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../providers/progress_providers.dart';

class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: l10n.signOut,
      onPressed: () => _confirm(context, ref),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SyncNotice notice = ref.read(syncNoticeProvider);
    final bool hasUnsaved =
        notice == SyncNotice.pending ||
        notice == SyncNotice.failed ||
        notice == SyncNotice.storageDegraded;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.signOutWarningTitle),
        content: Text(
          hasUnsaved ? l10n.signOutWarningPending : l10n.signOutWarningSynced,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }
}
