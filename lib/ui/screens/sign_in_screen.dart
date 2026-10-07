/// Pantalla de inicio de sesión.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../services/auth/auth_service.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_failure_message.dart';
import '../widgets/email_password_form.dart';
import 'password_reset_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AuthFormState state = ref.watch(authControllerProvider);
    final AuthFailure? failure = state.failure;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(l10n.appTagline, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            EmailPasswordForm(
              submitLabel: l10n.signInTitle,
              submitting: state.submitting,
              errorMessage: failure == null
                  ? null
                  : authFailureMessage(l10n, failure),
              onChanged: () => ref.read(authControllerProvider.notifier).dismissError(),
              onSubmit: (String email, String password) => ref
                  .read(authControllerProvider.notifier)
                  .signIn(email: email, password: password),
              footer: Column(
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SignUpScreen(),
                      ),
                    ),
                    child: Text(l10n.signUpPrompt),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PasswordResetScreen(),
                      ),
                    ),
                    child: Text(l10n.forgotPassword),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
