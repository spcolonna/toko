// applicant_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/SecondaryButton.dart';
// Asumimos que los imports de tu proyecto son correctos

class ApplicantDetailScreen extends StatefulWidget {
  final String postId;
  final String applicantId;

  const ApplicantDetailScreen({
    super.key,
    required this.postId,
    required this.applicantId,
  });

  @override
  State<ApplicantDetailScreen> createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  String? _selectedStatus;
  final List<String> _statusOptions = ['New', 'Viewed', 'Contacted', 'Rejected'];

  // Función para actualizar el estado del postulante en Firestore
  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('match_posts')
          .doc(widget.postId)
          .collection('applicants')
          .doc(widget.applicantId)
          .update({'status': newStatus});

      setState(() {
        _selectedStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a "$newStatus"')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar estado: $e')),
      );
    }
  }

  // --- Widget para mostrar datos de contacto ---
  Widget _buildContactInfo(String label, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DocumentReference applicantRef = FirebaseFirestore.instance
        .collection('match_posts')
        .doc(widget.postId)
        .collection('applicants')
        .doc(widget.applicantId);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Detalle de Postulación', style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: applicantRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Postulación no encontrada.', style: TextStyle(color: AppColors.textSecondary)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['name'] ?? 'Músico sin nombre';
          final String phone = data['contactPhone'] ?? ''; // 📌 OBTENER TELÉFONO
          final String email = data['contactEmail'] ?? '';
          final String links = data['links'] ?? '';
          final String message = data['message'] ?? 'El músico no dejó un mensaje.';

          if (_selectedStatus == null) {
            _selectedStatus = data['status'] ?? 'New';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CABECERA DE DATOS Y ESTADO ---
                Text(name, style: const TextStyle(color: AppColors.textWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // GESTIÓN DE ESTADO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cambiar Estado:', style: TextStyle(color: AppColors.textWhite, fontSize: 16)),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      dropdownColor: AppColors.secondaryColor,
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
                      items: _statusOptions.map((String status) {
                        return DropdownMenuItem<String>(value: status, child: Text(status));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue != _selectedStatus) {
                          _updateStatus(newValue);
                        }
                      },
                    ),
                  ],
                ),
                const Divider(color: AppColors.textSecondary),

                // --- INFORMACIÓN DE CONTACTO ---
                const Text('Información de Contacto:', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                _buildContactInfo('Email', email, Icons.email),
                _buildContactInfo('Teléfono', phone, Icons.phone), // 📌 MOSTRAR TELÉFONO

                const Divider(color: AppColors.textSecondary),

                // --- MENSAJE / CARTA DE PRESENTACIÓN ---
                const SizedBox(height: 16),
                const Text('Mensaje de Postulación:', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),

                // --- LINKS ---
                const SizedBox(height: 24),
                const Text('Links a Música/Perfiles:', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(links.isEmpty ? 'No proporcionó links.' : links, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),

                // --- BOTÓN DE CONTACTAR ---
                const SizedBox(height: 40),
                SecondaryButton(
                  text: 'Contactar por Email',
                  onPressed: () {
                    // Lógica para abrir la app de correo
                    _updateStatus('Contacted');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Simulación: Abrir cliente de email.')),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
