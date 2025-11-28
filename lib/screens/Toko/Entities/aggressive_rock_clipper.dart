// lib/widgets/aggressive_rock_clipper.dart (Hombros Redondeados, Base Angular Agresiva)

import 'package:flutter/material.dart';

class AggressiveRockClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();

    final double w = size.width;
    final double h = size.height;

    // --- Puntos y Curvas ---

    // 1. Punto de inicio (después del redondeo del hombro superior izquierdo)
    path.moveTo(w * 0.15, 0); // Empieza un poco más adentro en la parte superior

    // 2. Curva superior IZQUIERDA (Redondeo del hombro)
    path.quadraticBezierTo(w * 0.0, 0,          // Punto de control: Borde superior izquierdo
        w * 0.0, h * 0.15);  // Llega al borde izquierdo, 15% abajo (inicio del lado)

    // 3. Lado izquierdo hacia abajo, conectando con el punto de control de la base angular
    path.quadraticBezierTo(w * 0.1, h * 0.7,    // Punto de control para la curva descendente
        w * 0.4, h);         // Punto final de la punta inferior izquierda (del original)

    // 4. Parte inferior (línea recta que conecta las dos puntas de la base)
    path.lineTo(w * 0.6, h); // Conecta con la punta inferior derecha (del original)

    // 5. Lado derecho hacia arriba, conectando con el punto de control de la base angular
    path.quadraticBezierTo(w * 0.9, h * 0.7,    // Punto de control para la curva ascendente
        w * 1.0, h * 0.15);  // Llega al borde derecho, 15% abajo (inicio del lado)

    // 6. Curva superior DERECHA (Redondeo del hombro)
    path.quadraticBezierTo(w * 1.0, 0,          // Punto de control: Borde superior derecho
        w * 0.85, 0);       // Vuelve a la parte superior, 15% desde el borde derecho

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
