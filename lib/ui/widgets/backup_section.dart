/// Las tres acciones de respaldo: exportar, importar y borrar (FR-045, FR-046).
///
/// La destructiva está visualmente separada del resto —bajo su propia línea, con
/// el color de error— porque ninguna de las otras dos tiene vuelta atrás que
/// haga falta explicar, y mezclarlas en la misma lista las haría parecer igual
/// de inofensivas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/backup/backup_service.dart';
import '../providers/backup_providers.dart';
import 'destructive_confirm_dialog.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BackupState backup = ref.watch(backupControllerProvider);
    final BackupController controller = ref.read(
      backupControllerProvider.notifier,
    );
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Respaldo', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Tu avance ya se guarda en la nube. Un respaldo sirve para tenerlo '
          'también fuera de la app.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (backup.lastAction != null || backup.parseFailure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Notice(state: backup, onDismiss: controller.dismiss),
          ),
        OutlinedButton.icon(
          onPressed: backup.busy ? null : controller.exportToClipboard,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copiar mi respaldo'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: backup.busy ? null : () => _askForBackupText(context, ref),
          icon: const Icon(Icons.paste_outlined),
          label: const Text('Importar un respaldo'),
        ),
        const Divider(height: 32),
        Text(
          'Borrar mi progreso',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: colors.error),
        ),
        const SizedBox(height: 4),
        Text(
          'Borra lo guardado en este dispositivo y vuelve a empezar desde A1.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: backup.busy ? null : () => _confirmWipe(context, ref),
          style: OutlinedButton.styleFrom(foregroundColor: colors.error),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Borrar mi progreso'),
        ),
      ],
    );
  }

  /// Pide el texto del respaldo y lo importa.
  Future<void> _askForBackupText(BuildContext context, WidgetRef ref) async {
    final String? raw = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _ImportDialog(),
    );
    if (raw == null || raw.trim().isEmpty) return;
    await ref.read(backupControllerProvider.notifier).importFromText(raw);
  }

  Future<void> _confirmWipe(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await DestructiveConfirmDialog.show(
      context,
      title: '¿Borrar tu progreso?',
      consequence:
          'Se borrará todo lo guardado de este idioma en este dispositivo: '
          'lecciones aprobadas, racha, XP y la cola de repaso.',
      confirmLabel: 'Borrar',
    );
    if (!confirmed) return;
    await ref.read(backupControllerProvider.notifier).wipe();
  }
}

/// Dónde se pega el respaldo.
class _ImportDialog extends StatefulWidget {
  const _ImportDialog();

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Importar un respaldo'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Pega aquí el contenido del respaldo. Se combinará con tu avance '
          'actual, así que no perderás lo que hayas hecho después.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '{ "backupVersion": 1, … }',
          ),
        ),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text),
        child: const Text('Importar'),
      ),
    ],
  );
}

/// El resultado de la última acción, con su motivo si falló.
///
/// Los cuatro rechazos se resuelven con un `switch` exhaustivo sobre la
/// jerarquía `sealed`, así que un caso nuevo no compila hasta que se le escribe
/// un mensaje. Un `String` genérico dejaría que los cuatro dijeran «error».
class _Notice extends StatelessWidget {
  const _Notice({required this.state, required this.onDismiss});

  final BackupState state;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final BackupParseResult? failure = state.parseFailure;
    final bool isError = failure != null;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? colors.errorContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              failure != null ? _failureMessage(failure) : _actionMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar el aviso',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  String _actionMessage() => switch (state.lastAction) {
    BackupAction.exported =>
      'Respaldo copiado. Pégalo en una nota o un archivo para guardarlo.',
    BackupAction.imported =>
      'Respaldo importado y combinado con tu avance actual.',
    BackupAction.wiped => 'Tu progreso de este idioma se borró.',
    BackupAction.nothingToExport =>
      'Todavía no hay nada que respaldar. Termina una lección primero.',
    null => '',
  };

  String _failureMessage(BackupParseResult failure) => switch (failure) {
    BackupValid() => '',
    BackupUnsupportedVersion(:final int found, :final int supported) =>
      'Ese respaldo lo escribió una versión más nueva de la app (formato '
          '$found; esta entiende hasta $supported). Actualiza la app e '
          'inténtalo de nuevo. No se ha cambiado nada.',
    BackupMalformed(:final String reason) =>
      'Ese texto no es un respaldo válido: $reason. No se ha cambiado nada.',
    BackupWrongCourse(:final String found, :final String expected) =>
      'Ese respaldo es del idioma «$found» y estás en «$expected». Cambia de '
          'idioma antes de importarlo. No se ha cambiado nada.',
  };
}
