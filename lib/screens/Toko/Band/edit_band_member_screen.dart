import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/SecondaryButton.dart';

class EditBandMemberScreen extends StatefulWidget {
  final String bandId;
  final String memberId;
  final Map<String, dynamic> memberData;
  final bool isExternalMember;

  const EditBandMemberScreen({
    super.key,
    required this.bandId,
    required this.memberId,
    required this.memberData,
    required this.isExternalMember,
  });

  @override
  State<EditBandMemberScreen> createState() => _EditBandMemberScreenState();
}

class _EditBandMemberScreenState extends State<EditBandMemberScreen> {
  // --- CONTROLADORES ---
  final _nameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _instrumentsController = TextEditingController();
  final _bioController = TextEditingController();

  // --- ESTADO ---
  DateTime? _birthDate;
  XFile? _memberImage;
  String? _selectedBandRole;

  final List<String> _availableBandRoles = ['Vocalista', 'Guitarrista', 'Bajista', 'Baterista', 'Teclista', 'Manager', 'Roadie', 'Otro'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData(widget.memberData);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    _instrumentsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // --- CARGA INICIAL DE DATOS ---
  void _loadInitialData(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _birthPlaceController.text = data['birthPlace'] ?? '';
    _instrumentsController.text = data['instruments'] ?? '';
    _bioController.text = data['artistBio'] ?? '';
    _selectedBandRole = data['bandRole'];

    // Convertir Timestamp a DateTime
    final Timestamp? birthTimestamp = data['birthDate'];
    _birthDate = birthTimestamp?.toDate();
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
              primary: AppColors.primaryColor, onPrimary: AppColors.textWhite, surface: AppColors.backgroundDark, onSurface: AppColors.textWhite,
            ),
            dialogBackgroundColor: AppColors.backgroundDark,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() { _birthDate = pickedDate; });
    }
  }

  // --- Photo Picker (Lógica de edición: permite reemplazar la foto) ---
  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() { _memberImage = image; });
    }
  }

  // --- Lógica de Actualización ---
  Future<void> _updateMember() async {
    if (_nameController.text.isEmpty || _selectedBandRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el nombre y el rol principal.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String? photoUrl = widget.memberData['photoUrl']; // Mantener URL existente

      // 1. Lógica de Subida de Imagen (Si se seleccionó una nueva, reemplazar la URL)
      if (_memberImage != null) {
        // TODO: IMPLEMENTAR: Subir _memberImage a Storage y obtener photoUrl (photoUrl = newUrl)
        photoUrl = 'placeholder_url_edited_${_nameController.text}';
      }

      // 2. Creación de Datos de Actualización
      final updatedData = {
        'name': _nameController.text.trim(),
        'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
        'birthPlace': _birthPlaceController.text.trim(),
        'instruments': _instrumentsController.text.trim(),
        'artistBio': _bioController.text.trim(),
        'bandRole': _selectedBandRole,
        'photoUrl': photoUrl,
        // No actualizamos isTokoUser ni createdAt
      };

      // 3. ACTUALIZAR EN FIRESTORE
      if (widget.isExternalMember) {
        // Miembro externo (Subcolección)
        await FirebaseFirestore.instance
            .collection('bands')
            .doc(widget.bandId)
            .collection('externalMembers')
            .doc(widget.memberId)
            .update(updatedData);
      } else {
        // Miembro Toko (Requiere actualizar solo el rol en el mapa principal, otros datos personales van en la colección 'users')
        // Por ahora, solo actualizaremos el rol, asumiendo que el resto de datos personales (bio, fecha) vienen de la colección 'users'.
        await FirebaseFirestore.instance.collection('bands').doc(widget.bandId).update({
          'members.${widget.memberId}.role': _selectedBandRole,
          // Si se permiten editar datos personales Toko, deben actualizar la colección 'users'.
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Vuelve con señal de éxito
      }

    } catch (e) {
      print('Error al editar miembro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si es un Toko User, solo permitimos editar el rol en la banda (bandRole).
    final isTokoUser = !widget.isExternalMember;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(isTokoUser ? 'Editar Rol' : 'Editar Músico', style: const TextStyle(color: AppColors.textWhite)),
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
            if (!isTokoUser)
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.secondaryColor,
                    // Muestra la nueva imagen o la URL existente
                    backgroundImage: _memberImage != null
                        ? FileImage(File(_memberImage!.path)) as ImageProvider<Object>?
                        : (widget.memberData['photoUrl'] != null ? NetworkImage(widget.memberData['photoUrl']!) : null),
                    child: (_memberImage == null && widget.memberData['photoUrl'] == null)
                        ? const Icon(Icons.person, size: 40, color: AppColors.textWhite)
                        : null,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // --- ROL PRINCIPAL EN LA BANDA (Editable para ambos) ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Rol Principal en la Banda',
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

            // Campos Personales (Solo para miembros externos)
            if (!isTokoUser) ...[
              CustomInputField(controller: _nameController, labelText: 'Nombre del Músico', icon: Icons.badge_outlined),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fecha de Nacimiento', prefixIcon: Icon(Icons.cake, color: AppColors.textSecondary)),
                  child: Text(
                    _birthDate == null ? 'Seleccionar fecha' : DateFormat.yMMMd().format(_birthDate!),
                    style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomInputField(controller: _birthPlaceController, labelText: 'Lugar de Nacimiento', icon: Icons.place_outlined),
              const SizedBox(height: 16),
              CustomInputField(controller: _instrumentsController, labelText: 'Roles/Instrumentos', icon: Icons.music_note_outlined, maxLines: 2),
              const SizedBox(height: 16),
              CustomInputField(controller: _bioController, labelText: 'Biografía del Artista', icon: Icons.info_outline, maxLines: 4),
              const SizedBox(height: 32),
            ],

            // --- BOTÓN DE GUARDAR ---
            _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)))
                : SecondaryButton(
              text: isTokoUser ? 'Actualizar Rol' : 'Guardar Perfil Editado',
              onPressed: _updateMember,
            ),
          ],
        ),
      ),
    );
  }
}
