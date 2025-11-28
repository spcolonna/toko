import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/SecondaryButton.dart';

class MusicianDataTab extends StatefulWidget {
  final String userId;
  const MusicianDataTab({super.key, required this.userId});

  @override
  State<MusicianDataTab> createState() => _MusicianDataTabState();
}

class _MusicianDataTabState extends State<MusicianDataTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linksController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _birthDate;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _linksController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // --- Lógica de Carga de Datos ---
  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final data = userDoc.data();

      if (data != null && mounted) {
        _nameController.text = data['displayName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _linksController.text = data['musicianLinks'] ?? '';
        _bioController.text = data['musicianBio'] ?? '';

        final Timestamp? birthTimestamp = data['birthDate'];
        _birthDate = birthTimestamp?.toDate();

        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        print('Error loading musician data: $e');
        setState(() { _isLoading = false; });
      }
    }
  }

  // --- Lógica de Guardado (Actualiza el documento 'users') ---
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; });

    try {
      final updateData = {
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'musicianLinks': _linksController.text.trim(),
        'musicianBio': _bioController.text.trim(),
        'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
      };

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado exitosamente!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) { setState(() { _isSaving = false; }); }
    }
  }

  // --- Date Picker (Corregido a Future<void>) ---
  Future<void> _pickBirthDate() async {
    final DateTime? pickedDate = await showDatePicker(
        context: context, initialDate: _birthDate ?? DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
    if (pickedDate != null) {
      setState(() { _birthDate = pickedDate; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
    }

    final InputBorder customBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo 1: Nombre (displayName)
            CustomInputField(controller: _nameController, labelText: 'Tu Nombre', icon: Icons.person, validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 16),

            // Campo 2: Teléfono
            CustomInputField(controller: _phoneController, labelText: 'Número de Teléfono', icon: Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),

            // Campo 3: Fecha de Nacimiento
            GestureDetector(
              // 📌 CORRECCIÓN: Envolver la llamada asíncrona en un lambda síncrono.
              onTap: () async { await _pickBirthDate(); },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de Nacimiento', labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.cake, color: AppColors.primaryColor),
                  border: customBorder, enabledBorder: customBorder, focusedBorder: customBorder.copyWith(borderSide: const BorderSide(color: AppColors.primaryColor, width: 2)),
                ),
                child: Text(
                  _birthDate == null ? 'Seleccionar fecha' : DateFormat.yMMMd().format(_birthDate!),
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Campo 4: Links de Música/Social
            CustomInputField(controller: _linksController, labelText: 'Links de Música (Spotify, YT)', icon: Icons.link),
            const SizedBox(height: 16),

            // Campo 5: Bio (Currículum Musical)
            CustomInputField(controller: _bioController, labelText: 'Biografía / Experiencia Musical', icon: Icons.mic_none, maxLines: 5),
            const SizedBox(height: 32),

            // Botón de Guardar
            SecondaryButton(
              // 📌 CORRECCIÓN: Pasar el flag isLoading y el texto fijo
              text: 'Guardar Perfil de Músico',
              onPressed: _isSaving ? null : _saveProfile,
              isLoading: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}
