import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';

import 'Match/applications_admin_screen.dart';
import 'Band/band_metrics_screen.dart';
import 'Band/band_profile_screen.dart';
import 'Events/band_events_screen.dart';

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
          length: 4, // 📌 AHORA SON 4 PESTAÑAS
          child: Scaffold(
            backgroundColor: AppColors.backgroundDark,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundDark,
              automaticallyImplyLeading: false,
              title: const Text('Dashboard de Mi Banda', style: TextStyle(color: AppColors.textWhite)),
              elevation: 0,
              bottom: TabBar(
                indicatorColor: AppColors.primaryColor,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(icon: Icon(Icons.edit_note), text: 'Perfil'),
                  Tab(icon: Icon(Icons.event), text: 'Eventos'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Métricas'),
                  Tab(icon: Icon(Icons.email), text: 'Postulaciones'), // 📌 NUEVA PESTAÑA
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // 1. Perfil Editable
                BandProfileScreen(bandId: bandId),

                // 2. Gestión de Eventos
                BandEventsScreen(bandId: bandId),

                // 3. Métricas
                BandMetricsScreen(bandId: bandId),

                // 4. Postulaciones (Administración de Match)
                ApplicationsAdminScreen(bandId: bandId), // 📌 NUEVA VISTA
              ],
            ),
          ),
        );
      },
    );
  }
}
