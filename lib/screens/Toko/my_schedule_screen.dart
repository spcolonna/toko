import 'package:flutter/material.dart';
import 'package:toko/theme/AppColors.dart';

class MyScheduleScreen extends StatelessWidget {
  const MyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Sección 3: Mi Agenda',
        style: TextStyle(color: AppColors.textWhite, fontSize: 24),
      ),
    );
  }
}
