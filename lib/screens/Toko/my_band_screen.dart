// my_band_screen.dart (Contenido del Tab 5)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'create_band_screen.dart'; // Importamos la nueva pantalla

class MyBandScreen extends StatelessWidget {
  const MyBandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Manejar el caso si el usuario no está logueado (aunque no debería pasar)
      return const Center(child: Text('Error de autenticación.', style: TextStyle(color: AppColors.textWhite)));
    }

    // Escuchamos el documento del usuario para saber si tiene banda
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }

        // Verifica si el campo 'hasBand' está en true
        final hasBand = snapshot.data?.get('hasBand') ?? false;

        if (hasBand) {
          // Opción A: Ya tiene banda -> Muestra el Dashboard de la banda
          return const Center(
            child: Text(
              'Dashboard de Mi Banda (¡A construir!)',
              style: TextStyle(color: AppColors.textWhite, fontSize: 20),
            ),
          );
        } else {
          // Opción B: No tiene banda -> Muestra el botón para crearla
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '¡Potencia tu música! Crea el perfil de tu banda ahora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textWhite, fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navegación modal a la pantalla de creación
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CreateBandScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Crear Banda',
                    style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
