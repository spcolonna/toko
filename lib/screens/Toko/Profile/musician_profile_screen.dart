import 'package:flutter/material.dart';
import 'package:toko/theme/AppColors.dart';

import 'musician_data_tab.dart';
import 'my_match_offers_tab.dart';

class MusicianProfileScreen extends StatelessWidget {
  final String currentUserId;

  const MusicianProfileScreen({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: const Text('Mi Perfil de Músico', style: TextStyle(color: AppColors.textWhite)),
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.primaryColor,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Mis Datos', icon: Icon(Icons.person)),
              Tab(text: 'Mis Publicaciones', icon: Icon(Icons.mic)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña 1: Edición de Datos Personales
            MusicianDataTab(userId: currentUserId),
            // Pestaña 2: Visualización de Posts de Oferta
            MyMatchOffersTab(userId: currentUserId),
          ],
        ),
      ),
    );
  }
}
