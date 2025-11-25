import 'package:flutter/material.dart';

class AppColors {
  // Paleta de colores de Toko (Estilo Púrpura Sofisticado)

  // 1. Fondo Oscuro/Principal: Púrpura Oscuro (Background Dark)
  // Uso: Fondo principal de todas las pantallas.
  static const Color backgroundDark = Color(0xFF262246); // #262246

  // 2. Primario (Acento Fuerte): Rojo Coral (Primary/Action Color)
  // Uso: Botones de acción principales, iconos de "Me gusta", indicadores de actividad.
  static const Color primaryColor = Color(0xFFF75753); // #F75753

  // 3. Secundario (Acento Suave/Contraste Header): Púrpura Rojizo (Secondary Color)
  // Uso: Headers, fondos de tarjetas (cards), elementos de UI de contraste sutil.
  static const Color secondaryColor = Color(0xFF7A4154); // #7A4154

  // 4. Texto Principal Claro: Blanco Cálido (Text White)
  // Uso: Todo el texto y la iconografía principal sobre fondos oscuros.
  static const Color textWhite = Color(0xFFFAF8F1); // #FAF8F1

  // 5. Texto/Fondo Terciario: Gris Violáceo Suave (Text Secondary)
  // Uso: Texto secundario, subtítulos, campos de input inactivos, divisores sutiles.
  static const Color textSecondary = Color(0xFF9492A0); // #9492A0

  // Alias mantenido por compatibilidad con el código anterior que usaba backgroundGray
  static const Color backgroundGray = backgroundDark;

  // Puedes añadir esto si quieres tener un gradiente predefinido para darle más profundidad
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF262246), Color(0xFF191630)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
