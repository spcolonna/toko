import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'contact_request_form_screen.dart'; // Importamos el nuevo formulario de solicitud

class MatchMusicianOfferScreen extends StatelessWidget {
  MatchMusicianOfferScreen({super.key});

  void _navigateToContactForm(String postId, String musicianUid, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContactRequestFormScreen(
          postId: postId,
          musicianUid: musicianUid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Imprime el error de índice completo para diagnóstico
          print('Error de consulta Match Musician Offer: ${snapshot.error}');
          return Center(child: Text('Error al cargar publicaciones. Revisa la consola.', style: const TextStyle(color: Colors.redAccent)));
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

            // ✅ CORRECCIÓN DE TIPADO: Asegurar que 'rolesNeeded' y 'genres' son listas
            final List<String> roles = List<String>.from(post['rolesNeeded'] ?? []);
            final List<String> genres = List<String>.from(post['genres'] ?? []);

            final creatorId = post['creatorId'];

            return Card(
              color: AppColors.secondaryColor.withOpacity(0.3),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(Icons.person, color: AppColors.textWhite),
                title: Text(post['name'] ?? 'Músico Anónimo', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                // Subtítulo con los datos unidos
                subtitle: Text('Toca: ${roles.join(', ')} | Géneros: ${genres.join(', ')}', style: TextStyle(color: AppColors.textSecondary)),
                trailing: ElevatedButton(
                  // 📌 Llamada a la navegación con el UID del músico
                  onPressed: () => _navigateToContactForm(postId, creatorId, context),
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
