import 'package:flutter/material.dart';
import 'package:toko/theme/AppColors.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Cambiado a VoidCallback?
  final bool isLoading; // 📌 NUEVO: Flag de carga

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false, // 📌 Valor por defecto
  });

  @override
  Widget build(BuildContext context) {
    // 📌 La acción onPressed debe ser nula si está cargando
    final buttonOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: buttonOnPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          side: const BorderSide(color: AppColors.primaryColor, width: 2),
          foregroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // 📌 CONTENIDO: Muestra el indicador si está cargando
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            // ✅ SOLUCIÓN: Usar AlwaysStoppedAnimation para el tipo Color
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        )
            : Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}
