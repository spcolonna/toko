import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'applicants_list_screen.dart';

class ApplicationsAdminScreen extends StatelessWidget {
  final String bandId;

  const ApplicationsAdminScreen({super.key, required this.bandId});

  @override
  Widget build(BuildContext context) {
    // Consulta: Publicaciones creadas por esta banda, ordenadas por fecha.
    // 🛑 REQUIERE ÍNDICE COMPUESTO: creatorId (asc) y createdAt (desc)
    final Stream<QuerySnapshot> bandPostsStream = FirebaseFirestore.instance
        .collection('match_posts')
        .where('creatorId', isEqualTo: bandId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: bandPostsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }

        // 🚨 MANEJO DE ERROR DE ÍNDICE
        if (snapshot.hasError) {
          final errorText = snapshot.error.toString();

          // 📌 ACCIÓN CLAVE: Imprimir el error completo que contiene la URL.
          print('--- FIREBASE INDEX ERROR DIAGNOSTIC ---');
          print('Consulta de Postulaciones Fallida: ${snapshot.error}');
          print('-----------------------------------------');

          if (errorText.contains('The query requires an index') || errorText.contains('firestore.googleapis.com')) {
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
                      'Para ver tus publicaciones, necesitas crear un índice compuesto. **Revisa la consola de depuración** para copiar el enlace directo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.secondaryColor, borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                        'Colección: `match_posts`\nCampos: `creatorId` (Asc), `createdAt` (Desc)',
                        textAlign: TextAlign.left,
                        style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          // Fallback para otros errores de Firebase
          return Center(child: Text('Error al cargar publicaciones: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No has creado ninguna publicación Match aún.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final postId = posts[index].id;

            final applicantsCount = post['applicantsCount'] ?? 0;
            final type = post['type'] == 'BAND_SEARCH' ? 'Búsqueda de Músico' : 'Oferta de Músico';

            return Card(
              color: AppColors.secondaryColor.withOpacity(0.3),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(
                  post['title'] ?? '$type - Sin Título',
                  style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$type | Postulantes: $applicantsCount',
                  style: TextStyle(color: applicantsCount > 0 ? AppColors.primaryColor : AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: () {
                  // Navegar a la lista de postulantes de esta publicación
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ApplicantsListScreen(
                        postId: postId,
                        postTitle: post['title'] ?? 'Publicación Sin Título',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
