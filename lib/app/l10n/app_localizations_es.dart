// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Idiomas';

  @override
  String get appTagline => 'Aprende desde cero hasta hablar con fluidez';

  @override
  String get chooseCourse => 'Elige el idioma que quieres aprender';

  @override
  String get levelUpcoming => 'Próximo';

  @override
  String get levelUpcomingDetail =>
      'Estamos preparando el contenido de este nivel.';

  @override
  String get levelLocked => 'Bloqueado';

  @override
  String get levelMastered => 'Dominado';

  @override
  String get levelPassed => 'Superado';

  @override
  String get storageDegradedTitle => 'Tu avance no se está guardando';

  @override
  String get storageDegradedBody =>
      'Puedes seguir estudiando, pero lo de esta sesión se perderá al cerrar la app.';

  @override
  String get offlineFirstRunTitle => 'Necesitas conexión solo esta vez';

  @override
  String get offlineFirstRunBody =>
      'Para crear tu cuenta hace falta conexión. Después podrás estudiar sin internet.';

  @override
  String get retry => 'Reintentar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String reviewDueCount(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString palabras para repasar',
      one: '1 palabra para repasar',
      zero: 'Estás al día con el repaso',
    );
    return '$_temp0';
  }

  @override
  String streakDays(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString días seguidos',
      one: '1 día seguido',
      zero: 'Sin racha todavía',
    );
    return '$_temp0';
  }

  @override
  String xpTotal(num count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString XP';
  }

  @override
  String get signInTitle => 'Entrar';

  @override
  String get signUpTitle => 'Crear cuenta';

  @override
  String get passwordResetTitle => 'Recuperar el acceso';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get signUpPrompt => '¿No tienes cuenta? Créala';

  @override
  String get signInPrompt => '¿Ya tienes cuenta? Entra';

  @override
  String get forgotPassword => 'Olvidé mi contraseña';

  @override
  String get sendResetEmail => 'Enviar instrucciones';

  @override
  String get resetEmailSent =>
      'Te enviamos las instrucciones por correo. Revisa también la carpeta de spam.';

  @override
  String get onlyEmailAndPassword =>
      'Solo pedimos correo y contraseña. Nada más.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutWarningTitle => '¿Cerrar sesión?';

  @override
  String get signOutWarningSynced =>
      'Tu progreso está respaldado en la nube. Podrás recuperarlo al volver a entrar.';

  @override
  String get signOutWarningPending =>
      'Tienes avance que todavía no llegó a la nube. Si cierras sesión ahora, lo perderás.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get syncPending => 'Guardando tu avance…';

  @override
  String get syncFailed =>
      'No pudimos guardar tu avance en la nube. Lo reintentaremos.';

  @override
  String get authErrorInvalidEmail => 'Ese correo no parece válido.';

  @override
  String get authErrorWeakPassword =>
      'La contraseña es demasiado corta. Usa al menos seis caracteres.';

  @override
  String get authErrorEmailInUse =>
      'Ya existe una cuenta con ese correo. Prueba a entrar.';

  @override
  String get authErrorWrongCredentials =>
      'El correo o la contraseña no coinciden.';

  @override
  String get authErrorUserNotFound =>
      'No encontramos ninguna cuenta con ese correo.';

  @override
  String get authErrorTooManyAttempts =>
      'Demasiados intentos. Espera unos minutos y vuelve a probar.';

  @override
  String get authErrorNoConnection =>
      'Sin conexión. Para crear tu cuenta o entrar la primera vez hace falta internet; después podrás estudiar sin él.';

  @override
  String get authErrorUnknown => 'Algo falló. Vuelve a intentarlo.';
}
