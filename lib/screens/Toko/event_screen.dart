import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toko/theme/AppColors.dart';

import 'Entities/event_card.dart';
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
