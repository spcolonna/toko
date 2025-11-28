import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import '../Match/edit_match_post_screen.dart';
import '../Match/interests_received_screen.dart';

class MyMatchOffersTab extends StatelessWidget {
  final String userId;
  const MyMatchOffersTab({super.key, required this.userId});

  // Función para manejar la navegación a la edición
  void _navigateToEditPost(BuildContext context, String postId, Map<String, dynamic> postData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditMatchPostScreen(
          postId: postId,
          initialData: postData,
          isBandPost: false, // Es un post de músico
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consulta: Publicaciones de TIPO 'MUSICIAN_OFFER' creadas por este userId
    final Stream<QuerySnapshot> myOffersStream = FirebaseFirestore.instance
        .collection('match_posts')
        .where('type', isEqualTo: 'MUSICIAN_OFFER')
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: myOffersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }

        if (snapshot.hasError) {
          print('--- FIREBASE INDEX ERROR DIAGNOSTIC ---');
          print('Consulta de Ofertas Fallida (MyMatchOffersTab): ${snapshot.error}');
          print('-----------------------------------------');
          return const Center(child: Text('🚨 Error al cargar publicaciones. Revisa la consola.', style: TextStyle(color: Colors.redAccent)));
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
                'Aún no has publicado tu perfil de músico.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)
            ),
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postDoc = posts[index];
            final post = postDoc.data() as Map<String, dynamic>;
            final postId = postDoc.id;
            final roles = (post['rolesNeeded'] as List?)?.join(', ') ?? 'N/A';
            final status = post['status'] ?? 'Open';

            final interestedCount = post['applicantsCount'] ?? 0;

            return Card(
              color: AppColors.secondaryColor.withOpacity(0.3),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(post['name'] ?? 'Mi Oferta: $roles', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  'Estado: $status | Interesados: $interestedCount',
                  style: TextStyle(color: status == 'Open' ? AppColors.primaryColor : AppColors.textSecondary),
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    // Navegación al buzón de solicitudes
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => InterestsReceivedScreen(postId: postId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: interestedCount > 0 ? AppColors.primaryColor : AppColors.secondaryColor.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                  child: Text(
                    'Ver Solicitudes',
                    style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
                  ),
                ),
                onTap: () {
                  _navigateToEditPost(context, postId, post);
                },
              ),
            );
          },
        );
      },
    );
  }
}
