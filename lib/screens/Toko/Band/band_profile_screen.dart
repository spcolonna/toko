import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/SecondaryButton.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'create_band_member_screen.dart'; // Asegúrate de que esta clase exista
import 'edit_band_member_screen.dart'; // Asegúrate de que esta clase exista

class BandProfileScreen extends StatefulWidget {
  final String bandId;
  const BandProfileScreen({super.key, required this.bandId});

  @override
  State<BandProfileScreen> createState() => _BandProfileScreenState();
}

class _BandProfileScreenState extends State<BandProfileScreen> {
  // --- 1. CONTROLADORES Y ESTADO ---
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _socialsController = TextEditingController();
  final _newMemberEmailController = TextEditingController();
  final _phoneController = TextEditingController(); // ✅ CONTROLADOR: TELÉFONO

  DateTime? _dateFounded;
  Set<String> _selectedGenres = {};
  bool _isDataLoaded = false;

  final List<String> _availableGenres = ['Rock', 'Pop', 'Indie', 'Metal', 'Cumbia', 'Jazz', 'Electrónica'];
  final List<String> _availableRoles = ['Vocalist', 'Guitarist', 'Bassist', 'Drummer', 'Keyboardist', 'Manager'];

  @override
  void dispose() {
    _nameController.dispose(); _cityController.dispose(); _bioController.dispose();
    _emailController.dispose(); _socialsController.dispose(); _newMemberEmailController.dispose();
    _phoneController.dispose(); // ✅ DISPOSE: TELÉFONO
    super.dispose();
  }

  // --- 2. LÓGICA DE CARGA DE DATOS ---
  void _loadInitialData(Map<String, dynamic> bandData) {
    if (_isDataLoaded) return;
    _nameController.text = bandData['name'] ?? '';
    _cityController.text = bandData['city'] ?? '';
    _bioController.text = bandData['bio'] ?? '';
    _emailController.text = bandData['contactEmail'] ?? '';
    _socialsController.text = bandData['socialLinks'] ?? '';
    _phoneController.text = bandData['contactPhone'] ?? ''; // ✅ CARGA INICIAL: TELÉFONO

    final Timestamp? foundedTimestamp = bandData['dateFounded'];
    _dateFounded = foundedTimestamp?.toDate();

    final List<String> genres = List<String>.from(bandData['genres'] ?? []);
    _selectedGenres = genres.toSet();

    _isDataLoaded = true;
  }

  // --- 3. MÉTODOS AUXILIARES (Funciones de navegación, pickers, etc.) ---
  Future<void> _pickDateFounded() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context, initialDate: _dateFounded ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryColor, onPrimary: AppColors.textWhite, surface: AppColors.backgroundDark, onSurface: AppColors.textWhite,),
          dialogBackgroundColor: AppColors.backgroundDark,), child: child!,);},);
    if (pickedDate != null) {
      setState(() {
        _dateFounded = pickedDate;
        _isDataLoaded = false;
      });
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lógica de subida de logo a Storage pendiente.')));
      }
    }
  }

  Future<void> _navigateToAddMemberScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CreateBandMemberScreen(bandId: widget.bandId)),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nuevo miembro agregado a la banda.')));
    }
  }

  Future<void> _removeMember(String id, bool isExternalMember) async {
    if (!mounted) return;
    try {
      if (isExternalMember) {
        await FirebaseFirestore.instance.collection('bands').doc(widget.bandId).collection('externalMembers').doc(id).delete();
      } else {
        await FirebaseFirestore.instance.collection('bands').doc(widget.bandId).update({
          'members.${id}': FieldValue.delete(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Miembro ${isExternalMember ? "manual" : "Toko"} eliminado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String name) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundDark,
          title: const Text("Confirmar Eliminación", style: TextStyle(color: AppColors.primaryColor)),
          content: Text("¿Estás seguro de que quieres eliminar a $name de la banda? Esta acción es irreversible.", style: const TextStyle(color: AppColors.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold))),
          ],
        );
      },
    ) ?? false;
  }

  // --- 4. LÓGICA DE GUARDADO ---
  Future<void> _saveProfile() async {
    if (!mounted) return;
    try {
      final updatedData = {
        'name': _nameController.text.trim(), 'city': _cityController.text.trim(), 'bio': _bioController.text.trim(),
        'contactEmail': _emailController.text.trim(),
        'contactPhone': _phoneController.text.trim(), // ✅ GUARDAR: TELÉFONO
        'socialLinks': _socialsController.text.trim(),
        'dateFounded': _dateFounded != null ? Timestamp.fromDate(_dateFounded!) : null,
        'genres': _selectedGenres.toList(),
      };
      await FirebaseFirestore.instance.collection('bands').doc(widget.bandId).update(updatedData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado exitosamente!')),);
      }
    } catch (e) {
      print('Error al guardar el perfil en Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar: Asegure reglas de seguridad (write).')),);
      }
    }
  }

  // --- 5. WIDGET DE GESTIÓN DE MIEMBROS (Subdivisión de UI) ---
  Widget _buildMembersManagement(Map<String, dynamic> bandData) {
    final tokouserMembers = bandData['members'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Integrantes de la Banda', style: TextStyle(color: AppColors.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(color: AppColors.secondaryColor),

          Material(
            color: Colors.transparent,
            child: Column(
              children: [
                // --- Lista de Miembros Toko ---
                ...tokouserMembers.entries.map((entry) {
                  final memberUid = entry.key;
                  final memberRole = entry.value['role'] ?? 'Miembro';
                  final memberName = "Usuario Toko ($memberUid)";

                  return ListTile(
                    contentPadding: EdgeInsets.zero, leading: const CircleAvatar(backgroundColor: AppColors.secondaryColor, child: Icon(Icons.person, color: AppColors.textWhite)),
                    title: Text(memberName, style: const TextStyle(color: AppColors.textWhite)),
                    subtitle: Text('Rol: $memberRole', style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: PopupMenuButton<String>(
                      color: AppColors.backgroundDark,
                      onSelected: (value) async {
                        if (value == 'edit') {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lógica de edición de Usuario Toko pendiente.')));
                        } else if (value == 'delete') {
                          final confirmed = await _showDeleteConfirmation(memberName);
                          if (confirmed) { _removeMember(memberUid, false); }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(value: 'edit', child: Text('Editar Rol', style: TextStyle(color: AppColors.textWhite))),
                        PopupMenuItem<String>(value: 'delete', child: Text('Eliminar/Expulsar', style: TextStyle(color: AppColors.primaryColor))),
                      ],
                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                    ),
                  );
                }).toList(),

                // --- Lista de Miembros Externos (StreamBuilder) ---
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bands').doc(widget.bandId).collection('externalMembers').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Text('Error al cargar miembros externos.', style: TextStyle(color: AppColors.primaryColor));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

                    final externalMembers = snapshot.data!.docs;

                    return Column(
                      children: externalMembers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final memberName = data['name'] ?? 'Músico Externo';
                        final memberRole = data['bandRole'] ?? 'Músico';

                        return ListTile(
                          contentPadding: EdgeInsets.zero, leading: const CircleAvatar(backgroundColor: AppColors.secondaryColor, child: Icon(Icons.mic, color: AppColors.textWhite)),
                          title: Text(memberName, style: const TextStyle(color: AppColors.textWhite)),
                          subtitle: Text('Rol: $memberRole', style: const TextStyle(color: AppColors.textSecondary)),
                          trailing: PopupMenuButton<String>(
                            color: AppColors.backgroundDark,
                            onSelected: (value) async {
                              if (value == 'edit') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditBandMemberScreen(bandId: widget.bandId, memberId: doc.id, memberData: data, isExternalMember: true,),
                                  ),
                                );
                              } else if (value == 'delete') {
                                final confirmed = await _showDeleteConfirmation(memberName);
                                if (confirmed) { _removeMember(doc.id, true); }
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(value: 'edit', child: Text('Editar Perfil', style: TextStyle(color: AppColors.textWhite))),
                              PopupMenuItem<String>(value: 'delete', child: Text('Eliminar Perfil', style: TextStyle(color: AppColors.primaryColor))),
                            ],
                            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // --- BOTÓN MINIMALISTA DE AGREGAR MIEMBRO ---
          const Divider(color: AppColors.secondaryColor),
          TextButton.icon(
            onPressed: _navigateToAddMemberScreen,
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.primaryColor),
            label: const Text('Agregar Nuevo Músico', style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // 📌 Eliminamos el topPadding ya que el AppBar lo gestionará

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bands').doc(widget.bandId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }

        final bandData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        if (!_isDataLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _loadInitialData(bandData);
            });
          });
        }

        final logoUrl = bandData['logoUrl'] as String?;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          // ✅ APP BAR CON FLECHA DE RETROCESO
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textSecondary), // Color de la flecha
            title: const Text(
                'Editar Perfil de Banda',
                style: TextStyle(color: AppColors.textWhite)
            ),
          ),
          body: SingleChildScrollView(
            // Padding estático, el AppBar maneja el padding superior
            padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- LOGO ---
                Center(
                  child: GestureDetector(
                    onTap: _pickAndUploadLogo,
                    child: CircleAvatar(
                      radius: 60, backgroundColor: AppColors.secondaryColor,
                      backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                      child: logoUrl == null ? const Icon(Icons.camera_alt, size: 40, color: AppColors.textWhite) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- FORMULARIO DE EDICIÓN ---
                CustomInputField(controller: _nameController, labelText: 'Nombre de la Banda', icon: Icons.group_outlined),
                const SizedBox(height: 16),
                CustomInputField(controller: _cityController, labelText: 'Ciudad', icon: Icons.location_city_outlined),
                const SizedBox(height: 16),
                CustomInputField(controller: _bioController, labelText: 'Biografía', icon: Icons.info_outline, maxLines: 4),
                const SizedBox(height: 16),
                CustomInputField(controller: _emailController, labelText: 'Email de Contacto', icon: Icons.email_outlined),
                const SizedBox(height: 16),
                // ✅ CAMPO DE TELÉFONO DE CONTACTO
                CustomInputField(
                  controller: _phoneController,
                  labelText: 'Teléfono de Contacto',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone, // Teclado optimizado
                ),
                const SizedBox(height: 16),
                CustomInputField(controller: _socialsController, labelText: 'Links Sociales (URL)', icon: Icons.link_outlined),
                const SizedBox(height: 24),

                // --- FECHA DE FUNDACIÓN (Nacimiento de la Banda) ---
                GestureDetector(
                  onTap: _pickDateFounded,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha de Fundación', labelStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.secondaryColor.withOpacity(0.5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5))),
                    ),
                    child: Text(_dateFounded == null ? 'Seleccionar fecha' : DateFormat.yMMMd().format(_dateFounded!), style: const TextStyle(color: AppColors.textWhite, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),

                // --- EDICIÓN DE GÉNEROS ---
                const Text('Géneros de la Banda', style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: Wrap(
                    spacing: 8.0, runSpacing: 4.0,
                    children: _availableGenres.map((genre) {
                      final isSelected = _selectedGenres.contains(genre);
                      return ActionChip(
                        label: Text(genre),
                        labelStyle: TextStyle(color: isSelected ? AppColors.textWhite : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                        backgroundColor: isSelected ? AppColors.primaryColor : AppColors.secondaryColor.withOpacity(0.5),
                        side: BorderSide(color: isSelected ? AppColors.primaryColor : AppColors.secondaryColor),
                        onPressed: () {
                          setState(() {
                            if (isSelected) { _selectedGenres.remove(genre); } else { if (_selectedGenres.length < 3) { _selectedGenres.add(genre); } }
                          });
                          FocusScope.of(context).unfocus();
                        },
                      );
                    }).toList(),
                  ),
                ),

                // --- GESTIÓN DE MIEMBROS ---
                _buildMembersManagement(bandData),

                const SizedBox(height: 32),

                // --- BOTÓN DE GUARDAR ---
                SecondaryButton(text: 'Guardar Cambios del Perfil', onPressed: _saveProfile),
              ],
            ),
          ),
        );
      },
    );
  }
}
