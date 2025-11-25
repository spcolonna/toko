import 'package:flutter/material.dart';
import 'package:toko/screens/Toko/my_schedule_screen.dart';
import 'package:toko/theme/AppColors.dart';

import 'band_screen.dart';
import 'event_screen.dart';
import 'match_screen.dart';
import 'my_band_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Temporalmente, asumo que el usuario aún NO tiene banda para ver el botón 'Crear Banda'
  bool _hasBand = false;

  // 1. Lista de Widgets de las pantallas principales
  final List<Widget> _widgetOptions = <Widget>[
    const EventScreen(),
    const BandScreen(),
    const MyScheduleScreen(),
    const MatchScreen(),
    const MyBandScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Asegura que todos los ítems se muestren
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: AppColors.primaryColor, // Rojo Coral
        unselectedItemColor: AppColors.textSecondary, // Gris Violáceo
        items: <BottomNavigationBarItem>[
          // 1. Eventos (Home)
          const BottomNavigationBarItem(
            icon: Icon(Icons.flash_on),
            label: 'Eventos',
          ),
          // 2. Bandas
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Bandas',
          ),
          // 3. Mi Agenda
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Mi Agenda',
          ),
          // 4. Match
          const BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            label: 'Match',
          ),
          // 5. Mi Banda / Crear Banda (Tab Dinámico)
          BottomNavigationBarItem(
            icon: Icon(_hasBand ? Icons.mic_external_on : Icons.add_circle_outline),
            label: _hasBand ? 'Mi Banda' : 'Crear Banda',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Estos son solo placeholders para que el código compile.
class EventosScreen extends StatelessWidget { const EventosScreen({super.key}); @override Widget build(BuildContext context) { return const Center(child: Text('Eventos (Home)', style: TextStyle(color: AppColors.textWhite))); } }
class BandasScreen extends StatelessWidget { const BandasScreen({super.key}); @override Widget build(BuildContext context) { return const Center(child: Text('Bandas', style: TextStyle(color: AppColors.textWhite))); } }
class MiAgendaScreen extends StatelessWidget { const MiAgendaScreen({super.key}); @override Widget build(BuildContext context) { return const Center(child: Text('Mi Agenda', style: TextStyle(color: AppColors.textWhite))); } }
class MatchScreen extends StatelessWidget { const MatchScreen({super.key}); @override Widget build(BuildContext context) { return const Center(child: Text('Match', style: TextStyle(color: AppColors.textWhite))); } }
class MiBandaScreen extends StatelessWidget { const MiBandaScreen({super.key}); @override Widget build(BuildContext context) { return const Center(child: Text('Mi Banda / Crear Banda', style: TextStyle(color: AppColors.textWhite))); } }
