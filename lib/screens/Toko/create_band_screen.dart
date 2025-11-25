import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  // Lista de géneros disponibles (puedes expandirla luego)
  final List<String> _availableGenres = ['Rock', 'Pop', 'Indie', 'Metal', 'Cumbia', 'Jazz', 'Electrónica'];
  Set<String> _selectedGenres = {};

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE CREACIÓN EN FIREBASE ---
  Future<void> _createBand() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _isLoading) return;

    if (_nameController.text.isEmpty || _selectedGenres.isEmpty || _cityController.text.isEmpty) {
      _showErrorDialog(l10n.errorTitle, l10n.bandCreationErrorMissingFields);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final bandRef = FirebaseFirestore.instance.collection('bands');

      // 1. Crear el documento de la banda
      final newBand = {
        'name': _nameController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _bioController.text.trim(),
        'genres': _selectedGenres.toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'ownerUid': user.uid, // El creador es el propietario
        'members': {
          user.uid: {'role': 'Manager', 'instrument': 'Vocalista/Músico', 'joinedAt': FieldValue.serverTimestamp()}
        },
        'followersCount': 0,
        'eventsCount': 0,
      };

      final newBandDoc = await bandRef.add(newBand);
      final bandId = newBandDoc.id;

      // 2. Actualizar el perfil del usuario en Firestore (users collection)
      // Indica que el usuario ya tiene una banda y guarda el ID
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'hasBand': true,
        'managedBandId': bandId,
        'mainBandId': bandId, // ID de la banda principal a la que pertenece
      });

      // 3. Navegación exitosa: Volver a la pantalla principal
      if (mounted) {
        // En un escenario real, deberías actualizar el estado global del usuario (Provider)
        // y luego navegar. Por ahora, simplemente cerramos la pantalla.
        Navigator.of(context).pop();
      }

    } catch (e) {
      _showErrorDialog(l10n.errorTitle, l10n.genericErrorContent(e.toString()));
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  void _showErrorDialog(String title, String content) {
    // ... (función de diálogo de error, la puedes copiar de WelcomeScreen)
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
        title: Text(l10n.createBandTitle, style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. INPUT: Nombre de la Banda
            CustomInputField(
              controller: _nameController,
              labelText: l10n.bandNameLabel,
              icon: Icons.group_outlined,
            ),
            const SizedBox(height: 24),

            // 2. INPUT: Ciudad
            CustomInputField(
              controller: _cityController,
              labelText: l10n.cityLabel,
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(height: 24),

            // 3. INPUT: Biografía
            CustomInputField(
              controller: _bioController,
              labelText: l10n.bioLabel,
              icon: Icons.info_outline,
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // 4. SELECCIÓN DE GÉNEROS (Chips)
            Text(
              l10n.selectGenresLabel,
              style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
                  backgroundColor: isSelected ? AppColors.primaryColor : AppColors.secondaryColor.withOpacity(0.5),
                  onPressed: () {
                    setState(() {
                      if (isSelected) {
                        _selectedGenres.remove(genre);
                      } else {
                        _selectedGenres.add(genre);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 48),

            // 5. BOTÓN DE CREACIÓN
            _isLoading
                ? Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor))
            )
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
