import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:toko/theme/AppColors.dart';
import 'Entities/event_card.dart';
import 'Entities/feed_item.dart';
import 'Events/event_detail_screen.dart';


class EventScreen extends StatelessWidget {
  EventScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- FUNCIÓN CLAVE: CONSULTA Y COMBINACIÓN DE DATOS (Se mantiene) ---
  Future<List<FeedItem>> _fetchCombinedFeed() async {
    final currentTime = Timestamp.now();

    final eventsSnapshot = await _firestore
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: currentTime)
        .orderBy('date', descending: false)
        .get();

    final postsSnapshot = await _firestore
        .collection('band_posts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final List<FeedItem> combinedList = [];

    for (var doc in eventsSnapshot.docs) {
      combinedList.add(FeedItem(
          id: doc.id,
          type: 'event',
          data: doc.data(),
          sortDate: doc.data()['date'] as Timestamp
      ));
    }

    for (var doc in postsSnapshot.docs) {
      combinedList.add(FeedItem(
          id: doc.id,
          type: 'post',
          data: doc.data(),
          sortDate: doc.data()['createdAt'] as Timestamp
      ));
    }

    combinedList.sort((a, b) => b.sortDate.compareTo(a.sortDate));

    return combinedList;
  }

  // --- LÓGICA DE INTERACCIÓN: Me Gusta en Posts (Se mantiene) ---
  Future<void> _togglePostLike(String postId, bool isLiked) async {
    final postRef = _firestore.collection('band_posts').doc(postId);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      if (!postSnapshot.exists) return;

      final userRef = _firestore.collection('users').doc(user.uid);

      // No necesitamos leer userSnapshot aquí si confiamos en el stream que lo hace
      // final userSnapshot = await transaction.get(userRef);
      // ... la transacción ya está validada, solo la ejecutamos

      final currentCount = postSnapshot.data()?['likesCount'] ?? 0;
      final shouldIncrement = !isLiked;

      // Determinamos el nuevo conteo
      final newCount = shouldIncrement ? currentCount + 1 : max(0, currentCount - 1);

      // 1. Actualizar el Contador del Post
      transaction.update(postRef, {'likesCount': newCount});

      // 2. Actualizar la Lista del Usuario (esto dispara el StreamBuilder del usuario)
      if (shouldIncrement) {
        transaction.update(userRef, {'likedPosts': FieldValue.arrayUnion([postId])});
      } else {
        transaction.update(userRef, {'likedPosts': FieldValue.arrayRemove([postId])});
      }
    });
  }

  // --- WIDGET AUXILIAR: TARJETA DE PUBLICACIÓN (CORREGIDA CON STREAMS) ---
  Widget _buildPostCard(BuildContext context, FeedItem item, String currentUserId) {
    final String bandId = item.data['bandId'] ?? '';
    final String postTitle = item.data['title'] ?? 'Nueva Publicación';
    final String postBody = item.data['body'] ?? item.data['description'] ?? 'Sin descripción.';
    final DateTime createdAt = (item.data['createdAt'] as Timestamp).toDate();
    final String postType = item.data['type'] ?? 'Noticia';
    final IconData typeIcon = postType == 'RELEASE' ? Icons.album : Icons.campaign;

    // 1. FutureBuilder para el nombre de la banda (dato estático, se carga una vez)
    return FutureBuilder<String>(
      future: _fetchBandName(bandId),
      builder: (context, bandNameSnapshot) {
        final bandName = bandNameSnapshot.data ?? 'Cargando Banda...';

        // 2. StreamBuilder para el documento del Post (obtiene likesCount en tiempo real)
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('band_posts').doc(item.id).snapshots(),
          builder: (context, postSnapshot) {

            // Usamos el dato actual del Stream si está disponible, si no, el dato inicial
            final postData = postSnapshot.data?.data() as Map<String, dynamic>? ?? item.data;
            final int likesCount = postData['likesCount'] ?? 0;

            // 3. StreamBuilder para el documento del Usuario (obtiene el estado 'isLiked' en tiempo real)
            return StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(currentUserId).snapshots(),
              builder: (context, userSnapshot) {

                final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                final List<String> likedPosts = List<String>.from(userData['likedPosts'] ?? []);
                final bool isLiked = likedPosts.contains(item.id);

                // Si aún estamos cargando datos, mostramos un indicador
                if (bandNameSnapshot.connectionState == ConnectionState.waiting || postSnapshot.connectionState == ConnectionState.waiting || userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor))));
                }

                // --- Construcción de la Tarjeta ---
                return Card(
                  color: AppColors.secondaryColor.withOpacity(0.8),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- HEADER ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(typeIcon, color: AppColors.primaryColor),
                                const SizedBox(width: 8),
                                Text(bandName, style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Text('($postType)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                            Text(DateFormat('MMM d').format(createdAt), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),

                        const Divider(color: AppColors.secondaryColor, height: 24),

                        // --- TÍTULO Y CUERPO ---
                        Text(postTitle, style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(postBody, style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 16),

                        // --- ACCIÓN: LIKE Y LINK ---
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 24),
                              color: isLiked ? AppColors.primaryColor : AppColors.textSecondary,
                              // El onPressed ejecuta la transacción, que dispara los StreamBuilders
                              onPressed: () => _togglePostLike(item.id, isLiked),
                            ),
                            Text('$likesCount Me Gusta', style: TextStyle(color: AppColors.textSecondary)),

                            const Spacer(),

                            // Botón de Enlace (si existe)
                            if (postData['linkUrl'] != null && postData['linkUrl'].isNotEmpty)
                              TextButton.icon(
                                onPressed: () { /* TODO: Abrir URL */ },
                                icon: const Icon(Icons.link, size: 18, color: AppColors.primaryColor),
                                label: const Text('Escuchar/Ver', style: TextStyle(color: AppColors.primaryColor)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Función para obtener el nombre de la banda (se mantiene)
  Future<String> _fetchBandName(String bandId) async {
    if (bandId.isEmpty) return 'Banda Desconocida';
    try {
      final doc = await _firestore.collection('bands').doc(bandId).get();
      return doc.data()?['name'] ?? 'Banda Sin Nombre';
    } catch (e) {
      return 'Error al cargar Banda';
    }
  }


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

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            title: const Text('Feed de Toko', style: TextStyle(color: AppColors.textWhite)),
            backgroundColor: AppColors.backgroundDark,
          ),
          body: FutureBuilder<List<FeedItem>>(
            future: _fetchCombinedFeed(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
              }

              if (snapshot.hasError) {
                print('Error al cargar feed combinado: ${snapshot.error}');
                return Center(child: Text('Error al cargar feed: La consulta de band_posts requiere un índice. Revisa el log.', style: const TextStyle(color: Colors.redAccent)));
              }

              final feedItems = snapshot.data ?? [];

              if (feedItems.isEmpty) {
                return const Center(child: Text('No hay contenido programado.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: feedItems.length,
                itemBuilder: (context, index) {
                  final item = feedItems[index];

                  // 1. DISTINCIÓN VISUAL Y LÓGICA
                  if (item.type == 'event') {
                    // Tarjeta de EVENTO
                    return EventCard(
                      eventId: item.id,
                      eventData: item.data,
                      currentUserId: currentUserId,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EventDetailScreen(eventId: item.id, currentUserId: currentUserId),
                          ),
                        );
                      },
                    );
                  } else if (item.type == 'post') {
                    // Tarjeta de PUBLICACIÓN (Ahora usa Streams para ser real-time)
                    return _buildPostCard(context, item, currentUserId);
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),
        );
      },
    );
  }
}
