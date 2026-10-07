import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// Nombre de la aplicación, visible en el conmutador de apps
  ///
  /// In es, this message translates to:
  /// **'Idiomas'**
  String get appTitle;

  /// Frase de presentación en la pantalla de acceso
  ///
  /// In es, this message translates to:
  /// **'Aprende desde cero hasta hablar con fluidez'**
  String get appTagline;

  /// Encabezado del catálogo de cursos
  ///
  /// In es, this message translates to:
  /// **'Elige el idioma que quieres aprender'**
  String get chooseCourse;

  /// Etiqueta de un nivel anunciado sin contenido construido
  ///
  /// In es, this message translates to:
  /// **'Próximo'**
  String get levelUpcoming;

  /// Explicación al tocar un nivel anunciado
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando el contenido de este nivel.'**
  String get levelUpcomingDetail;

  /// Etiqueta de un nivel cuyo requisito previo no se cumple
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get levelLocked;

  /// Nivel marcado como dominado por la prueba de nivelación
  ///
  /// In es, this message translates to:
  /// **'Dominado'**
  String get levelMastered;

  /// Nivel cuyo examen se aprobó
  ///
  /// In es, this message translates to:
  /// **'Superado'**
  String get levelPassed;

  /// Aviso cuando el almacenamiento local falló (FR-043)
  ///
  /// In es, this message translates to:
  /// **'Tu avance no se está guardando'**
  String get storageDegradedTitle;

  /// Detalle del aviso de almacenamiento degradado
  ///
  /// In es, this message translates to:
  /// **'Puedes seguir estudiando, pero lo de esta sesión se perderá al cerrar la app.'**
  String get storageDegradedBody;

  /// Aviso cuando no hay red en el primer arranque (FR-004)
  ///
  /// In es, this message translates to:
  /// **'Necesitas conexión solo esta vez'**
  String get offlineFirstRunTitle;

  /// Detalle del aviso de primer arranque sin conexión
  ///
  /// In es, this message translates to:
  /// **'Para crear tu cuenta hace falta conexión. Después podrás estudiar sin internet.'**
  String get offlineFirstRunBody;

  /// Botón para repetir una operación que falló
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// Botón de avance genérico
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// Cuántas palabras vencen hoy, incluido el estado al día (FR-030)
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Estás al día con el repaso} =1{1 palabra para repasar} other{{count} palabras para repasar}}'**
  String reviewDueCount(num count);

  /// Racha diaria de estudio
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin racha todavía} =1{1 día seguido} other{{count} días seguidos}}'**
  String streakDays(num count);

  /// Puntos de experiencia acumulados
  ///
  /// In es, this message translates to:
  /// **'{count} XP'**
  String xpTotal(num count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
