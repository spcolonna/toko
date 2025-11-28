import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/SecondaryButton.dart';

class ContactRequestFormScreen extends StatefulWidget {
  final String postId; // El ID del post que el músico creó
  final String musicianUid; // El UID del músico que recibe la solicitud

  const ContactRequestFormScreen({
    super.key,
    required this.postId,
    required this.musicianUid,
  });

  @override
  State<ContactRequestFormScreen> createState() => _ContactRequestFormScreenState();
}

class _ContactRequestFormScreenState extends State<ContactRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _bandEmailController = TextEditingController();
  final _bandPhoneController = TextEditingController(); // Teléfono opcional

  bool _isLoading = false;
  String _bandId = ''; // ID de la banda que solicita (necesario para el registro)

  @override
  void initState() {
    super.initState();
    // 📌 NOTA: En un caso real, aquí deberías buscar el 'bandId' del manager actual
    // que está solicitando el contacto, usando FirebaseAuth.instance.currentUser!.uid
    _bandId = 'bandId_del_manager_actual';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _bandEmailController.dispose();
    _bandPhoneController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE ENVÍO DE SOLICITUD ---
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bandEmailController.text.isEmpty) {
      _showSnackBar('El Email es obligatorio para contactar.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final requestData = {
        'bandId': _bandId,
        'managerUid': FirebaseAuth.instance.currentUser!.uid,
        'message': _messageController.text.trim(),
        'contactEmail': _bandEmailController.text.trim(),
        'contactPhone': _bandPhoneController.text.trim(), // Opcional
        'status': 'Pending',
        'requestedAt': FieldValue.serverTimestamp(),
      };

      // 1. Guardar la solicitud en una subcolección del PERFIL del músico (users/{uid}/contactRequests)
      //    Esto permite al músico ver directamente las ofertas.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.musicianUid) // El UID del músico que hizo el post
          .collection('contactRequests')
          .add(requestData);

      // 2. Opcional: Marcar el Match Post como 'Solicitado'
      // await FirebaseFirestore.instance.collection('match_posts').doc(widget.postId).update({ 'lastContacted': FieldValue.serverTimestamp() });

      if (mounted) {
        _showSnackBar('Solicitud de contacto enviada a ${widget.musicianUid} con éxito!');
        Navigator.of(context).pop();
      }

    } catch (e) {
      _showSnackBar('Error al enviar la solicitud: $e');
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  }


  @override
  Widget build(BuildContext context) {
    final title = 'Solicitar Contacto a Músico';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Proporciona tus datos de contacto para que el músico pueda responder a tu interés.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 20),

              // CAMPO 1: EMAIL DE CONTACTO (Obligatorio)
              CustomInputField(
                controller: _bandEmailController,
                labelText: 'Email de Contacto de tu Banda',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.isEmpty) ? 'El email es obligatorio.' : null,
              ),
              const SizedBox(height: 16),

              // CAMPO 2: TELÉFONO DE CONTACTO (Opcional)
              CustomInputField(
                controller: _bandPhoneController,
                labelText: 'Teléfono de Contacto (Opcional)',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => null,
              ),
              const SizedBox(height: 16),

              // CAMPO 3: MENSAJE / INTERÉS
              CustomInputField(
                controller: _messageController,
                labelText: 'Mensaje de Interés',
                icon: Icons.message,
                maxLines: 5,
              ),
              const SizedBox(height: 32),

              // BOTÓN DE ENVÍO
              SecondaryButton(
                text: 'Enviar Solicitud de Contacto',
                onPressed: _submitRequest,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
