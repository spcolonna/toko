import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toko/theme/AppColors.dart';
import 'apply_form_screen.dart'; // Importa el formulario de postulación

class MatchBandSearchScreen extends StatelessWidget {
  const MatchBandSearchScreen({super.key});

  // Lógica de postulación (solo verifica si el usuario ya aplicó)
  Future<void> _applyToPost(String postId, String userId, BuildContext context, String bandName) async {
    final postRef = FirebaseFirestore.instance.collection('match_posts').doc(postId);

    // Aquí implementamos la navegación al formulario de contacto
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ApplyFormScreen(
          postId: postId,
          currentUserId: userId,
          bandName: bandName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Inicia sesión para ver vacantes.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final currentUserId = user.uid;

    // Consulta Compuesta: Requiere el índice [type (asc), status (asc), createdAt (desc)]
    final Stream<QuerySnapshot> bandSearchStream = FirebaseFirestore.instance
        .collection('match_posts')
        .where('type', isEqualTo: 'BAND_SEARCH')
        .where('status', isEqualTo: 'Open')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: bandSearchStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }

        // 🚨 MANEJO DE ERROR DE ÍNDICE (para obtener la URL)
        if (snapshot.hasError) {
          final errorText = snapshot.error.toString();
          print('--- FIREBASE INDEX ERROR DIAGNOSTIC ---');
          print('Consulta Match Fallida (BAND_SEARCH): ${snapshot.error}');
          print('-----------------------------------------');

          if (errorText.contains('The query requires an index')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 40),
                    const SizedBox(height: 10),
                    const Text('🚨 ¡Índice de Firestore Requerido!', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                      'Revisa la consola para copiar el enlace directo de creación. Índice Requerido: `type` (Asc), `status` (Asc), `createdAt` (Desc).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(child: Text('Error al cargar publicaciones: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay bandas buscando músicos en este momento.', style: TextStyle(color: AppColors.textSecondary)));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final postId = posts[index].id;
            final bandName = post['bandName'] ?? 'Banda Desconocida';
            final roles = (post['rolesNeeded'] as List?)?.join(', ') ?? 'Varios';
            final genres = (post['genres'] as List?)?.join(', ') ?? 'N/A';

            // Usamos 'applicantsUids' para chequear si ya postuló
            final applicantsUids = List<String>.from(post['applicantsUids'] ?? []);
            final hasApplied = applicantsUids.contains(currentUserId);

            return Card(
              color: AppColors.secondaryColor.withOpacity(0.3),
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(bandName, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                subtitle: Text('Busca: $roles | Géneros: $genres | Ciudad: ${post['city']}', style: TextStyle(color: AppColors.textSecondary)),
                onTap: () {
                  // TODO: Navegar a los detalles de la publicación
                },
                trailing: ElevatedButton(
                  onPressed: hasApplied ? null : () => _applyToPost(postId, currentUserId, context, bandName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasApplied ? AppColors.textSecondary.withOpacity(0.5) : AppColors.primaryColor,
                  ),
                  child: Text(hasApplied ? 'Postulado' : 'Postularme', style: const TextStyle(color: AppColors.textWhite)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
