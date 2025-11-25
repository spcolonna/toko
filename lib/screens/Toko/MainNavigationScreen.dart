import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';
import 'bands_screen.dart';
import 'event_screen.dart';
import 'match_screen.dart';
import 'my_band_screen.dart';
import 'create_band_screen.dart';
import 'my_schedule_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = const <Widget>[
    EventScreen(),
    BandsScreen(),
    MyScheduleScreen(),
    MatchScreen(),
    MyBandScreen(), // MyBandScreen es la pestaña 4 (índice 4)
  ];

  void _onItemTapped(int index) async {
    final user = FirebaseAuth.instance.currentUser;

    if (index == 4 && user != null) {
      // --- LÓGICA DE INTERCEPCIÓN PARA LA PESTAÑA 'MI BANDA' (índice 4) ---

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final hasBand = userData?['hasBand'] ?? false;

      if (!hasBand) {
        // Opción A: Usuario NO tiene banda -> Navegar directamente al formulario
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CreateBandScreen()),
        );
        // NO actualizamos _selectedIndex, manteniendo la vista en el Tab anterior (ej. Eventos)
        return;
      }
    }

    // Opción B: Si es cualquier otra pestaña (0-3) o si ya TIENE banda,
    // simplemente cambiamos el Tab.
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // El StreamBuilder sigue siendo útil aquí para actualizar el ícono del tab
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
    }

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final bool hasBand = userData?['hasBand'] ?? false;

          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(
              // El cuerpo solo muestra la pantalla del índice seleccionado
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.backgroundDark,
              selectedItemColor: AppColors.primaryColor,
              unselectedItemColor: AppColors.textSecondary,
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'Eventos'),
                const BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Bandas'),
                const BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Mi Agenda'),
                const BottomNavigationBarItem(icon: Icon(Icons.handshake_outlined), label: 'Match'),

                // 5. PESTAÑA DINÁMICA
                BottomNavigationBarItem(
                  icon: Icon(hasBand ? Icons.mic_external_on : Icons.add_circle_outline),
                  label: hasBand ? 'Mi Banda' : 'Crear Banda',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped, // Usamos la función con la lógica de intercepción
            ),
          );
        }
    );
  }
}
