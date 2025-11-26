import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toko/theme/AppColors.dart';

class MyMatchPostsScreen extends StatelessWidget {
  const MyMatchPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    // Consulta: Obtener todos los posts de Músico Ofreciéndose creados por el usuario actual
    final Stream<QuerySnapshot> myPostsStream = FirebaseFirestore.instance
        .collection('match_posts')
        .where('type', isEqualTo: 'MUSICIAN_OFFER')
        .where('creatorId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: myPostsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)));
        }

        final posts = snapshot.data?.docs ?? [];
        if (posts.isEmpty) {
          return const Center(child: Text('Aún no has publicado tu perfil de músico.', style: TextStyle(color: AppColors.textSecondary)));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final roles = (post['rolesNeeded'] as List?)?.join(', ') ?? 'N/A';

            return ListTile(
              title: Text(post['name'] ?? 'Mi Oferta', style: const TextStyle(color: AppColors.textWhite)),
              subtitle: Text('Roles: $roles | Estado: ${post['status']}', style: const TextStyle(color: AppColors.textSecondary)),
              trailing: const Icon(Icons.edit, color: AppColors.textSecondary),
              onTap: () {
                // TODO: Navegar a la edición del post o al panel de mensajes
              },
            );
          },
        );
      },
    );
  }
}
