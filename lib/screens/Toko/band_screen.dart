import 'package:flutter/material.dart';
import 'package:toko/theme/AppColors.dart';

class BandScreen extends StatelessWidget {
  const BandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Sección 2: Bandas',
        style: TextStyle(color: AppColors.textWhite, fontSize: 24),
      ),
    );
  }
}
