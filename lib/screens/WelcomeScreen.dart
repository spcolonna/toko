import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toko/screens/Toko/Entities/aggressive_rock_clipper.dart';
import 'package:toko/services/auth_service.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/CustomPasswordField.dart';
import 'package:toko/widgets/SecondaryButton.dart';

import '../l10n/app_localizations.dart';
import 'Toko/MainNavigationScreen.dart';
import 'forgot_password_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  bool _isLogin = true;

  // Métodos de navegación y autenticación (se mantienen intactos)
  Future<void> _navigateAfterAuth(User user) async {
    final userProfileRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userProfileDoc = await userProfileRef.get();

    if (!mounted) return;

    // Si el perfil NO existe, lo creamos.
    if (!userProfileDoc.exists) {
      final newUserProfile = {
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'hasBand': false, // Campo clave para el futuro Tab Bar dinámico
        'followingBands': [], // Array para bandas seguidas
        'rsvpEvents': [], // Array para eventos a los que va
      };
      await userProfileRef.set(newUserProfile);
    }

    // REDIRECCIÓN FINAL: Navegar a la pantalla principal
    // Usamos pushReplacement para que el usuario no pueda volver al login con el botón 'atrás'
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen())
    );
  }

  Future<void> _performLogin() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await _navigateAfterAuth(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found': errorMessage = l10n.loginErrorUserNotFound; break;
        case 'wrong-password': errorMessage = l10n.loginErrorWrongPassword; break;
        case 'invalid-credential': errorMessage = l10n.loginErrorInvalidCredential; break;
        default: errorMessage = l10n.unexpectedError;
      }
      _showErrorDialog(l10n.loginErrorTitle, errorMessage);
    } catch (e) {
      _showErrorDialog(l10n.errorTitle, l10n.genericErrorContent(e.toString()));
    } finally {
      if (mounted && _isLoading) { setState(() { _isLoading = false; }); }
    }
  }

  Future<void> _performRegistration() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) return;
    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final userModel = await _authService.signUpWithEmailPassword(email, password);
      if (userModel != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _navigateAfterAuth(user);
        }
      } else {
        _showErrorDialog(l10n.registrationErrorTitle, l10n.registrationErrorContent);
      }
    } catch (e) {
      _showErrorDialog(l10n.errorTitle, l10n.genericErrorContent(e.toString()));
    } finally {
      if (mounted && _isLoading) { setState(() { _isLoading = false; }); }
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(child: Text(l10n.ok), onPressed: () { Navigator.of(ctx).pop(); })
      ],
    ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
// --- WIDGETS AUXILIARES PARA EL BUILD ---

  // WIDGET PRINCIPAL DEL FORMULARIO (para usar con AnimatedSwitcher)
  Widget _buildAuthFormBody(AppLocalizations l10n, bool isLogin) {
    // Usamos el 'key' aquí para que AnimatedSwitcher sepa cuándo el contenido
    // de esta sección ha cambiado (Login vs Registro).
    return Column(
      key: ValueKey<bool>(isLogin),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Enlace de Olvidé Contraseña (solo aparece en modo Login)
        if (isLogin)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Navegación a la pantalla de Olvidé Contraseña
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
              },
              child: Text(
                l10n.forgotPasswordLink,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),

        const SizedBox(height: 16.0), // Espaciador para separar del botón

        // El botón de acción principal (Login/Registro)
        if (_isLoading)
          const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)
              )
          )
        else
          SecondaryButton(
            text: isLogin ? l10n.loginButton : l10n.createAccountButton,
            onPressed: isLogin ? _performLogin : _performRegistration,
          ),
      ],
    );
  }

  // --- WIDGET PRIVADO: EL CONMUTADOR (TOGGLE) CON ANIMACIÓN (se mantiene igual) ---
  Widget _buildAuthToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: AppColors.textSecondary, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleItem(l10n.loginButton, true),
          _buildToggleItem(l10n.createAccountButton, false),
        ],
      ),
    );
  }

  // --- ITEM INDIVIDUAL DEL TOGGLE (se mantiene igual) ---
  Widget _buildToggleItem(String text, bool targetLoginState) {
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() { _isLogin = targetLoginState; }); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: _isLogin == targetLoginState ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: _isLogin == targetLoginState ? AppColors.textWhite : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- CONSTRUCCIÓN DE LA UI (NUEVO ORDEN) ---
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Para que el formulario se estire
            children: [
              Center(
                child: ClipPath( // 📌 CAMBIAMOS ClipOval por ClipPath
                  clipper: AggressiveRockClipper(), // 📌 Usamos nuestro clipper personalizado
                  child: Image.asset(
                    'assets/logo/Logo.jpeg',
                    height: 200, // Ajusta la altura para que la púa se vea bien
                    width: 230, // Ajusta el ancho también
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Center(
                child: Text(
                  l10n.appSlogan,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 48.0),

              // 2. CONMUTADOR (TOGGLE)
              _buildAuthToggle(l10n),
              const SizedBox(height: 32.0),

              // 3. CAMPOS DE TEXTO ESTATICOS (FUERA DE LA ANIMACIÓN)
              CustomInputField(
                controller: _emailController,
                labelText: l10n.emailLabel,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 16.0),
              CustomPasswordField(
                controller: _passwordController,
              ),
              const SizedBox(height: 32.0), // Separación antes de la parte animada

              // 4. SECCIÓN INFERIOR ANIMADA (BOTÓN Y ENLACE)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildAuthFormBody(l10n, _isLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
