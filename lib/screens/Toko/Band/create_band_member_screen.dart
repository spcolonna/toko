import 'dart:io'; // Necesario para FileImage

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';
// Asegúrate de que estas importaciones sean correctas en tu proyecto
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/SecondaryButton.dart';


class CreateBandMemberScreen extends StatefulWidget {
  final String bandId;
  const CreateBandMemberScreen({super.key, required this.bandId});

  @override
  State<CreateBandMemberScreen> createState() => _CreateBandMemberScreenState();
}

class _CreateBandMemberScreenState extends State<CreateBandMemberScreen> {
  // --- CONTROLADORES ---
  final _nameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _instrumentsController = TextEditingController(); // Campo de texto abierto
  final _bioController = TextEditingController();

  // --- ESTADO ---
  DateTime? _birthDate;
  XFile? _memberImage; // Archivo local de la foto
  String? _selectedBandRole; // Rol primario en la banda (Ej: Vocalista)

  final List<String> _availableBandRoles = ['Vocalista', 'Guitarrista', 'Bajista', 'Baterista', 'Teclista', 'Manager', 'Roadie', 'Otro'];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    _instrumentsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // --- Date Picker ---
  Future<void> _pickBirthDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.textWhite,
              surface: AppColors.backgroundDark,
              onSurface: AppColors.textWhite,
            ),
            dialogBackgroundColor: AppColors.backgroundDark,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _birthDate = pickedDate;
      });
    }
  }

  // --- Photo Picker ---
  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _memberImage = image;
      });
    }
  }

  // --- Lógica de Guardado ---
  Future<void> _addMember() async {
    if (_nameController.text.isEmpty || _selectedBandRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el nombre y el rol principal.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String? photoUrl;
      // 1. Lógica de Subida de Imagen (Firebase Storage)
      if (_memberImage != null) {
        // TODO: IMPLEMENTAR: Subir _memberImage a Storage y obtener photoUrl
        photoUrl = 'placeholder_url_para_${_nameController.text.toLowerCase().replaceAll(' ', '_')}';
      }

      // 2. Creación de Datos
      final newMemberData = {
        'name': _nameController.text.trim(),
        'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
        'birthPlace': _birthPlaceController.text.trim(),
        'instruments': _instrumentsController.text.trim(),
        'artistBio': _bioController.text.trim(),
        'bandRole': _selectedBandRole,
        'photoUrl': photoUrl,
        'isTokoUser': false, // No es un usuario de Toko
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 3. Almacenamiento en la Subcolección 'externalMembers'
      await FirebaseFirestore.instance
          .collection('bands')
          .doc(widget.bandId)
          .collection('externalMembers')
          .add(newMemberData);

      if (mounted) {
        // Vuelve a la pantalla anterior indicando éxito
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      print('Error al agregar miembro externo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el músico: $e')),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Agregar Nuevo Músico (Manual)', style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- FOTO DEL MÚSICO ---
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.secondaryColor,
                  // Muestra la imagen seleccionada o un ícono
                  backgroundImage: _memberImage != null ? FileImage(File(_memberImage!.path)) as ImageProvider<Object>? : null,
                  child: _memberImage == null
                      ? const Icon(Icons.person_add_alt_1, size: 40, color: AppColors.textWhite)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- NOMBRE ---
            CustomInputField(controller: _nameController, labelText: 'Nombre del Músico', icon: Icons.badge_outlined),
            const SizedBox(height: 16),

            // --- ROL PRINCIPAL EN LA BANDA ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Rol Principal en la Banda (Manager, Vocalista, etc.)',
                prefixIcon: Icon(Icons.mic_none, color: AppColors.textSecondary),
              ),
              dropdownColor: AppColors.backgroundDark,
              style: const TextStyle(color: AppColors.textWhite),
              value: _selectedBandRole,
              items: _availableBandRoles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (value) {
                setState(() { _selectedBandRole = value; });
              },
            ),
            const SizedBox(height: 24),

            // --- FECHA DE NACIMIENTO ---
            GestureDetector(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Nacimiento',
                  prefixIcon: Icon(Icons.cake, color: AppColors.textSecondary),
                ),
                child: Text(
                  _birthDate == null
                      ? 'Seleccionar fecha'
                      : DateFormat.yMMMd().format(_birthDate!),
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- LUGAR DE NACIMIENTO ---
            CustomInputField(controller: _birthPlaceController, labelText: 'Lugar de Nacimiento', icon: Icons.place_outlined),
            const SizedBox(height: 16),

            // --- INSTRUMENTOS (Campo Abierto) ---
            CustomInputField(
              controller: _instrumentsController,
              labelText: 'Roles/Instrumentos (Ej: Guitarra principal, Voz, Batería)',
              icon: Icons.music_note_outlined,
              hintText: 'Separar con comas o saltos de línea.',
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // --- BIO DEL ARTISTA ---
            CustomInputField(controller: _bioController, labelText: 'Biografía del Artista', icon: Icons.info_outline, maxLines: 4),
            const SizedBox(height: 32),

            // --- BOTÓN DE GUARDAR ---
            _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)))
                : SecondaryButton(
              text: 'Crear Perfil de Músico',
              onPressed: _addMember,
            ),
          ],
        ),
      ),
    );
  }
}
