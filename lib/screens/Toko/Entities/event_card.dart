import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/AppColors.dart';

class EventCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final String currentUserId;
  final VoidCallback? onTap;

  EventCard({
    super.key,
    required this.eventId,
    required this.eventData,
    required this.currentUserId,
    this.onTap,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lógica para manejar la asistencia (se mantiene igual)
  Future<void> toggleAttendance() async {
    final eventRef = _firestore.collection('events').doc(eventId);
    final List<String> attendees = List<String>.from(eventData['attendees'] ?? []);
    final isGoing = attendees.contains(currentUserId);
    final updateData = {
      'attendees': isGoing
          ? FieldValue.arrayRemove([currentUserId])
          : FieldValue.arrayUnion([currentUserId])
    };
    try { await eventRef.update(updateData); } catch (e) { print('Error al actualizar asistencia: $e'); }
  }

  // --- FUNCIÓN CLAVE: Obtener Logo y Nombre de la Banda ---
  Future<Map<String, dynamic>> _fetchBandDetails() async {
    final bandId = eventData['bandId'] as String? ?? '';
    if (bandId.isEmpty) return {'name': 'Banda Desconocida', 'logoUrl': null};

    final bandDoc = await _firestore.collection('bands').doc(bandId).get();
    final bandData = bandDoc.data();

    return {
      'name': bandData?['name'] ?? 'Banda Desconocida',
      'logoUrl': bandData?['logoUrl'],
    };
  }

  @override
  Widget build(BuildContext context) {
    final date = (eventData['date'] as Timestamp).toDate();
    final List<String> attendees = List<String>.from(eventData['attendees'] ?? []);
    final bool isGoing = attendees.contains(currentUserId);
    final int attendeeCount = attendees.length;

    return FutureBuilder<Map<String, dynamic>>(
        future: _fetchBandDetails(),
        builder: (context, snapshot) {
          final bandName = snapshot.data?['name'] ?? 'Cargando Banda...';
          final logoUrl = snapshot.data?['logoUrl'];

          return GestureDetector(
            onTap: onTap, // Navega al EventDetailScreen
            child: Card(
              color: AppColors.secondaryColor.withOpacity(0.3),
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. HEADER: LOGO y NOMBRE (Lo más importante) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo y Nombre (Prioridad alta)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryColor,
                              backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
                              child: logoUrl == null ? const Icon(Icons.mic, color: AppColors.textWhite, size: 20) : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              bandName,
                              style: const TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        // Icono de Me Gusta (Interacción secundaria)
                        IconButton(
                          icon: Icon(isGoing ? Icons.event_available : Icons.event_outlined),
                          color: isGoing ? AppColors.primaryColor : AppColors.textSecondary,
                          onPressed: toggleAttendance,
                          tooltip: isGoing ? 'Ya estás en la lista' : 'Marcar asistencia',
                        ),
                      ],
                    ),

                    const Divider(color: AppColors.secondaryColor, height: 24),

                    // --- 2. CUERPO: FECHA y LUGAR ---
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('EEE, d MMM', 'es').format(date)} | ${DateFormat('HH:mm').format(date)}',
                          style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // --- 3. ASISTENCIA (Más pequeño) ---
                    Row(
                      children: [
                        const Icon(Icons.people, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 4),
                        Text(
                            '$attendeeCount van',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)
                        ),

                        const Spacer(),

                        // Tipo de Evento / Ciudad
                        Text(
                            eventData['place'] ?? 'Lugar no especificado',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}
