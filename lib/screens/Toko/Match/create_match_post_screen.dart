import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/SecondaryButton.dart';

class CreateMatchPostScreen extends StatefulWidget {
  final String currentUserId;
  final String? bandId;
  final bool isBandPost;

  const CreateMatchPostScreen({
    super.key,
    required this.currentUserId,
    required this.bandId,
    required this.isBandPost,
  });

  @override
  State<CreateMatchPostScreen> createState() => _CreateMatchPostScreenState();
}

class _CreateMatchPostScreenState extends State<CreateMatchPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rolesController = TextEditingController(); // Roles/Instrumentos que busca o que toca
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();

  final List<String> _availableGenres = ['Rock', 'Pop', 'Indie', 'Metal', 'Cumbia', 'Jazz', 'Electrónica'];
  Set<String> _selectedGenres = {};

  bool _isLoading = false;
  String _bandName = 'Cargando nombre...';

  @override
  void initState() {
    super.initState();
    if (widget.isBandPost && widget.bandId != null) {
      _fetchBandName();
    }
  }

  @override
  void dispose() {
    _rolesController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // Obtiene el nombre de la banda para el título del post
  Future<void> _fetchBandName() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('bands').doc(widget.bandId).get();
      if (mounted) {
        setState(() {
          _bandName = doc.data()?['name'] ?? 'Banda Desconocida';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bandName = 'Error al cargar nombre';
        });
      }
    }
  }

  // --- LÓGICA DE CREACIÓN DE POST ---
  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate() || _selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa todos los campos y selecciona géneros.')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final postType = widget.isBandPost ? 'BAND_SEARCH' : 'MUSICIAN_OFFER';

      final newPost = {
        'type': postType,
        'creatorId': widget.isBandPost ? widget.bandId : widget.currentUserId,
        'bandName': widget.isBandPost ? _bandName : null,
        'rolesNeeded': _rolesController.text.split(',').map((s) => s.trim()).toList(),
        'genres': _selectedGenres.toList(),
        'city': _cityController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'Open',
        'applicants': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('match_posts').add(newPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Publicación de Match creada con éxito!')));
        Navigator.of(context).pop();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear publicación: $e')));
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isBandPost ? 'Buscar Músicos para $_bandName' : 'Publicar mi Oferta de Músico';

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
                widget.isBandPost
                    ? 'Define el rol o instrumento que necesita tu banda.'
                    : 'Define tus habilidades para ofrecerte a bandas.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 20),

              // CAMPO: ROLES/INSTRUMENTOS
              CustomInputField(
                controller: _rolesController,
                labelText: widget.isBandPost ? 'Roles Buscados (Ej: Baterista, Manager)' : 'Instrumentos que Toca (Ej: Voz, Guitarra)',
                icon: Icons.music_note,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // CAMPO: CIUDAD
              CustomInputField(
                controller: _cityController,
                labelText: 'Ciudad de Operación',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),

              // CAMPO: DESCRIPCIÓN/BIO
              CustomInputField(
                controller: _descriptionController,
                labelText: widget.isBandPost ? 'Descripción de la Vacante' : 'Biografía y Experiencia',
                icon: Icons.info_outline,
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              // SELECCIÓN DE GÉNEROS
              const Text('Géneros Musicales', style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0, runSpacing: 4.0,
                children: _availableGenres.map((genre) {
                  final isSelected = _selectedGenres.contains(genre);
                  return ActionChip(
                    label: Text(genre),
                    labelStyle: TextStyle(color: isSelected ? AppColors.textWhite : AppColors.textSecondary),
                    backgroundColor: isSelected ? AppColors.primaryColor : AppColors.secondaryColor.withOpacity(0.5),
                    onPressed: () {
                      setState(() {
                        if (isSelected) { _selectedGenres.remove(genre); } else { _selectedGenres.add(genre); }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // BOTÓN DE PUBLICACIÓN
              _isLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor)))
                  : SecondaryButton(
                text: widget.isBandPost ? 'Publicar Vacante' : 'Publicar Mi Perfil',
                onPressed: _createPost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
