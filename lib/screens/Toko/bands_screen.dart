import 'package:flutter/material.dart';
import 'package:toko/theme/AppColors.dart';
import 'Band/discover_bands_screen.dart';
import 'Follow/following_bands_screen.dart';

class BandsScreen extends StatelessWidget {
  const BandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Descubrir y Seguidas
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: const Text('Bandas', style: TextStyle(color: AppColors.textWhite)),
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          // El buscador y filtros de DiscoverBandsScreen ya no están aquí, solo el TabBar
          bottom: TabBar(
            indicatorColor: AppColors.primaryColor,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'Descubrir', icon: Icon(Icons.search)),
              Tab(text: 'Seguidas', icon: Icon(Icons.star)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 1. Buscador y Carga Infinita (El código BandsScreen original)
            DiscoverBandsScreen(),
            // 2. Bandas Favoritas/Seguidas
            FollowingBandsScreen(),
          ],
        ),
      ),
    );
  }
}
