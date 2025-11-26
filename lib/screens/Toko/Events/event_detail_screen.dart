import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  final String currentUserId;

  EventDetailScreen({
    super.key,
    required this.eventId,
    required this.currentUserId,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Lógica de Interacción ---
  Future<void> toggleAttendance(String action) async {
    final eventRef = _firestore.collection('events').doc(eventId);

    final updateData = {
      'attendees': action == 'REMOVE'
          ? FieldValue.arrayRemove([currentUserId])
          : FieldValue.arrayUnion([currentUserId]),
    };

    try {
      await eventRef.update(updateData);
    } catch (e) {
      print('Error al actualizar asistencia en detalles: $e');
    }
  }

  // --- Función para obtener el nombre de la Banda (FutureBuilder) ---
  Future<String> _fetchBandName(String bandId) async {
    if (bandId.isEmpty) return 'Banda Desconocida';
    try {
      final doc = await _firestore.collection('bands').doc(bandId).get();
      return doc.data()?['name'] ?? 'Banda Sin Nombre';
    } catch (e) {
      return 'Error al cargar Banda';
    }
  }

  // --- Función de Edición (Placeholder) ---
  void editEvent(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegando al editor... (Implementar navegación a EditEventScreen)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Detalles del Evento', style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('events').doc(eventId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error al cargar los detalles del evento.', style: TextStyle(color: Colors.redAccent)));
          }

          final eventData = snapshot.data!.data() as Map<String, dynamic>;
          final date = (eventData['date'] as Timestamp).toDate();
          final String eventBandId = eventData['bandId'] ?? '';
          final List<String> attendees = List<String>.from(eventData['attendees'] ?? []);
          final List<dynamic> tickets = eventData['tickets'] ?? [];
          final String ticketLink = eventData['ticketLink'] ?? '';

          final bool isGoing = attendees.contains(currentUserId);
          final int attendeeCount = attendees.length;

          // Lógica para determinar si el usuario actual es el administrador de la banda
          // NOTA: Esta verificación asume que el usuario tiene el managedBandId,
          // lo cual se debe validar con una consulta real para 'isCreator'.
          final bool isCreatorPlaceholder = false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y Banda Creadora
                Text(eventData['title'] ?? 'Evento sin título', style: const TextStyle(color: AppColors.textWhite, fontSize: 28, fontWeight: FontWeight.bold)),

                FutureBuilder<String>(
                  future: _fetchBandName(eventBandId),
                  builder: (context, bandSnapshot) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('Por: ${bandSnapshot.data ?? 'Cargando...'}', style: TextStyle(color: AppColors.textSecondary, fontSize: 18, fontStyle: FontStyle.italic)),
                    );
                  },
                ),

                const SizedBox(height: 15),
                Text(
                  '${DateFormat('EEEE, d MMM yyyy', 'es').format(date)} | ${DateFormat('HH:mm').format(date)}',
                  style: const TextStyle(color: AppColors.primaryColor, fontSize: 18),
                ),
                const Divider(color: AppColors.secondaryColor, height: 30),

                // Lugar y Asistentes
                Row(children: [const Icon(Icons.location_on, color: AppColors.textSecondary), const SizedBox(width: 8), Text(eventData['place'] ?? 'Lugar no especificado', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),]),
                const SizedBox(height: 16),
                Row(children: [const Icon(Icons.people, color: AppColors.textSecondary), const SizedBox(width: 8), Text('$attendeeCount personas van', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),]),
                const SizedBox(height: 30),

                // Precios / Tickets
                const Text('Entradas y Precios', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                if (tickets.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tickets.map((t) {
                      final ticket = t as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '${ticket['name']}: \$${ticket['value'].toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text('Entradas no especificadas.', style: TextStyle(color: AppColors.textSecondary)),

                const SizedBox(height: 20),

                // Enlace de Tickets
                if (ticketLink.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TextButton.icon(
                      onPressed: () {
                        // TODO: Implementar lanzamiento de URL (url_launcher package)
                      },
                      icon: const Icon(Icons.link, color: AppColors.primaryColor),
                      label: Text('Comprar Tickets aquí', style: TextStyle(color: AppColors.primaryColor, fontSize: 16)),
                    ),
                  ),

                // Descripción Completa
                const Text('Descripción del Toque', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(eventData['description'] ?? 'No hay descripción disponible para este evento.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 40),

                // 2. Control de Asistencia (Quiero Asistir / Ya no voy)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => toggleAttendance(isGoing ? 'REMOVE' : 'ADD'),
                    icon: Icon(isGoing ? Icons.cancel : Icons.person_add, color: AppColors.textWhite),
                    label: Text(
                      isGoing ? 'Ya no voy (Retirar Asistencia)' : 'Quiero Asistir',
                      style: const TextStyle(fontSize: 16, color: AppColors.textWhite),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGoing ? Colors.red.shade700 : AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

              ],
            ),
          );
        },
      ),
    );
  }
}
