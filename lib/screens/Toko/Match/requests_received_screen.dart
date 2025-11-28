import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:intl/intl.dart';
import 'contact_request_detail_screen.dart'; // Importamos la pantalla de destino

class RequestsReceivedScreen extends StatelessWidget {
  final String userId;
  const RequestsReceivedScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Consulta: Subcolección de solicitudes de contacto en el perfil del músico
    final Stream<QuerySnapshot> requestsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('contactRequests')
        .orderBy('requestedAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Buzón de Solicitudes', style: TextStyle(color: AppColors.textWhite)),
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
                  'Aún no has recibido solicitudes de contacto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final requestDoc = requests[index];
              final request = requestDoc.data() as Map<String, dynamic>;
              final date = (request['requestedAt'] as Timestamp).toDate();

              return Card(
                color: AppColors.secondaryColor.withOpacity(0.3),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(request['bandId'] ?? 'Banda Desconocida', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                  subtitle: Text('Mensaje: ${request['message']}\nContacto: ${request['contactEmail']}', style: TextStyle(color: AppColors.textSecondary)),
                  trailing: Text(DateFormat('MMM d').format(date), style: TextStyle(color: AppColors.textSecondary)),
                  onTap: () {
                    // 📌 NAVEGACIÓN IMPLEMENTADA: Va al detalle de la solicitud
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ContactRequestDetailScreen(requestData: request),
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
