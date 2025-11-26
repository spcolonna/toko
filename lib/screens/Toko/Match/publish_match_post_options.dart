import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';

// Este widget muestra un botón o un menú de opciones basado en si el usuario tiene una banda.
class PublishMatchPostOptions extends StatelessWidget {
  const PublishMatchPostOptions({super.key});

  // Función de navegación de ejemplo (deberás reemplazarla con tu lógica real)
  void _navigateToCreatePost(BuildContext context, String postType) {
    // Aquí puedes usar Navigator para ir a la pantalla de creación
    String message = postType == 'BAND_SEARCH'
        ? 'Navegar a: Publicar Búsqueda de Banda'
        : 'Navegar a: Ofrecer Perfil de Músico';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: postType == 'BAND_SEARCH' ? AppColors.primaryColor : AppColors.textSecondary,
      ),
    );
    // Ejemplo de navegación real:
    // Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatePostScreen(type: postType)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink(); // No mostrar nada si no hay usuario logueado
    }

    // 1. Stream para obtener el perfil del usuario y el estado de la banda.
    final Stream<DocumentSnapshot> userProfileStream = FirebaseFirestore.instance
        .collection('user_profiles')
        .doc(user.uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: userProfileStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mostrar un indicador de carga pequeño mientras se recuperan los datos.
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
            ),
          );
        }

        // Asumir que 'hasBand' es false si el documento no existe o el campo es nulo.
        final bool hasBand = snapshot.data?.get('hasBand') ?? false;

        if (hasBand) {
          // 2. Si el usuario tiene banda: Mostrar un menú de opciones (dos caminos)
          return PopupMenuButton<String>(
            color: AppColors.secondaryColor,
            icon: const Icon(Icons.add, color: AppColors.textWhite),
            onSelected: (String result) {
              _navigateToCreatePost(context, result);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              // Opción 1: Publicar búsqueda para la banda
              PopupMenuItem<String>(
                value: 'BAND_SEARCH',
                child: Text(
                    'Publicar Búsqueda de Banda',
                    style: const TextStyle(color: AppColors.textWhite)
                ),
              ),
              const PopupMenuDivider(),
              // Opción 2: Ofrecerse como músico (perfil)
              PopupMenuItem<String>(
                value: 'MUSICIAN_OFFER',
                child: Text(
                    'Ofrecerme como Músico',
                    style: const TextStyle(color: AppColors.textWhite)
                ),
              ),
            ],
          );
        } else {
          // 3. Si el usuario NO tiene banda: Mostrar un botón directo (un camino)
          return FloatingActionButton(
            heroTag: 'publish_musician_offer',
            backgroundColor: AppColors.primaryColor,
            onPressed: () => _navigateToCreatePost(context, 'MUSICIAN_OFFER'),
            child: const Icon(Icons.mic, color: AppColors.textWhite),
          );
        }
      },
    );
  }
}
