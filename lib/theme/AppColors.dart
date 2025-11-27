// lib/theme/AppColors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Paleta "DARK ROCK" para TOKO

  // Fondo Principal: Negro Amp (#181414)
  static const Color backgroundDark = Color(0xFF181414);

  // Fondo de Tarjetas/Inputs: Gris Carbón (#2C2828)
  static const Color secondaryColor = Color(0xFF2C2828); // Reutilizamos secondaryColor para el fondo de cards

  // Primario (Acento): Naranja Fuego (#FF4500) - CTA, likes, alertas
  static const Color primaryColor = Color(0xFFFF4500);

  // Secundario (Metálico): Gris Aluminio (#D3D3D3) - Iconos, bordes inactivos
  static const Color textSecondary = Color(0xFFD3D3D3);

  // Texto Principal Claro: Blanco Sucio (#F0F0F0)
  static const Color textWhite = Color(0xFFF0F0F0);

  // (Opcional) Color de Éxito, si se necesita
  static const Color successColor = Color(0xFF32CD32);

  // Alias mantenido
  static const Color backgroundGray = backgroundDark;
}
