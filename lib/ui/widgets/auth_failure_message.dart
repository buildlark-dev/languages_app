/// Traduce un [AuthFailure] al mensaje que ve la persona.
///
/// Está en un archivo propio para que las tres pantallas de cuenta usen el mismo
/// texto para el mismo fallo. FR-004 exige un mensaje distinto por caso, y
/// repetir el `switch` en cada pantalla acabaría dando tres redacciones distintas
/// del mismo problema.
library;

import '../../app/l10n/app_localizations.dart';
import '../../services/auth/auth_service.dart';

String authFailureMessage(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure) {
      AuthFailure.invalidEmail => l10n.authErrorInvalidEmail,
      AuthFailure.weakPassword => l10n.authErrorWeakPassword,
      AuthFailure.emailAlreadyInUse => l10n.authErrorEmailInUse,
      AuthFailure.wrongCredentials => l10n.authErrorWrongCredentials,
      AuthFailure.userNotFound => l10n.authErrorUserNotFound,
      AuthFailure.tooManyAttempts => l10n.authErrorTooManyAttempts,
      AuthFailure.noConnection => l10n.authErrorNoConnection,
      AuthFailure.unknown => l10n.authErrorUnknown,
    };
