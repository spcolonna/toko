import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';
import 'create_event_screen.dart';
import 'dart:developer'; // Importar para usar log()

class BandEventsScreen extends StatelessWidget {
  final String bandId;
  const BandEventsScreen({super.key, required this.bandId});

  @override
  Widget build(BuildContext context) {
    // 1. 🛑 VERIFICACIÓN INICIAL: Si el bandId está vacío, no ejecutes la consulta.
    if (bandId.isEmpty) {
      return const Center(
        child: Text(
            'Error: El ID de la banda es inválido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.redAccent)
        ),
      );
    }

    // Diagnóstico: Imprime el ID que se está consultando
    log('Consultando eventos para Band ID: $bandId');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegación con el bandId correcto
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

      body: StreamBuilder<QuerySnapshot>(
        // 2. ✅ CONSULTA COMPUESTA Y ROBUSTA:
        // Ordena por la fecha del evento y luego por la fecha de creación para consistencia.
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('bandId', isEqualTo: bandId)
            .orderBy('date', descending: true)
            .orderBy('createdAt', descending: true) // Se recomienda para resolver conflictos de tiempo.
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
          }

          // 2. 🛑 MANEJO DEL ERROR DE ÍNDICE (Verificación Clave)
          if (snapshot.hasError) {
            // Imprime el error completo en la consola de depuración (donde aparece la URL)
            // Esto es crucial, ya que el error de índice contiene la URL.
            print('--- FIREBASE INDEX ERROR DIAGNOSTIC ---');
            print('Consulta Fallida en Eventos: ${snapshot.error}');
            print('-----------------------------------------');

            // Muestra un mensaje amigable al usuario con el error
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  '¡Error de configuración de la Base de Datos! Necesitas crear un índice compuesto.\n\nPor favor, revisa la consola de depuración (Debug Console) para copiar el enlace de creación del índice.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            );
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
              final eventData = events[index].data() as Map<String, dynamic>;
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
                trailing: isFuture
                    ? const Icon(Icons.edit, color: AppColors.textSecondary)
                    : const Icon(Icons.history, color: AppColors.textSecondary),
                onTap: () {
                  // Navegar a la pantalla de edición/detalles del evento
                },
              );
            },
          );
        },
      ),
    );
  }
}
