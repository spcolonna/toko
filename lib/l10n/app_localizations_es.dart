// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Toko';

  @override
  String get appSlogan =>
      'Conecta con tu audiencia y descubre el próximo toque en vivo.';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get loginButton => 'Iniciar Sesión';

  @override
  String get createAccountButton => 'Crear Cuenta';

  @override
  String get forgotPasswordLink => '¿Olvidaste tu contraseña?';

  @override
  String get createBandTitle => 'Crea tu Banda';

  @override
  String get bandNameLabel => 'Nombre de la banda';

  @override
  String get cityLabel => 'Ciudad (Ej: Buenos Aires)';

  @override
  String get bioLabel => 'Biografía de la banda';

  @override
  String get selectGenresLabel => 'Selecciona los géneros (máx. 3)';

  @override
  String get createBandButton => 'Crear mi Banda';

  @override
  String get contactEmailLabel => 'Email de Contacto';

  @override
  String get socialLinksLabel =>
      'Links Sociales (URL de Spotify, YouTube, etc.)';

  @override
  String get dateFoundedLabel => 'Fecha de Fundación (Nacimiento de la Banda)';

  @override
  String get dateFoundedPlaceholder => 'Seleccionar fecha';

  @override
  String get yourRoleLabel => 'Tu Rol en la Banda (Rol principal)';

  @override
  String get errorTitle => '¡Ups!';

  @override
  String get unexpectedError =>
      'Ocurrió un error inesperado. Intenta de nuevo.';

  @override
  String get loginErrorTitle => 'Error de inicio de sesión';

  @override
  String get loginErrorUserNotFound =>
      'Usuario no encontrado. Verifica tu correo.';

  @override
  String get loginErrorWrongPassword => 'La contraseña es incorrecta.';

  @override
  String get loginErrorInvalidCredential =>
      'Credenciales inválidas. Intenta de nuevo.';

  @override
  String get registrationErrorTitle => 'Error de registro';

  @override
  String get registrationErrorContent =>
      'No pudimos crear tu cuenta. Verifica los datos e intenta de nuevo.';

  @override
  String genericErrorContent(Object errorDetails) {
    return 'Error: $errorDetails';
  }

  @override
  String get ok => 'Aceptar';

  @override
  String get bandCreationErrorMissingFields =>
      'Por favor, completa el nombre, la ciudad, la fecha de fundación y tu rol.';
}
