// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'Toko';

  @override
  String get appSlogan =>
      'Conecte-se com seu público e descubra o próximo show ao vivo.';

  @override
  String get emailLabel => 'Endereço de e-mail';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get loginButton => 'Entrar';

  @override
  String get createAccountButton => 'Criar Conta';

  @override
  String get forgotPasswordLink => 'Esqueceu sua senha?';

  @override
  String get createBandTitle => 'Crie Sua Banda';

  @override
  String get bandNameLabel => 'Nome da banda';

  @override
  String get cityLabel => 'Cidade (Ex: São Paulo)';

  @override
  String get bioLabel => 'Biografia da banda';

  @override
  String get selectGenresLabel => 'Selecione os gêneros (máx. 3)';

  @override
  String get createBandButton => 'Criar Minha Banda';

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
  String get errorTitle => 'Ops!';

  @override
  String get unexpectedError => 'Ocorreu um erro inesperado. Tente novamente.';

  @override
  String get loginErrorTitle => 'Erro de Login';

  @override
  String get loginErrorUserNotFound =>
      'Usuário não encontrado. Verifique seu e-mail.';

  @override
  String get loginErrorWrongPassword => 'A senha está incorreta.';

  @override
  String get loginErrorInvalidCredential =>
      'Credenciais inválidas. Tente novamente.';

  @override
  String get registrationErrorTitle => 'Erro de Registro';

  @override
  String get registrationErrorContent =>
      'Não foi possível criar sua conta. Verifique os dados e tente novamente.';

  @override
  String genericErrorContent(Object errorDetails) {
    return 'Erro: $errorDetails';
  }

  @override
  String get ok => 'Aceitar';

  @override
  String get bandCreationErrorMissingFields =>
      'Por favor, preencha o nome, a cidade e selecione pelo menos um gênero.';
}
