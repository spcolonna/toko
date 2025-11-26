import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';

import 'Events/event_detail_screen.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: AppColors.backgroundDark, body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor))),);
        }

        final User? user = authSnapshot.data;
        if (user == null) {
          return const Scaffold(backgroundColor: AppColors.backgroundDark, body: Center(child: Text('Debes iniciar sesión para ver los eventos.', style: TextStyle(color: AppColors.textSecondary))),);
        }

        final String currentUserId = user.uid;

        final Stream<QuerySnapshot> eventsStream = FirebaseFirestore.instance
            .collection('events')
            .where('date', isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy('date', descending: false)
            .snapshots();

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            title: const Text('Próximos Eventos', style: TextStyle(color: AppColors.textWhite)),
            backgroundColor: AppColors.backgroundDark,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: eventsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error al cargar eventos: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
              }

              final events = snapshot.data?.docs ?? [];

              if (events.isEmpty) {
                return const Center(child: Text('No hay eventos programados.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final eventDoc = events[index];
                  final eventId = eventDoc.id;
                  final eventData = eventDoc.data() as Map<String, dynamic>;

                  return EventCard(
                    eventId: eventId,
                    eventData: eventData,
                    currentUserId: currentUserId,
                    onTap: () {
                      // 📌 NAVEGACIÓN IMPLEMENTADA
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(
                            eventId: eventId,
                            currentUserId: currentUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// El widget EventCard debe ser definido en este archivo o importado
class EventCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final String currentUserId;
  final VoidCallback? onTap; // Añadido para permitir la acción de navegación

  EventCard({
    super.key,
    required this.eventId,
    required this.eventData,
    required this.currentUserId,
    this.onTap,
  });

  // Función para manejar la asistencia (Add/Remove User ID)
  Future<void> toggleAttendance() async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    final List<String> attendees = List<String>.from(eventData['attendees'] ?? []);
    final isGoing = attendees.contains(currentUserId);
    final updateData = {'attendees': isGoing ? FieldValue.arrayRemove([currentUserId]) : FieldValue.arrayUnion([currentUserId])};
    try {
      await eventRef.update(updateData);
    } catch (e) {
      print('Error al actualizar asistencia: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = (eventData['date'] as Timestamp).toDate();
    final List<String> attendees = List<String>.from(eventData['attendees'] ?? []);
    final bool isGoing = attendees.contains(currentUserId);
    final int attendeeCount = attendees.length;

    return GestureDetector(
      onTap: onTap, // Usa el callback onTap para la navegación
      child: Card(
        color: AppColors.secondaryColor.withOpacity(0.3),
        margin: const EdgeInsets.only(bottom: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... (Contenido del card)
              Row(children: [
                Column(children: [
                  Text(DateFormat('MMM', 'es').format(date).toUpperCase(), style: const TextStyle(color: AppColors.primaryColor, fontSize: 12)),
                  Text(DateFormat('dd').format(date), style: const TextStyle(color: AppColors.primaryColor, fontSize: 24, fontWeight: FontWeight.bold)),
                ]), const SizedBox(width: 16),
                Expanded(child: Text(eventData['title'] ?? 'Evento sin título', style: const TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold))),
              ]),
              const Divider(color: AppColors.secondaryColor, height: 24),
              Text('${eventData['place'] ?? 'Lugar no especificado'}', style: const TextStyle(color: AppColors.textSecondary)),
              Text('Hora: ${DateFormat('HH:mm').format(date)}', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Row(children: [const Icon(Icons.people, color: AppColors.textSecondary, size: 18), const SizedBox(width: 4), Text('$attendeeCount personas van', style: const TextStyle(color: AppColors.textSecondary)),]),
              const SizedBox(height: 16),

              // Botón de Asistencia
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: toggleAttendance,
                  icon: Icon(isGoing ? Icons.check_circle : Icons.person_add, color: AppColors.textWhite),
                  label: Text(isGoing ? '¡Estás Asistiendo!' : 'Quiero Asistir', style: const TextStyle(fontSize: 16, color: AppColors.textWhite)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGoing ? AppColors.primaryColor.withOpacity(0.8) : AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
