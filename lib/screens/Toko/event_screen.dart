import 'package:flutter/material.dart';
import 'package:toko/theme/AppColors.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Sección 1: Eventos',
        style: TextStyle(color: AppColors.textWhite, fontSize: 24),
      ),
    );
  }
}
