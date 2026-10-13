/// Pantalla de registro.
///
/// Pide **únicamente** correo y contraseña, y lo dice en pantalla. FR-006 prohíbe
/// pedir nombre, fecha de nacimiento, teléfono o ubicación en esta entrega, y
/// decirlo en voz alta es lo que convierte la promesa en algo comprobable por
/// quien se registra.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../services/auth/auth_service.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_failure_message.dart';
import '../widgets/email_password_form.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthFormState state = ref.watch(authControllerProvider);
    final AuthFailure? failure = state.failure;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUpTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              l10n.onlyEmailAndPassword,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            EmailPasswordForm(
              submitLabel: l10n.signUpTitle,
              submitting: state.submitting,
              errorMessage: failure == null
                  ? null
                  : authFailureMessage(l10n, failure),
              onChanged: () =>
                  ref.read(authControllerProvider.notifier).dismissError(),
              onSubmit: (String email, String password) => ref
                  .read(authControllerProvider.notifier)
                  .signUp(email: email, password: password),
              footer: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.signInPrompt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
