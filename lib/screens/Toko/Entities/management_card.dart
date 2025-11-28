import 'package:flutter/material.dart';
import '../../../theme/AppColors.dart';

class ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ManagementCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.secondaryColor.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor, size: 30),
        title: Text(title, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 16),
        onTap: onTap,
      ),
    );
  }
}
