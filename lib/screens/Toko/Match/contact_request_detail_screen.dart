import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:intl/intl.dart';

class ContactRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> requestData;

  const ContactRequestDetailScreen({super.key, required this.requestData});

  // Función para abrir el cliente de correo
  void _openEmailClient(BuildContext context, String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abriendo cliente de correo para: $email'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String bandName = requestData['bandId'] ?? 'Banda Desconocida';
    final String managerEmail = requestData['contactEmail'] ?? 'N/A';
    final String managerPhone = requestData['contactPhone'] ?? 'No proporcionado';
    final String message = requestData['message'] ?? 'La banda no dejó un mensaje de interés.';

    // Convertir el Timestamp si existe
    final Timestamp? requestedAtTimestamp = requestData['requestedAt'];
    final String requestedAtString = requestedAtTimestamp != null
        ? DateFormat('MMM d, yyyy HH:mm').format(requestedAtTimestamp.toDate())
        : 'Fecha no registrada';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Solicitud de $bandName', style: const TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y Fecha
            Text(bandName, style: const TextStyle(color: AppColors.textWhite, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('Enviado el $requestedAtString', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const Divider(color: AppColors.secondaryColor, height: 30),

            // Mensaje Detallado
            const Text('Mensaje de la Banda:', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.secondaryColor.withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
              child: Text(message, style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 30),

            // Información de Contacto
            const Text('Datos de Contacto:', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Email
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email, color: AppColors.primaryColor),
              title: const Text('Email', style: TextStyle(color: AppColors.textWhite)),
              subtitle: Text(managerEmail, style: TextStyle(color: AppColors.textSecondary)),
              onTap: managerEmail != 'N/A' ? () => _openEmailClient(context, managerEmail) : null,
            ),

            // Teléfono
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone, color: AppColors.primaryColor),
              title: const Text('Teléfono', style: TextStyle(color: AppColors.textWhite)),
              subtitle: Text(managerPhone, style: TextStyle(color: AppColors.textSecondary)),
              // onTap: managerPhone != 'No proporcionado' ? () => launchUrl(Uri.parse('tel:$managerPhone')) : null,
            ),

            const SizedBox(height: 40),

            // Botón de Respuesta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: managerEmail != 'N/A' ? () => _openEmailClient(context, managerEmail) : null,
                icon: const Icon(Icons.reply, color: AppColors.textWhite),
                label: const Text('Responder por Email', style: TextStyle(color: AppColors.textWhite, fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
