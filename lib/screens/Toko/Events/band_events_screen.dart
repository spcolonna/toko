import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';
import 'create_event_screen.dart';
import 'edit_event_screen.dart';

// Definición para el tipo de contenido unificado
class ContentItem {
  final String id;
  final String type; // 'event' or 'post'
  final Map<String, dynamic> data;

  ContentItem({required this.id, required this.type, required this.data});
}

class BandEventsScreen extends StatelessWidget {
  final String bandId;
  const BandEventsScreen({super.key, required this.bandId});

  // --- FUNCIÓN CLAVE: CONSULTA Y COMBINACIÓN DE DATOS ---
  Future<List<ContentItem>> _fetchCombinedContent() async {
    final firestore = FirebaseFirestore.instance;
    final currentTime = Timestamp.now();

    // Consulta 1: Eventos (Ordenados por fecha/futuro)
    final eventsSnapshot = await firestore
        .collection('events')
        .where('bandId', isEqualTo: bandId)
        .orderBy('date', descending: true)
        .get();

    // Consulta 2: Posts (Ordenados por fecha de creación)
    final postsSnapshot = await firestore
        .collection('band_posts')
        .where('bandId', isEqualTo: bandId)
        .orderBy('createdAt', descending: true)
        .get();

    final List<ContentItem> combinedList = [];

    // Mapear Eventos
    for (var doc in eventsSnapshot.docs) {
      combinedList.add(ContentItem(id: doc.id, type: 'event', data: doc.data()));
    }

    // Mapear Posts
    for (var doc in postsSnapshot.docs) {
      combinedList.add(ContentItem(id: doc.id, type: 'post', data: doc.data()));
    }

    // Ordenar la lista combinada (Eventos futuros primero, luego Posts, luego Eventos pasados)
    combinedList.sort((a, b) {
      final dateA = (a.data['date'] ?? a.data['createdAt'] ?? Timestamp.now()) as Timestamp;
      final dateB = (b.data['date'] ?? b.data['createdAt'] ?? Timestamp.now()) as Timestamp;

      // Ordena por fecha: Descendente (más nuevo/futuro primero)
      return dateB.compareTo(dateA);
    });

    return combinedList;
  }

  // --- WIDGET 1: TARJETA DE EVENTO (Visualización Clara) ---
  Widget _buildEventCard(BuildContext context, ContentItem item) {
    final eventId = item.id;
    final eventData = item.data;
    final date = (eventData['date'] as Timestamp).toDate();
    final isFuture = date.isAfter(DateTime.now());

    return Card(
      color: AppColors.secondaryColor.withOpacity(0.5), // Color más oscuro
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        tileColor: isFuture ? Colors.transparent : Colors.black.withOpacity(0.2), // Color para eventos pasados
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isFuture ? AppColors.primaryColor : AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(DateFormat('MMM').format(date), style: const TextStyle(color: AppColors.textWhite, fontSize: 9)),
              Text(DateFormat('dd').format(date), style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        title: Text(eventData['title'] ?? 'Evento sin título', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${eventData['place']} | ${DateFormat('HH:mm').format(date)}',
            style: TextStyle(color: isFuture ? AppColors.textSecondary : Colors.redAccent)
        ),
        trailing: Icon(isFuture ? Icons.edit : Icons.history, color: AppColors.textSecondary),
        onTap: () {
          // Navegación a la edición de EVENTO
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditEventScreen(eventId: eventId, bandId: bandId),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET 2: TARJETA DE POST (Visualización Diferenciada) ---
  Widget _buildPostCard(BuildContext context, ContentItem item) {
    final postId = item.id;
    final postData = item.data;
    final createdAt = (postData['createdAt'] as Timestamp).toDate();

    return Card(
      color: AppColors.secondaryColor.withOpacity(0.8), // Color más claro para diferenciar
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          postData['type'] == 'RELEASE' ? Icons.album : Icons.campaign,
          color: AppColors.primaryColor,
        ),
        title: Text(postData['title'] ?? 'Post Sin Título', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${postData['type']} | ${DateFormat('MMM d').format(createdAt)}',
            style: TextStyle(color: AppColors.textSecondary)
        ),
        trailing: const Icon(Icons.edit, color: AppColors.textSecondary),
        onTap: () {
          // TODO: Navegación a la edición de POST (EditBandPostScreen)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navegar a edición de POST (A implementar).')));
        },
      ),
    );
  }

  // --- MOSTRAR OPCIONES DE CREACIÓN (Modal Bottom Sheet) ---
  void _showCreationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('¿Qué contenido deseas crear?', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.primaryColor),
              title: const Text('Crear Nuevo Evento/Toque', style: TextStyle(color: AppColors.textWhite)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateEventScreen(bandId: bandId)));
              },
            ),
            const Divider(color: AppColors.backgroundDark, height: 1),
            ListTile(
              leading: const Icon(Icons.post_add, color: AppColors.primaryColor),
              title: const Text('Crear Nueva Publicación/Noticia', style: TextStyle(color: AppColors.textWhite)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateEventScreen(bandId: bandId)));
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // --- FUNCIÓN BUILD PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,

      // Botón FAB para mostrar el modal de opciones de creación
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreationOptions(context),
        label: const Text('Crear Contenido', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: AppColors.textWhite),
        backgroundColor: AppColors.primaryColor,
      ),

      // AppBar (Mantiene el mismo diseño simple)
      appBar: AppBar(
        title: const Text('Gestión de Contenido', style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),

      // 📜 Listado de contenido combinado
      body: FutureBuilder<List<ContentItem>>(
        future: _fetchCombinedContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
          }
          if (snapshot.hasError) {
            print('Error al cargar contenido combinado: ${snapshot.error}');
            return const Center(child: Text('Error al cargar contenido. Revisa tu consola.', style: TextStyle(color: Colors.red)));
          }

          final combinedContent = snapshot.data ?? [];

          if (combinedContent.isEmpty) {
            return const Center(
              child: Text(
                  'Aún no has creado ningún contenido. ¡Presiona "+" para empezar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 16),
            itemCount: combinedContent.length,
            itemBuilder: (context, index) {
              final item = combinedContent[index];

              if (item.type == 'event') {
                return _buildEventCard(context, item);
              } else if (item.type == 'post') {
                return _buildPostCard(context, item);
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
