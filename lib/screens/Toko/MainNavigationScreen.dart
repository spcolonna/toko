import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';

// Importa todas las pantallas de navegación
import 'bands_screen.dart';
import 'event_screen.dart';
import 'match_screen.dart';
import 'my_schedule_screen.dart';

// 📌 IMPORTANTE: Importamos el HUB de gestión que creamos anteriormente
import 'management_decisor_screen.dart';


class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // 1. Definir la lista de Widgets con el Hub de Gestión en el índice 4
  final List<Widget> _widgetOptions = <Widget>[
    EventScreen(),
    const BandsScreen(),
    const MyScheduleScreen(),
    const MatchScreen(),
    const ManagementDecisorScreen(), // 📌 Este es el HUB de opciones (Perfil de Músico / Administración de Banda)
  ];

  // 2. Simplificar la función de tap para solo actualizar el índice
  void _onItemTapped(int index) {
    // Se elimina la lógica de 'push' y la verificación de 'hasBand'.
    // Ahora, tocar un ícono simplemente cambia el contenido del 'body'.
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Mostrar indicador de carga mientras se espera la autenticación/redirección
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
    }

    // 3. Usar StreamBuilder para obtener el estado de la banda y actualizar el ícono del tab dinámicamente
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          // Asumimos que la existencia de managedBandId determina si tiene una banda
          final String? managedBandId = userData?['managedBandId'];
          final bool hasBand = managedBandId != null && managedBandId.isNotEmpty;

          return Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(
              // Muestra el Widget correspondiente al índice seleccionado
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

                // 5. PESTAÑA DE GESTIÓN (Índice 4)
                BottomNavigationBarItem(
                  // El ícono es dinámico, reflejando si tiene banda o si debe crear una
                  icon: Icon(hasBand ? Icons.mic_external_on : Icons.add_circle_outline),
                  // La etiqueta es fija, ya que el HUB maneja la doble funcionalidad
                  label: 'Mi Gestión',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        }
    );
  }
}
