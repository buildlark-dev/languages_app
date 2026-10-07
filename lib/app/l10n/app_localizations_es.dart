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
}
