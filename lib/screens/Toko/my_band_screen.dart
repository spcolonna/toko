import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';

import 'Band/band_metrics_screen.dart';
import 'Band/band_profile_screen.dart';

// --- Placeholder/Clases de Sub-pantallas ---
class BandEventsManagerScreen extends StatelessWidget {
  final String bandId;
  const BandEventsManagerScreen({super.key, required this.bandId});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('2. Crear y Gestionar Eventos para $bandId', style: const TextStyle(color: AppColors.textWhite)));
  }
}

// ---------------------------------------------

class MyBandScreen extends StatelessWidget {
  const MyBandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Authentication Error.', style: TextStyle(color: AppColors.textWhite)));
    }

    // El StreamBuilder lee el documento del usuario para obtener el ID de la banda
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final bandId = userData?['mainBandId'] as String?;

        // 🛑 Seguridad: Si llega aquí sin ID de banda (aunque el hasBand lo previene)
        if (bandId == null) {
          return const Center(
            child: Text(
              'Error: No se encontró el ID de la banda asociada.',
              style: TextStyle(color: AppColors.textWhite),
            ),
          );
        }

        // --- DASHBOARD PRINCIPAL CON TAB BAR ---
        return DefaultTabController(
          length: 3, // Perfil, Eventos, Métricas
          child: Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundDark,
              automaticallyImplyLeading: false, // Ocultar el botón de retroceso
              title: const Text('Dashboard de Mi Banda', style: TextStyle(color: AppColors.textWhite)),
              elevation: 0,
              bottom: TabBar(
                indicatorColor: AppColors.primaryColor, // Indicador Rojo Coral
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(icon: Icon(Icons.edit_note), text: 'Perfil'),
                  Tab(icon: Icon(Icons.event), text: 'Eventos'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Métricas'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // 1. Perfil Editable
                BandProfileScreen(bandId: bandId),

                // 2. Gestión de Eventos
                BandEventsManagerScreen(bandId: bandId),

                // 3. Métricas
                BandMetricsScreen(bandId: bandId),
              ],
            ),
          ),
        );
      },
    );
  }
}
