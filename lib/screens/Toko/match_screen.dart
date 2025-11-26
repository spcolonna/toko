import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toko/theme/AppColors.dart';

import 'Match/create_match_post_screen.dart';
import 'Match/match_band_search_screen.dart';
import 'Match/match_musician_offer_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- FUNCIÓN CENTRAL DE NAVEGACIÓN Y DECISIÓN ---
  Future<void> _navigateToCreatePost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Obtener el estado de la banda (de forma síncrona en el Future)
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final bandId = userData?['managedBandId'];
    final bool hasBand = bandId != null && bandId.isNotEmpty;

    if (!mounted) return;

    if (hasBand) {
      // 2. Si tiene banda: Mostrar el selector de opciones
      _showCreationOptions(context, user.uid, bandId);
    } else {
      // 3. Si NO tiene banda: Navegar directamente a la oferta de Músico
      _startCreationFlow(context, user.uid, null, false);
    }
  }

  // --- FUNCIÓN QUE MUESTRA EL MENÚ INFERIOR DE OPCIONES ---
  void _showCreationOptions(BuildContext context, String userId, String bandId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '¿Qué deseas publicar?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            // Opción 1: Publicar búsqueda para la banda (Vacante)
            ListTile(
              leading: const Icon(Icons.group_add, color: AppColors.textWhite),
              title: const Text('Publicar Vacante para mi Banda', style: TextStyle(color: AppColors.textWhite)),
              onTap: () {
                Navigator.of(context).pop(); // Cierra el modal
                _startCreationFlow(context, userId, bandId, true);
              },
            ),
            // Opción 2: Ofrecerse como Músico
            ListTile(
              leading: const Icon(Icons.mic, color: AppColors.textWhite),
              title: const Text('Ofrecerme como Músico (Mi Perfil)', style: TextStyle(color: AppColors.textWhite)),
              onTap: () {
                Navigator.of(context).pop(); // Cierra el modal
                _startCreationFlow(context, userId, bandId, false);
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // --- FUNCIÓN QUE EJECUTA LA NAVEGACIÓN FINAL ---
  void _startCreationFlow(BuildContext context, String userId, String? bandId, bool isBandPost) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateMatchPostScreen(
          currentUserId: userId,
          bandId: bandId,
          isBandPost: isBandPost,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          title: const Text('Match: Conexiones Musicales', style: TextStyle(color: AppColors.textWhite)),
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: AppColors.primaryColor,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Bandas Buscan', icon: Icon(Icons.person_add_alt_1)),
              Tab(text: 'Músicos Se Ofrecen', icon: Icon(Icons.mic_external_on)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MatchBandSearchScreen(),
            MatchMusicianOfferScreen(),
          ],
        ),
        // 📌 FAB CORREGIDO: Llama a la lógica de decisión, que manejará la navegación.
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToCreatePost,
          label: const Text('Publicar Búsqueda', style: TextStyle(color: AppColors.textWhite)),
          icon: const Icon(Icons.add, color: AppColors.textWhite),
          backgroundColor: AppColors.primaryColor,
        ),
      ),
    );
  }
}
