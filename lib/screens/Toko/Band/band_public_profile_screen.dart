import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:toko/theme/AppColors.dart';

// Definición de la pantalla
class BandPublicProfileScreen extends StatelessWidget {
  final String bandId;

  // ❌ ANTES: const FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ✅ AHORA: SIN 'const'
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ❌ ANTES: const BandPublicProfileScreen({super.key, required this.bandId});
  // ✅ AHORA: SIN 'const' en el constructor
  BandPublicProfileScreen({super.key, required this.bandId}); // <-- EL CAMBIO CLAVE

  // --- LÓGICA DE INTERACCIÓN (Transacción Atómica y Segura) ---
  Future<void> _updateMetric(String bandId, String metricField, bool shouldIncrement) async {
    final bandRef = _firestore.collection('bands').doc(bandId);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await _firestore.runTransaction((transaction) async {
      final bandSnapshot = await transaction.get(bandRef);
      if (!bandSnapshot.exists) {
        throw Exception("Band does not exist!");
      }

      final userRef = _firestore.collection('users').doc(user.uid);
      final userSnapshot = await transaction.get(userRef);

      final listFieldName = metricField == 'followersCount' ? 'followingBands' : 'likedBands';
      final List<String> currentList = List<String>.from(userSnapshot.data()?[listFieldName] ?? []);

      final bool alreadyExists = currentList.contains(bandId);

      if (shouldIncrement == alreadyExists) {
        return;
      }

      final currentCount = bandSnapshot.data()?[metricField] ?? 0;
      final newCount = shouldIncrement ? currentCount + 1 : max(0, currentCount - 1);

      transaction.update(bandRef, {metricField: newCount});

      if (shouldIncrement) {
        transaction.update(userRef, {
          listFieldName: FieldValue.arrayUnion([bandId])
        });
      } else {
        transaction.update(userRef, {
          listFieldName: FieldValue.arrayRemove([bandId])
        });
      }
    });
  }

  void _toggleFollow(String bandId, bool isFollowing) {
    _updateMetric(bandId, 'followersCount', !isFollowing);
  }

  void _toggleLike(String bandId, bool isLiked) {
    _updateMetric(bandId, 'likesCount', !isLiked);
  }
  // ----------------------------------------------


  // --- WIDGET AUXILIAR: Tarjeta de Próximo Evento ---
  Widget _buildEventCard(BuildContext context, Map<String, dynamic> eventData) {
    final Timestamp timestamp = eventData['date'] as Timestamp;
    final DateTime eventDate = timestamp.toDate();

    return Card(
      color: AppColors.secondaryColor.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(DateFormat('MMM').format(eventDate).toUpperCase(), style: const TextStyle(color: AppColors.textWhite, fontSize: 12)),
              Text(DateFormat('dd').format(eventDate), style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        title: Text(eventData['title'] ?? 'Evento sin título', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        subtitle: Text('${eventData['place']} - ${DateFormat('HH:mm').format(eventDate)}', style: TextStyle(color: AppColors.textSecondary)),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          color: AppColors.textSecondary,
          onPressed: () {
            // TODO: Navegar a la vista de detalle del Evento
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Login Required', style: TextStyle(color: AppColors.textWhite)));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Perfil de Banda', style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('bands').doc(bandId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Banda no encontrada.', style: TextStyle(color: AppColors.textWhite)));
          }

          final bandData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final logoUrl = bandData['logoUrl'] as String?;
          final followersCount = bandData['followersCount'] ?? 0;
          final likesCount = bandData['likesCount'] ?? 0;
          final bandName = bandData['name'] ?? 'Banda Desconocida';
          final bandBio = bandData['bio'] ?? 'Biografía no disponible.';
          final bandGenres = List<String>.from(bandData['genres'] ?? []);

          return StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(user.uid).snapshots(),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                final List<String> likedBands = List<String>.from(userData['likedBands'] ?? []);
                final List<String> followingBands = List<String>.from(userData['followingBands'] ?? []);

                final bool isLiked = likedBands.contains(bandId);
                final bool isFollowing = followingBands.contains(bandId);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. HEADER (LOGO Y NOMBRE) ---
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.secondaryColor,
                            backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                            child: logoUrl == null ? const Icon(Icons.mic, size: 30, color: AppColors.textWhite) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bandName, style: const TextStyle(color: AppColors.textWhite, fontSize: 28, fontWeight: FontWeight.bold)),
                                Text(bandData['city'] ?? 'Ciudad Desconocida', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- 2. INTERACCIÓN (ME GUSTA / SEGUIR) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Botón ME GUSTA
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 30),
                                color: isLiked ? AppColors.primaryColor : AppColors.textSecondary,
                                onPressed: () => _toggleLike(bandId, isLiked),
                              ),
                              Text('$likesCount Likes', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            ],
                          ),
                          // Botón SEGUIR
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(isFollowing ? Icons.check_circle : Icons.person_add_alt_1, size: 30),
                                color: isFollowing ? AppColors.primaryColor : AppColors.textSecondary,
                                onPressed: () => _toggleFollow(bandId, isFollowing),
                              ),
                              Text('$followersCount Seguidores', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 40, color: AppColors.secondaryColor),

                      // --- 3. BIOGRAFÍA Y GÉNEROS ---
                      const Text('Acerca de la Banda', style: TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(bandBio, style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        children: bandGenres.map((genre) => Chip(
                          label: Text(genre),
                          backgroundColor: AppColors.secondaryColor,
                          labelStyle: const TextStyle(color: AppColors.textWhite),
                        )).toList(),
                      ),
                      const Divider(height: 40, color: AppColors.secondaryColor),

                      // --- 4. PRÓXIMOS EVENTOS ---
                      const Text('Próximos Toques', style: TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('events')
                            .where('bandId', isEqualTo: bandId)
                            .where('date', isGreaterThanOrEqualTo: Timestamp.now())
                            .orderBy('date', descending: false)
                            .snapshots(),
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
                          }
                          if (!eventSnapshot.hasData || eventSnapshot.data!.docs.isEmpty) {
                            return Text('No hay eventos futuros programados.', style: TextStyle(color: AppColors.textSecondary));
                          }

                          return Column(
                            children: eventSnapshot.data!.docs.map((doc) => _buildEventCard(context, doc.data() as Map<String, dynamic>)).toList(),
                          );
                        },
                      ),
                      const Divider(height: 40, color: AppColors.secondaryColor),

                      // --- 5. INTEGRANTES (Placeholder) ---
                      const Text('Integrantes', style: TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('Integrantes listados aquí: (Total de miembros: ${(bandData['members'] as Map?)?.length ?? 0} Toko + Externos)', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
          );
        },
      ),
    );
  }
}
