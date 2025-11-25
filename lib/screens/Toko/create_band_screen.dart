import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Necesario para formatear la fecha

import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/SecondaryButton.dart';
import '../../l10n/app_localizations.dart';

class CreateBandScreen extends StatefulWidget {
  const CreateBandScreen({super.key});

  @override
  State<CreateBandScreen> createState() => _CreateBandScreenState();
}

class _CreateBandScreenState extends State<CreateBandScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController(); // NUEVO: Email de Contacto
  final _socialsController = TextEditingController(); // NUEVO: Links Sociales

  DateTime? _dateFounded; // NUEVO: Fecha de Fundación (Fecha de nacimiento de la banda)

  final List<String> _availableGenres = ['Rock', 'Pop', 'Indie', 'Metal', 'Cumbia', 'Jazz', 'Electrónica'];
  Set<String> _selectedGenres = {};

  // Roles disponibles para el miembro creador
  final List<String> _availableRoles = ['Vocalist', 'Guitarist', 'Bassist', 'Drummer', 'Keyboardist', 'Manager'];
  String? _selectedMemberRole; // Rol que se auto-asigna el creador

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _socialsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateFounded() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateFounded ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor, // Color principal del Picker
              onPrimary: AppColors.textWhite,
              surface: AppColors.backgroundDark, // Fondo
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
        _dateFounded = pickedDate;
      });
    }
  }

  Future<void> _createBand() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isLoading) return;

    if (_nameController.text.isEmpty || _selectedGenres.isEmpty || _cityController.text.isEmpty || _dateFounded == null || _selectedMemberRole == null) {
      _showErrorDialog(l10n.errorTitle, l10n.bandCreationErrorMissingFields);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final bandRef = FirebaseFirestore.instance.collection('bands');

      final newBand = {
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'contactEmail': _emailController.text.trim(), // Guardado
        'socialLinks': _socialsController.text.trim(), // Guardado (Podría ser un mapa luego)
        'dateFounded': Timestamp.fromDate(_dateFounded!), // Guardado
        'genres': _selectedGenres.toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'ownerUid': user.uid,
        'members': {},
        'followersCount': 0,
        'eventsCount': 0,
      };

      final newBandDoc = await bandRef.add(newBand);
      final bandId = newBandDoc.id;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'hasBand': true,
        'managedBandId': bandId,
        'mainBandId': bandId,
      });

      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      _showErrorDialog(l10n.errorTitle, l10n.genericErrorContent(e.toString()));
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        TextButton(child: Text(l10n.ok), onPressed: () { Navigator.of(ctx).pop(); })
      ],
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(l10n.createBandTitle, style: const TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomInputField(controller: _nameController, labelText: l10n.bandNameLabel, icon: Icons.group_outlined),
            const SizedBox(height: 24),

            // NUEVO: Fecha de Fundación de la Banda
            GestureDetector(
              onTap: _pickDateFounded,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dateFoundedLabel,
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                  ),
                ),
                child: Text(
                  _dateFounded == null
                      ? l10n.dateFoundedPlaceholder
                      : DateFormat.yMMMd().format(_dateFounded!),
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            CustomInputField(controller: _cityController, labelText: l10n.cityLabel, icon: Icons.location_city_outlined),
            const SizedBox(height: 24),
            CustomInputField(controller: _bioController, labelText: l10n.bioLabel, icon: Icons.info_outline, maxLines: 4),
            const SizedBox(height: 24),

            // NUEVO: Email de Contacto
            CustomInputField(controller: _emailController, labelText: l10n.contactEmailLabel, icon: Icons.email_outlined),
            const SizedBox(height: 24),

            // NUEVO: Links Sociales
            CustomInputField(controller: _socialsController, labelText: l10n.socialLinksLabel, icon: Icons.link_outlined),
            const SizedBox(height: 24),

            // NUEVO: Rol del Creador (Autoclasificación como primer miembro)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: l10n.yourRoleLabel,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.mic_none, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundDark,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              dropdownColor: AppColors.backgroundDark,
              style: const TextStyle(color: AppColors.textWhite),
              value: _selectedMemberRole,
              items: _availableRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMemberRole = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // SELECCIÓN DE GÉNEROS
            Text(l10n.selectGenresLabel, style: const TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _availableGenres.map((genre) {
                final isSelected = _selectedGenres.contains(genre);
                return ActionChip(
                  label: Text(genre),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: isSelected ? AppColors.primaryColor : Colors.transparent,
                  side: BorderSide(color: isSelected ? AppColors.primaryColor : AppColors.secondaryColor),
                  onPressed: () {
                    setState(() {
                      if (isSelected) {
                        _selectedGenres.remove(genre);
                      } else {
                        if (_selectedGenres.length < 3) { _selectedGenres.add(genre); }
                      }
                    });
                    FocusScope.of(context).unfocus();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 48),

            // BOTÓN DE CREACIÓN
            _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)))
                : SecondaryButton(
              text: l10n.createBandButton,
              onPressed: _createBand,
            ),
          ],
        ),
      ),
    );
  }
}
