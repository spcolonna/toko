import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';

class InterestsReceivedScreen extends StatelessWidget {
  final String postId;
  const InterestsReceivedScreen({super.key, required this.postId});

  // Función para simular el contacto de vuelta (Abriendo la app de correo)
  void _contactBand(String email, BuildContext context) {
    // Aquí iría la lógica real para usar 'url_launcher' y abrir el cliente de correo.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo cliente de correo para contactar a $email.'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consultar la subcolección 'contact_requests' de esta publicación del músico
    final Stream<QuerySnapshot> requestsStream = FirebaseFirestore.instance
        .collection('match_posts')
        .doc(postId)
        .collection('contact_requests') // <-- Subcolección de Solicitudes
        .orderBy('requestedAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Solicitudes de Contacto', style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar solicitudes: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay bandas interesadas en tu perfil.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              final date = (request['requestedAt'] as Timestamp).toDate();
              final messageSnippet = (request['message'] as String?)?.substring(0, 30) ?? 'Mensaje no disponible';

              return Card(
                color: AppColors.secondaryColor.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(request['bandName'] ?? 'Banda Desconocida', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(messageSnippet, style: TextStyle(color: AppColors.textSecondary)),
                      Text('Solicitado: ${DateFormat('MMM d, HH:mm').format(date)}', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _contactBand(request['contactEmail'], context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                    child: const Text('Contactar', style: TextStyle(color: AppColors.textWhite)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
