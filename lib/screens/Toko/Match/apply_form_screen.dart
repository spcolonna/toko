import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/SecondaryButton.dart';

class ApplyFormScreen extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String bandName;

  const ApplyFormScreen({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.bandName,
  });

  @override
  State<ApplyFormScreen> createState() => _ApplyFormScreenState();
}

class _ApplyFormScreenState extends State<ApplyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _linksController = TextEditingController();
  final _messageController = TextEditingController();
  final _phoneController = TextEditingController(); // 📌 NUEVO CONTROLADOR

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _linksController.dispose();
    _messageController.dispose();
    _phoneController.dispose(); // 📌 DISPOSE
    super.dispose();
  }

  // --- LÓGICA DE POSTULACIÓN ---
  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      final applicationData = {
        'musicianUid': widget.currentUserId,
        'name': _nameController.text.trim(),
        'contactEmail': _emailController.text.trim(),
        'links': _linksController.text.trim(),
        'message': _messageController.text.trim(),
        'contactPhone': _phoneController.text.trim(), // 📌 CAMPO GUARDADO
        'status': 'New',
        'appliedAt': FieldValue.serverTimestamp(),
      };

      // 1. Guardar la postulación en la subcolección 'applicants'
      await FirebaseFirestore.instance
          .collection('match_posts')
          .doc(widget.postId)
          .collection('applicants')
          .add(applicationData);

      // 2. Opcional: Actualizar el contador de postulaciones en el post principal
      await FirebaseFirestore.instance.collection('match_posts').doc(widget.postId).update({
        'applicantsCount': FieldValue.increment(1),
        'applicantsUids': FieldValue.arrayUnion([widget.currentUserId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Postulación a ${widget.bandName} enviada con éxito!')));
        Navigator.of(context).pop();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al postularse: $e')));
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Postularme a ${widget.bandName}', style: const TextStyle(color: AppColors.textWhite)),
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
              // NOMBRE COMPLETO
              CustomInputField(controller: _nameController, labelText: 'Tu Nombre Completo', icon: Icons.person, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),

              // EMAIL DE CONTACTO (Obligatorio)
              CustomInputField(controller: _emailController, labelText: 'Email de Contacto', icon: Icons.email, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),

              // NÚMERO DE TELÉFONO (Opcional)
              CustomInputField(
                controller: _phoneController,
                labelText: 'Número de Teléfono (Opcional)',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => null, // 📌 ES OPCIONAL, no requiere validación de nulidad
              ),
              const SizedBox(height: 16),

              // LINKS
              CustomInputField(controller: _linksController, labelText: 'Links a tu Música/Perfil', icon: Icons.link, validator: (v) => null,),
              const SizedBox(height: 16),

              // CARTA DE PRESENTACIÓN (Obligatorio)
              CustomInputField(controller: _messageController, labelText: 'Mensaje a la Banda', icon: Icons.message, maxLines: 5, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 32),

              // BOTÓN DE ENVÍO
              _isLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)))
                  : SecondaryButton(text: 'Enviar Postulación', onPressed: _submitApplication),
            ],
          ),
        ),
      ),
    );
  }
}
