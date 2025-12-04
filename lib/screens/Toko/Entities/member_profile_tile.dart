import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/AppColors.dart';
import 'member_details.dart';

class MemberProfileTile extends StatelessWidget {
  final MemberDetails member;

  const MemberProfileTile({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.secondaryColor.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile( // Usamos ExpansionTile para mostrar la Bio y Roles
        title: Text(member.name, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        subtitle: Text(member.role, style: TextStyle(color: AppColors.primaryColor)),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryColor.withOpacity(0.2),
          backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
          child: member.photoUrl == null ? Icon(member.isTokoUser ? Icons.person : Icons.mic, color: AppColors.textWhite) : null,
        ),
        collapsedIconColor: AppColors.textSecondary,
        iconColor: AppColors.primaryColor,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📌 MOSTRAR DESCRIPCIÓN (Bio)
                Text('Descripción:', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(member.bio, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 10),

                // 📌 MOSTRAR FECHA DE NACIMIENTO
                if (member.birthDate != null)
                  Text(
                    'Fecha de Nacimiento: ${DateFormat.yMMMd().format(member.birthDate!)}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
