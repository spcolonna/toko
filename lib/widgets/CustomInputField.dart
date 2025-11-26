import 'package:flutter/material.dart';

import '../theme/AppColors.dart';

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool isObscure;
  final int maxLines;
  final String? hintText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.isObscure = false,
    this.maxLines = 1,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField( // 📌 CAMBIO CLAVE: Usar TextFormField
      controller: controller,
      obscureText: isObscure,
      maxLines: maxLines,
      keyboardType: keyboardType, // Pasar el tipo de teclado
      validator: validator, // 📌 IMPLEMENTACIÓN DE VALIDATOR

      style: const TextStyle(color: AppColors.textWhite),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.secondaryColor.withOpacity(0.2), // Asumo que usas este fondo para inputs

        // Estilos de borde para TextFormField
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        // 📌 IMPORTANTE: Mostrar error de validación
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 14),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }
}
