import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';
import 'create_event_screen.dart';
import 'edit_event_screen.dart'; // Importación para la edición

class BandEventsScreen extends StatelessWidget {
  final String bandId;
  const BandEventsScreen({super.key, required this.bandId});

  @override
  Widget build(BuildContext context) {
    // 1. Consulta: Todos los eventos de la banda (pasados y futuros).
    final Stream<QuerySnapshot> eventsStream = FirebaseFirestore.instance
        .collection('events')
        .where('bandId', isEqualTo: bandId)
        .orderBy('date', descending: true) // Ordena del más reciente/futuro al más antiguo
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,

      // Botón de acción flotante (FAB) para crear el evento
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegación a la pantalla de creación, pasando el bandId
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateEventScreen(bandId: bandId),
            ),
          );
        },
        label: const Text('Crear Evento', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: AppColors.textWhite),
        backgroundColor: AppColors.primaryColor,
      ),

      // 📜 Listado de eventos de la banda
      body: StreamBuilder<QuerySnapshot>(
        stream: eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
          }
          if (snapshot.hasError) {
            print('Error al cargar eventos en BandEventsScreen: ${snapshot.error}');
            return const Center(child: Text('Error al cargar eventos. Revisa tu consola.', style: TextStyle(color: Colors.red)));
          }

          final events = snapshot.data?.docs ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text(
                  'Aún no has creado ningún evento. ¡Presiona "+" para empezar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final eventDoc = events[index];
              final eventId = eventDoc.id;
              final eventData = eventDoc.data() as Map<String, dynamic>;
              final date = (eventData['date'] as Timestamp).toDate();
              final isFuture = date.isAfter(DateTime.now());

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFuture ? AppColors.primaryColor : AppColors.secondaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(DateFormat('MMM').format(date), style: const TextStyle(color: AppColors.textWhite, fontSize: 10)),
                      Text(DateFormat('dd').format(date), style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                title: Text(eventData['title'] ?? 'Evento sin título', style: const TextStyle(color: AppColors.textWhite)),
                subtitle: Text(
                    '${eventData['place']} | ${DateFormat('HH:mm').format(date)}',
                    style: TextStyle(color: isFuture ? AppColors.textSecondary : Colors.redAccent)
                ),
                // 📌 Navegación al editor al hacer tap
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      // Pasa el ID del evento y el ID de la banda al editor
                      builder: (context) => EditEventScreen(eventId: eventId, bandId: bandId),
                    ),
                  );
                },
                trailing: isFuture
                    ? const Icon(Icons.edit, color: AppColors.textSecondary)
                    : const Icon(Icons.history, color: AppColors.textSecondary),
              );
            },
          );
        },
      ),
    );
  }
}
