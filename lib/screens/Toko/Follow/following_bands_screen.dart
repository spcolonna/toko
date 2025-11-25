import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toko/theme/AppColors.dart';
import '../Band/band_public_profile_screen.dart';

class FollowingBandsScreen extends StatelessWidget {
  const FollowingBandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Inicia sesión para ver tus favoritas.', style: TextStyle(color: AppColors.textWhite)));
    }

    // 1. Stream: Obtener las listas de IDs de bandas (seguidas y con like) del usuario
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Error al cargar datos de usuario.', style: TextStyle(color: AppColors.textWhite)));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final List<String> followingBands = List<String>.from(userData['followingBands'] ?? []);
        final List<String> likedBands = List<String>.from(userData['likedBands'] ?? []);

        final Set<String> uniqueBandIds = {...followingBands, ...likedBands};

        if (uniqueBandIds.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                  'Aún no sigues ni has dado "Me Gusta" a ninguna banda. ¡Ve a la pestaña Descubrir!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)
              ),
            ),
          );
        }

        // 2. Future: Consultar la información detallada de esas bandas por ID
        return FutureBuilder<QuerySnapshot>(
          // Firestore solo permite un máximo de 10 IDs en el whereIn
          future: FirebaseFirestore.instance
              .collection('bands')
              .where(FieldPath.documentId, whereIn: uniqueBandIds.take(10).toList())
              .get(),
          builder: (context, bandSnapshot) {
            if (bandSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
            }
            if (!bandSnapshot.hasData || bandSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No se encontró información de las bandas.', style: TextStyle(color: AppColors.textWhite)));
            }

            final bands = bandSnapshot.data!.docs;

            return ListView.builder(
              itemCount: bands.length,
              itemBuilder: (context, index) {
                final bandDoc = bands[index];
                final bandData = bandDoc.data() as Map<String, dynamic>;
                final bandId = bandDoc.id;

                final isFollowing = followingBands.contains(bandId);
                final isLiked = likedBands.contains(bandId);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondaryColor,
                    backgroundImage: bandData['logoUrl'] != null ? NetworkImage(bandData['logoUrl']) : null,
                    child: bandData['logoUrl'] == null ? const Icon(Icons.mic, color: AppColors.textWhite) : null,
                  ),
                  title: Text(bandData['name'] ?? 'Banda Sin Nombre', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${bandData['city'] ?? 'N/A'} | ${bandData['followersCount'] ?? 0} seguidores',
                      style: TextStyle(color: AppColors.textSecondary)
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLiked) const Icon(Icons.favorite, color: AppColors.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      if (isFollowing) const Icon(Icons.check_circle, color: AppColors.secondaryColor, size: 20),
                    ],
                  ),
                  onTap: () {
                    // IMPLEMENTACIÓN: Navegar al perfil público de la banda
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BandPublicProfileScreen(bandId: bandId),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
