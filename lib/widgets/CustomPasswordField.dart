import 'package:flutter/material.dart';
import 'package:toko/theme/AppColors.dart'; // Importamos tu paleta de colores
import '../l10n/app_localizations.dart';

class CustomPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator; // 📌 Permitir validación

  const CustomPasswordField({
    super.key,
    required this.controller,
    this.validator, // Aceptar el validador
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  late AppLocalizations l10n;
  bool _isObscured = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 📌 Solucionado: Obtener la instancia de l10n
    l10n = AppLocalizations.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField( // 📌 Usamos TextFormField para compatibilidad con formularios
      controller: widget.controller,
      obscureText: _isObscured,
      validator: widget.validator ?? (value) {
        if (value == null || value.isEmpty) {
          return 'La contraseña es obligatoria.';
        }
        return null;
      },
      style: const TextStyle(color: AppColors.textWhite),
      decoration: InputDecoration(
        labelText: l10n.passwordLabel, // 📌 Usar clave de localización
        labelStyle: TextStyle(color: AppColors.textSecondary), // Gris Aluminio

        // 📌 ÍCONO DE PREFIJO: Aplicamos el color Gris Aluminio
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),

        // Estilos de borde
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
        ),
        // 📌 Borde de FOCO: Aplica el color Primario (Naranja Fuego)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
        ),

        // ÍCONO DE SUFIJO (Mostrar/Ocultar)
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility : Icons.visibility_off,
            color: AppColors.textSecondary, // Color Gris Aluminio
          ),
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        ),
      ),
    );
  }
}
