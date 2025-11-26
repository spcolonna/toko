import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';

class MatchMusicianOfferScreen extends StatelessWidget {
  MatchMusicianOfferScreen({super.key});

  void _requestContact(String postId, String creatorId, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Solicitando contacto al músico ID: $creatorId. (Mensaje o Chat en proceso...)'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consulta: Músicos ofreciéndose
    final Stream<QuerySnapshot> musicianOfferStream = FirebaseFirestore.instance
        .collection('match_posts')
        .where('type', isEqualTo: 'MUSICIAN_OFFER')
        .where('status', isEqualTo: 'Open')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: musicianOfferStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar publicaciones: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return const Center(child: Text('No hay músicos ofreciéndose en este momento.', style: TextStyle(color: AppColors.textSecondary)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final postId = posts[index].id;

            // ✅ CORRECCIÓN 1: Asegurar que 'rolesNeeded' es una lista de strings
            final List<String> roles = List<String>.from(post['rolesNeeded'] ?? []);

            // ✅ CORRECCIÓN 2: Asegurar que 'genres' es una lista de strings
            final List<String> genres = List<String>.from(post['genres'] ?? []);

            final creatorId = post['creatorId'];

            return Card(
              color: AppColors.secondaryColor.withOpacity(0.3),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.person, color: AppColors.textWhite),
                title: Text(post['name'] ?? 'Músico Anónimo', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                // 📌 APLICAR CORRECCIÓN
                subtitle: Text('Toca: ${roles.join(', ')} | Géneros: ${genres.join(', ')}', style: TextStyle(color: AppColors.textSecondary)),
                trailing: ElevatedButton(
                  onPressed: () => _requestContact(postId, creatorId, context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text('Solicitar Contacto', style: TextStyle(color: AppColors.textWhite)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
