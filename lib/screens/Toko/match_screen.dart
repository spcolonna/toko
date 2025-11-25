import 'package:flutter/material.dart';
import 'package:toko/theme/AppColors.dart';

class MatchScreen extends StatelessWidget {
  const MatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Sección 4: Match',
        style: TextStyle(color: AppColors.textWhite, fontSize: 24),
      ),
    );
  }
}
