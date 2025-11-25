import 'package:flutter/material.dart';

import '../theme/AppColors.dart';

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool isObscure;
  final int maxLines;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.isObscure = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textWhite),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        // ... (otros estilos de decoración, como border, fill color, etc.)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
      ),
    );
  }
}
