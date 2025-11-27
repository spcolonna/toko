import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toko/theme/AppColors.dart';

import 'Entities/schedule_card.dart';
import 'Events/event_detail_screen.dart';

class MyScheduleScreen extends StatelessWidget {
  const MyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    if (user == null) {
      return const Center(child: Text('Debes iniciar sesión para ver tu agenda.', style: TextStyle(color: AppColors.textSecondary)));
    }

    final String currentUserId = user.uid;

    final Stream<QuerySnapshot> rsvpStream = _firestore
        .collection('events')
        .where('attendees', arrayContains: currentUserId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('date', descending: false)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Mi Agenda (Asistencias)', style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: rsvpStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
            }

            if (snapshot.hasError) {
              print('--- FIREBASE INDEX ERROR DIAGNOSTIC ---');
              print('Consulta Fallida en MyScheduleScreen: ${snapshot.error}');
              print('-----------------------------------------');
              return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('🚨 ¡Error de configuración de la BD! Revisa la consola (Debug Console) para copiar el enlace de creación del índice.', textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontSize: 16)),),);
            }

            final events = snapshot.data?.docs ?? [];

            if (events.isEmpty) {
              return const Center(child: Text('Aún no tienes asistencias confirmadas a eventos futuros. ¡Sal y apoya!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final eventDoc = events[index];
                final eventId = eventDoc.id;
                final eventData = eventDoc.data() as Map<String, dynamic>;

                final String currentUserId = user.uid; // Asegurar que el UID esté disponible

                return ScheduleCard(
                  eventId: eventId,
                  eventData: eventData,
                  currentUserId: currentUserId,
                  onTap: () {
                    // 📌 NAVEGACIÓN IMPLEMENTADA (Se mantiene la funcionalidad)
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
      ),
    );
  }
}
