import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Toko'**
  String get appName;

  /// No description provided for @appSlogan.
  ///
  /// In es, this message translates to:
  /// **'Conecta con tu audiencia y descubre el próximo toque en vivo.'**
  String get appSlogan;

  /// No description provided for @emailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginButton;

  /// No description provided for @createAccountButton.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get createAccountButton;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPasswordLink;

  /// No description provided for @errorTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Ups!'**
  String get errorTitle;

  /// No description provided for @unexpectedError.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado. Intenta de nuevo.'**
  String get unexpectedError;

  /// No description provided for @loginErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Error de inicio de sesión'**
  String get loginErrorTitle;

  /// No description provided for @loginErrorUserNotFound.
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado. Verifica tu correo.'**
  String get loginErrorUserNotFound;

  /// No description provided for @loginErrorWrongPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es incorrecta.'**
  String get loginErrorWrongPassword;

  /// No description provided for @loginErrorInvalidCredential.
  ///
  /// In es, this message translates to:
  /// **'Credenciales inválidas. Intenta de nuevo.'**
  String get loginErrorInvalidCredential;

  /// No description provided for @registrationErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Error de registro'**
  String get registrationErrorTitle;

  /// No description provided for @registrationErrorContent.
  ///
  /// In es, this message translates to:
  /// **'No pudimos crear tu cuenta. Verifica los datos e intenta de nuevo.'**
  String get registrationErrorContent;

  /// No description provided for @genericErrorContent.
  ///
  /// In es, this message translates to:
  /// **'Error: {errorDetails}'**
  String genericErrorContent(Object errorDetails);

  /// No description provided for @ok.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get ok;

  /// No description provided for @createBandTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu Banda'**
  String get createBandTitle;

  /// No description provided for @bandNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la banda'**
  String get bandNameLabel;

  /// No description provided for @cityLabel.
  ///
  /// In es, this message translates to:
  /// **'Ciudad (Ej: Buenos Aires)'**
  String get cityLabel;

  /// No description provided for @bioLabel.
  ///
  /// In es, this message translates to:
  /// **'Biografía de la banda'**
  String get bioLabel;

  /// No description provided for @selectGenresLabel.
  ///
  /// In es, this message translates to:
  /// **'Selecciona los géneros (máx. 3)'**
  String get selectGenresLabel;

  /// No description provided for @createBandButton.
  ///
  /// In es, this message translates to:
  /// **'Crear mi Banda'**
  String get createBandButton;

  /// No description provided for @bandCreationErrorMissingFields.
  ///
  /// In es, this message translates to:
  /// **'Por favor, completa el nombre, la ciudad y selecciona al menos un género.'**
  String get bandCreationErrorMissingFields;
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
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
