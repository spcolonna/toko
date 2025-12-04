import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:toko/theme/AppColors.dart';


class CreateEventScreen extends StatefulWidget {
  final String bandId;
  const CreateEventScreen({super.key, required this.bandId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _venueController = TextEditingController(); // Venue is optional for posts
  final _descriptionController = TextEditingController();
  final _ticketLinkController = TextEditingController();

  // --- CONTENT TYPE STATE ---
  String _contentType = 'EVENT'; // Default to EVENT
  final List<String> _contentTypes = ['EVENT', 'POST'];

  List<Map<String, dynamic>> _ticketList = [];
  DateTime? _selectedDateTime;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _descriptionController.dispose();
    _ticketLinkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  Future<void> _showTicketDialog({int? index, Map<String, dynamic>? currentTicket}) async {
    final nameController = TextEditingController(text: currentTicket?['name']);
    final valueController = TextEditingController(text: currentTicket?['value']?.toStringAsFixed(2) ?? '');
    final isEditing = index != null;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundDark,
          title: Text(isEditing ? 'Editar Precio' : 'Agregar Tipo de Entrada', style: const TextStyle(color: AppColors.textWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(controller: nameController, labelText: 'Descripción (Ej: General, VIP)', icon: Icons.description, validator: (v) => v!.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 16),
              _buildTextField(controller: valueController, labelText: 'Precio (€, \$)', icon: Icons.attach_money, keyboardType: TextInputType.number, validator: (v) => double.tryParse(v!) == null ? 'Valor inválido' : null),
            ],
          ),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: () {
                  setState(() { _ticketList.removeAt(index); });
                  Navigator.of(context).pop();
                },
                child: const Text('Eliminar', style: TextStyle(color: AppColors.primaryColor)),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(valueController.text.trim());
                if (nameController.text.isNotEmpty && value != null) {
                  setState(() {
                    final newTicket = {'name': nameController.text.trim(), 'value': value};
                    if (isEditing) {
                      _ticketList[index] = newTicket;
                    } else {
                      _ticketList.add(newTicket);
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
              child: const Text('Guardar', style: const TextStyle(color: AppColors.textWhite)),
            ),
          ],
        );
      },
    );
  }

  // --- FUNCIÓN UNIFICADA DE SUBMISIÓN ---
  Future<void> _submitContent() async {
    if (!_formKey.currentState!.validate()) return;

    // 1. VALIDACIÓN ESPECÍFICA DE EVENTOS
    if (_contentType == 'EVENT') {
      if (_selectedDateTime == null) { _showSnackBar('Selecciona la fecha y hora del evento.'); return; }
      if (_ticketList.isEmpty) { _showSnackBar('Debes agregar al menos un tipo de entrada.'); return; }
    }

    setState(() { _isSaving = true; });

    try {
      final baseData = {
        'bandId': widget.bandId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'linkUrl': _ticketLinkController.text.trim(), // Reutilizamos para link
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_contentType == 'EVENT') {
        // 2. CREACIÓN DE EVENTO
        final newEvent = {
          ...baseData,
          'date': Timestamp.fromDate(_selectedDateTime!),
          'place': _venueController.text.trim(),
          'tickets': _ticketList,
          'attendees': [],
        };
        await FirebaseFirestore.instance.collection('events').add(newEvent);
        _showSnackBar('🎉 Evento creado con éxito!');

      } else {
        // 3. CREACIÓN DE POST GENERAL
        final newPost = {
          ...baseData,
          'type': 'NEWS', // Asumo 'NEWS' como default para post general
          // Place/Venue no son necesarios aquí
        };
        await FirebaseFirestore.instance.collection('band_posts').add(newPost);
        _showSnackBar('🎉 Publicación de banda creada con éxito!');
      }

      // Limpiar formulario después de guardar
      _titleController.clear(); _venueController.clear(); _descriptionController.clear(); _ticketLinkController.clear();
      setState(() { _selectedDateTime = null; _ticketList = []; });

      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      _showSnackBar('🚨 Error al crear contenido: $e');
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  }

  // WIDGET AUXILIAR: Campo de Texto Estilizado (Formulario)
  Widget _buildTextField({
    required TextEditingController controller, required String labelText, required IconData icon,
    TextInputType keyboardType = TextInputType.text, int maxLines = 1, String? Function(String?)? validator,
  }) {
    // NOTE: Reemplaza con tu CustomInputField real
    return TextFormField(
      controller: controller, keyboardType: keyboardType, maxLines: maxLines,
      style: const TextStyle(color: AppColors.textWhite),
      decoration: InputDecoration(
        labelText: labelText, labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primaryColor), filled: true,
        fillColor: AppColors.secondaryColor.withOpacity(0.2),
      ),
      validator: validator ?? (value) => (value == null || value.isEmpty) ? 'Este campo es obligatorio.' : null,
    );
  }

  // WIDGET AUXILIAR: Selector de Fecha/Hora
  Widget _buildDateTimeSelector() {
    final String displayDate = _selectedDateTime == null ? 'Seleccionar Fecha y Hora' : DateFormat('EEE, d MMM yyyy - h:mm a', 'es').format(_selectedDateTime!);
    return InkWell(
      onTap: _isSaving ? null : _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16.0), decoration: BoxDecoration(color: AppColors.secondaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryColor, width: _selectedDateTime == null ? 0 : 1)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primaryColor), const SizedBox(width: 12),
            Text(displayDate, style: TextStyle(color: _selectedDateTime == null ? AppColors.textSecondary : AppColors.textWhite, fontSize: 16, fontWeight: _selectedDateTime == null ? FontWeight.normal : FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // WIDGET AUXILIAR: Listado de Precios
  Widget _buildTicketList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipos de Entrada y Precios', style: TextStyle(color: AppColors.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0, runSpacing: 4.0,
          children: _ticketList.asMap().entries.map((entry) {
            final index = entry.key;
            final ticket = entry.value;
            // NOTE: Reemplaza con tu ActionChip real
            return ActionChip(
              backgroundColor: AppColors.secondaryColor.withOpacity(0.5),
              label: Text('${ticket['name']} - \$${ticket['value'].toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textWhite)),
              onPressed: () => _showTicketDialog(index: index, currentTicket: ticket),
              avatar: const Icon(Icons.money, color: AppColors.primaryColor, size: 18),
            );
          }).toList(),
        ),
        TextButton.icon(
          onPressed: () => _showTicketDialog(),
          icon: const Icon(Icons.add_circle, color: AppColors.primaryColor),
          label: const Text('Agregar Otro Precio', style: const TextStyle(color: AppColors.primaryColor)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEvent = _contentType == 'EVENT';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(isEvent ? 'Crear Nuevo Evento' : 'Crear Nueva Publicación', style: const TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDark,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- 1. SELECTOR DE TIPO ---
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Tipo de Contenido',
                  prefixIcon: const Icon(Icons.create, color: AppColors.primaryColor),
                  filled: true, fillColor: AppColors.secondaryColor.withOpacity(0.2),
                ),
                dropdownColor: AppColors.backgroundDark,
                style: const TextStyle(color: AppColors.textWhite),
                value: _contentType,
                items: _contentTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type == 'EVENT' ? 'Evento/Toque' : 'Noticia/Post General', style: const TextStyle(color: AppColors.textWhite)))).toList(),
                onChanged: (value) { setState(() {
                  _contentType = value ?? 'EVENT';
                  // Reset fields specific to the other type when switching
                  _selectedDateTime = null;
                  _ticketList = [];
                }); },
              ),
              const SizedBox(height: 24),

              // --- 2. CAMPOS COMUNES ---
              _buildTextField(controller: _titleController, labelText: 'Título', icon: Icons.subtitles),
              const SizedBox(height: 16),
              _buildTextField(controller: _descriptionController, labelText: 'Descripción/Cuerpo', icon: Icons.notes, maxLines: 4),
              const SizedBox(height: 16),

              // --- 3. CAMPOS CONDICIONALES (EVENTOS) ---
              if (isEvent) ...[
                _buildDateTimeSelector(),
                const SizedBox(height: 16),
                _buildTextField(controller: _venueController, labelText: 'Lugar / Recinto', icon: Icons.location_on),
                const SizedBox(height: 16),
                _buildTicketList(),
                const SizedBox(height: 16),
              ],

              // Enlace (Útil para ambos: tickets o noticia)
              _buildTextField(
                controller: _ticketLinkController,
                labelText: isEvent ? 'Enlace de Compra de Tickets (opcional)' : 'Enlace de Noticia/Tema Nuevo (opcional)',
                icon: Icons.link,
                keyboardType: TextInputType.url,
                validator: (value) => null,
              ),
              const SizedBox(height: 32),

              // --- BOTÓN DE CREACIÓN ---
              ElevatedButton(
                onPressed: _isSaving ? null : _submitContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.textWhite))
                    : Text(isEvent ? 'Crear Evento' : 'Crear Publicación', style: const TextStyle(fontSize: 18, color: AppColors.textWhite)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
