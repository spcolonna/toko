import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';

import 'applicant_detail_screen.dart';

class ApplicantsListScreen extends StatelessWidget {
  final String postId;
  final String postTitle;

  const ApplicantsListScreen({super.key, required this.postId, required this.postTitle});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return Colors.greenAccent;
      case 'Viewed':
        return AppColors.primaryColor;
      case 'Contacted':
        return Colors.blueAccent;
      case 'Rejected':
        return Colors.redAccent;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext
  context) {
    // 2. Consultar la subcolección 'applicants' de la publicación
    final Stream<QuerySnapshot> applicantsStream = FirebaseFirestore.instance
        .collection('match_posts')
        .doc(postId)
        .collection('applicants')
        .orderBy('appliedAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Postulantes para: $postTitle', style: const TextStyle(color: AppColors.textWhite, fontSize: 16)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: applicantsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar postulantes: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Aún no hay postulaciones para esta publicación.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            );
          }

          final applicants = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final applicant = applicants[index].data() as Map<String, dynamic>;
              final applicantId = applicants[index].id;
              final status = applicant['status'] ?? 'New';

              return Card(
                color: AppColors.secondaryColor.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(applicant['name'] ?? 'Músico Desconocido', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Estado: $status',
                    style: TextStyle(color: _getStatusColor(status)),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary),
                  onTap: () {
                    // Navegar al detalle para ver el mensaje y gestionar el estado
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ApplicantDetailScreen(
                          postId: postId,
                          applicantId: applicantId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
