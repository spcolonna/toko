import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/screens/Toko/my_band_screen.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/screens/Toko/create_band_screen.dart';

import 'Band/band_profile_screen.dart';
import 'Entities/management_card.dart';
import 'Profile/musician_profile_screen.dart';
import '../WelcomeScreen.dart';


class ManagementDecisorScreen extends StatelessWidget {
  const ManagementDecisorScreen({super.key});

  // --- LÓGICA DE LOGOUT ---
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // 1. Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada con éxito.')),
      );

      // 2. Redirigir a la pantalla de bienvenida/login (limpiando la pila de navegación)
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()), // Reemplaza por tu pantalla de Login/Welcome
              (Route<dynamic> route) => false, // Elimina todas las rutas anteriores
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Inicia sesión para gestionar.', style: TextStyle(color: AppColors.textWhite)));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final bandId = userData?['managedBandId'] as String?;
        final bool hasBand = bandId != null && bandId.isNotEmpty;

        final Widget bandManagementWidget = hasBand
            ? ManagementCard(
          icon: Icons.mic_external_on,
          title: 'Administrar Mi Banda',
          subtitle: 'Gestiona eventos, miembros y métricas.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MyBandScreen()),
            );
          },
        )
            : ManagementCard(
          icon: Icons.add_circle,
          title: 'Crear una Nueva Banda',
          subtitle: 'Establece tu perfil y comienza a publicar.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CreateBandScreen()),
            );
          },
        );

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          // 📌 AÑADIMOS EL APP BAR Y EL BOTÓN DE LOGOUT
          appBar: AppBar(
            automaticallyImplyLeading: false, // Asegura que no aparezca la flecha de regreso si es el tab principal
            title: const Text('Mi Gestión', style: TextStyle(color: AppColors.textWhite)),
            backgroundColor: AppColors.backgroundDark,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                tooltip: 'Cerrar Sesión',
                onPressed: () => _logout(context), // Llama a la función de logout
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eliminamos el título duplicado, ya está en el AppBar

                  // OPCIÓN A: GESTIÓN DE BANDA (Condicional)
                  bandManagementWidget,
                  const SizedBox(height: 20),

                  // OPCIÓN B: GESTIÓN DE PERFIL DE MÚSICO (Siempre disponible)
                  ManagementCard(
                    icon: Icons.person_pin,
                    title: 'Mi Perfil de Músico',
                    subtitle: 'Edita tus datos personales y gestiona tus ofertas de Match.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MusicianProfileScreen(currentUserId: user.uid)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
// NOTA: EL WIDGET ManagementCard DEBE ESTAR DEFINIDO EN 'Entities/management_card.dart'
