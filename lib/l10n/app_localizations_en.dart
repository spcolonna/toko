// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Toko';

  @override
  String get appSlogan =>
      'Connect with your audience and discover the next live gig.';

  @override
  String get emailLabel => 'Email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Log In';

  @override
  String get createAccountButton => 'Create Account';

  @override
  String get forgotPasswordLink => 'Forgot your password?';

  @override
  String get errorTitle => 'Oops!';

  @override
  String get unexpectedError =>
      'An unexpected error occurred. Please try again.';

  @override
  String get loginErrorTitle => 'Login Error';

  @override
  String get loginErrorUserNotFound =>
      'User not found. Please verify your email.';

  @override
  String get loginErrorWrongPassword => 'The password is incorrect.';

  @override
  String get loginErrorInvalidCredential =>
      'Invalid credentials. Please try again.';

  @override
  String get registrationErrorTitle => 'Registration Error';

  @override
  String get registrationErrorContent =>
      'We could not create your account. Verify your data and try again.';

  @override
  String genericErrorContent(Object errorDetails) {
    return 'Error: $errorDetails';
  }

  @override
  String get ok => 'OK';

  @override
  String get createBandTitle => 'Create Your Band';

  @override
  String get bandNameLabel => 'Band name';

  @override
  String get cityLabel => 'City (Ex: Buenos Aires)';

  @override
  String get bioLabel => 'Band biography';

  @override
  String get selectGenresLabel => 'Select genres (max. 3)';

  @override
  String get createBandButton => 'Create My Band';

  @override
  String get bandCreationErrorMissingFields =>
      'Please complete the name, city, and select at least one genre.';
}
