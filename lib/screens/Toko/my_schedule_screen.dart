import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';

class MyScheduleScreen extends StatelessWidget {
  const MyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Debes iniciar sesión para ver tu agenda.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final String currentUserId = user.uid;

    final Stream<QuerySnapshot> rsvpStream = FirebaseFirestore.instance
        .collection('events')
        .where('attendees', arrayContains: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.now()) // ✅ FILTRO PARA SOLO EVENTOS FUTUROS
        .orderBy('date', descending: false)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      // 1. 📌 CORRECCIÓN DE UI: Añadir AppBar
      appBar: AppBar(
        title: const Text('Mi Agenda (Asistencias)', style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: SafeArea( // 2. 📌 CORRECCIÓN DE UI: Usar SafeArea para evitar el notch
        child: StreamBuilder<QuerySnapshot>(
          stream: rsvpStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
            }

            // 🛑 Manejo de error de índice:
            if (snapshot.hasError) {
              print('--- FIREBASE INDEX ERROR DIAGNOSTIC ---');
              print('Consulta Fallida en MyScheduleScreen: ${snapshot.error}');
              print('-----------------------------------------');
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    '🚨 ¡Error de configuración de la BD! Revisa la consola (Debug Console) para copiar el enlace de creación del índice.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                ),
              );
            }

            final events = snapshot.data?.docs ?? [];

            if (events.isEmpty) {
              return const Center(
                child: Text(
                    'Aún no tienes asistencias confirmadas a eventos futuros. ¡Sal y apoya!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary)
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final eventData = events[index].data() as Map<String, dynamic>;
                final date = (eventData['date'] as Timestamp).toDate();

                return Card(
                  color: AppColors.secondaryColor.withOpacity(0.3),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.primaryColor, width: 2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(DateFormat('MMM').format(date).toUpperCase(), style: const TextStyle(color: AppColors.textWhite, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(DateFormat('dd').format(date), style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    title: Text(eventData['title'] ?? 'Evento sin título', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${eventData['place'] ?? 'Lugar no especificado'} | ${DateFormat('HH:mm').format(date)}',
                        style: TextStyle(color: AppColors.textSecondary)
                    ),
                    trailing: const Icon(Icons.check_circle_outline, color: AppColors.primaryColor, size: 28),
                    onTap: () {
                      // TODO: Implementar navegación a los detalles del evento
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
