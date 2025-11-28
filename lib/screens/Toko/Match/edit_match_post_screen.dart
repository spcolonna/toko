import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'package:toko/widgets/CustomInputField.dart';
import 'package:toko/widgets/SecondaryButton.dart';

class EditMatchPostScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> initialData;
  final bool isBandPost;

  const EditMatchPostScreen({
    super.key,
    required this.postId,
    required this.initialData,
    required this.isBandPost,
  });

  @override
  State<EditMatchPostScreen> createState() => _EditMatchPostScreenState();
}

class _EditMatchPostScreenState extends State<EditMatchPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rolesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();

  final List<String> _availableGenres = ['Rock', 'Pop', 'Indie', 'Metal', 'Cumbia', 'Jazz', 'Electrónica'];
  Set<String> _selectedGenres = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _rolesController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // --- CARGA INICIAL DE DATOS ---
  void _loadInitialData() {
    final data = widget.initialData;

    _rolesController.text = (data['rolesNeeded'] as List?)?.join(', ') ?? '';
    _descriptionController.text = data['description'] ?? '';
    _cityController.text = data['city'] ?? '';

    final List<String> initialGenres = List<String>.from(data['genres'] ?? []);
    setState(() {
      _selectedGenres = initialGenres.toSet();
    });
  }

  // --- LÓGICA DE ACTUALIZACIÓN ---
  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate() || _selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, completa todos los campos y selecciona géneros.')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final updatedPost = {
        'rolesNeeded': _rolesController.text.split(',').map((s) => s.trim()).toList(),
        'genres': _selectedGenres.toList(),
        'city': _cityController.text.trim(),
        'description': _descriptionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('match_posts').doc(widget.postId).update(updatedPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicación actualizada con éxito!')));
        Navigator.of(context).pop();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar publicación: $e')));
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  // --- LÓGICA DE ELIMINACIÓN Y CONFIRMACIÓN ---
  Future<void> _confirmAndDeletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundDark,
          title: const Text('Confirmar Eliminación', style: TextStyle(color: AppColors.primaryColor)),
          content: const Text('¿Estás seguro de que quieres eliminar esta publicación? Esta acción no se puede deshacer.', style: TextStyle(color: AppColors.textWhite)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('Eliminar', style: TextStyle(color: AppColors.textWhite)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() { _isLoading = true; });
      try {
        // Llama a Firestore para eliminar el documento
        await FirebaseFirestore.instance.collection('match_posts').doc(widget.postId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicación eliminada con éxito!')));
          Navigator.of(context).pop(); // Vuelve a la lista de publicaciones
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        if (mounted) { setState(() { _isLoading = false; }); }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final title = widget.isBandPost ? 'Editar Vacante de Banda' : 'Editar Mi Oferta de Músico';

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
                'Edita los detalles de tu publicación. Los cambios se aplicarán inmediatamente.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 20),

              // CAMPO: ROLES/INSTRUMENTOS
              CustomInputField(
                controller: _rolesController,
                labelText: widget.isBandPost ? 'Roles Buscados (Ej: Baterista, Manager)' : 'Instrumentos que Toca (Ej: Voz, Guitarra)',
                icon: Icons.music_note, maxLines: 2, validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // CAMPO: CIUDAD
              CustomInputField(controller: _cityController, labelText: 'Ciudad de Operación', icon: Icons.location_on, validator: (v) => v!.isEmpty ? 'Requerido' : null,),
              const SizedBox(height: 16),

              // CAMPO: DESCRIPCIÓN/BIO
              CustomInputField(controller: _descriptionController, labelText: widget.isBandPost ? 'Descripción de la Vacante' : 'Biografía y Experiencia', icon: Icons.info_outline, maxLines: 5, validator: (v) => v!.isEmpty ? 'Requerido' : null,),
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

              // BOTÓN DE ACTUALIZACIÓN
              SecondaryButton(
                text: 'Guardar Cambios',
                onPressed: _updatePost,
                isLoading: _isLoading,
              ),

              // Botón de Eliminar (Llama al diálogo de confirmación)
              const SizedBox(height: 16),
              TextButton(
                onPressed: _confirmAndDeletePost, // 📌 Llama a la función de confirmación
                child: const Text('Eliminar Publicación', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
