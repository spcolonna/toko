import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/AppColors.dart';

class ScheduleCard extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final String currentUserId;
  final VoidCallback onTap;

  ScheduleCard({
    super.key,
    required this.eventId,
    required this.eventData,
    required this.currentUserId,
    required this.onTap,
  });

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    final place = eventData['place'] ?? 'Lugar no especificado';
    final title = eventData['title'] ?? 'Evento sin título';

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchBandDetails(),
      builder: (context, snapshot) {
        final bandName = snapshot.data?['name'] ?? 'Cargando Banda...';
        final logoUrl = snapshot.data?['logoUrl'];

        return GestureDetector(
          onTap: onTap,
          child: Card(
            color: AppColors.backgroundDark, // Fondo más oscuro para destacar el borde
            margin: const EdgeInsets.only(bottom: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primaryColor, width: 2), // Borde Primario
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // --- 1. FECHA (Columna destacada) ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryColor, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('MMM').format(date).toUpperCase(), style: const TextStyle(color: AppColors.textWhite, fontSize: 10)),
                        Text(DateFormat('dd').format(date), style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // --- 2. DETALLES (Banda y Título) ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre de la Banda (Prioridad alta)
                        Text(bandName, style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        // Título del Evento
                        Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 8),
                        // Lugar y Hora
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.textSecondary, size: 14),
                            const SizedBox(width: 4),
                            Text(place, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            const SizedBox(width: 10),
                            Text(DateFormat('HH:mm').format(date), style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- 3. LOGO DE BANDA (Trailing) ---
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.secondaryColor,
                    backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
                    child: logoUrl == null ? const Icon(Icons.mic, color: AppColors.textWhite, size: 20) : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
