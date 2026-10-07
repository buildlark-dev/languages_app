/// Pantalla de restablecimiento de contraseña.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../services/auth/auth_service.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_failure_message.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthFormState state = ref.watch(authControllerProvider);
    final AuthFailure? failure = state.failure;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.passwordResetTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              controller: _email,
              decoration: InputDecoration(labelText: l10n.emailLabel),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enabled: !state.submitting,
              onChanged: (_) =>
                  ref.read(authControllerProvider.notifier).dismissError(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.submitting
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .sendPasswordReset(_email.text.trim()),
              child: Text(l10n.sendResetEmail),
            ),
            if (failure != null) ...<Widget>[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  authFailureMessage(l10n, failure),
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
            if (state.done) ...<Widget>[
              const SizedBox(height: 16),
              // La confirmación menciona la carpeta de spam a propósito: es
              // donde acaba la mayoría de estos correos, y no decirlo genera
              // gente convencida de que la app no funciona.
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.resetEmailSent,
                  style: TextStyle(color: colors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
