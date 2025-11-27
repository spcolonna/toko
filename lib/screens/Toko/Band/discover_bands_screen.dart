import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toko/theme/AppColors.dart';

import 'band_public_profile_screen.dart';


// Constantes de paginación
const int bandsPerPage = 10;

class DiscoverBandsScreen extends StatefulWidget {
  const DiscoverBandsScreen({super.key});

  @override
  State<DiscoverBandsScreen> createState() => _DiscoverBandsScreenState();
}

class _DiscoverBandsScreenState extends State<DiscoverBandsScreen> {
  // --- ESTADO Y CONTROLADORES ---
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _bandDocuments = [];
  bool _isLoading = false;
  bool _hasMore = true; // Indica si hay más documentos para cargar
  DocumentSnapshot? _lastDocument; // Cursor para la paginación

  // Filtros
  final List<String> _availableGenres = ['Rock', 'Pop', 'Indie', 'Metal', 'Cumbia', 'Jazz', 'Electrónica'];
  Set<String> _selectedGenres = {};
  String _currentSearchTerm = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBands(); // Carga inicial
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- 2. LÓGICA DE CARGA DE DATOS ---

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('bands')
        .orderBy('name', descending: false)
        .limit(bandsPerPage);

    // Búsqueda por Género (Filtrado)
    // Firestore no permite 'array-contains-any' y 'limit' o 'startAfter' al mismo tiempo
    // en consultas complejas. Para filtros OR, usaremos 'arrayContainsAny'
    if (_selectedGenres.isNotEmpty) {
      // Nota: Firestore limita arrayContainsAny a 10 valores
      query = query.where('genres', arrayContainsAny: _selectedGenres.toList());
    }

    // Búsqueda por Nombre: Firestore requiere que el campo ordenado sea el campo filtrado.
    // Para simplificar, la búsqueda por nombre se hará por el momento solo a nivel de cliente
    // después de cargar los datos, O en Firestore solo si el nombre empieza con una letra específica,
    // ya que no soporta búsquedas de substring sin un índice completo.
    // Por ahora, cargaremos todo el set y filtraremos localmente si hay un término de búsqueda.

    return query;
  }

  Future<void> _loadBands({bool isRefresh = false}) async {
    if (_isLoading) return;
    if (!isRefresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query baseQuery = _buildQuery();

      if (!isRefresh && _lastDocument != null) {
        baseQuery = baseQuery.startAfterDocument(_lastDocument!);
      }

      final snapshot = await baseQuery.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        if (isRefresh) {
          _bandDocuments = snapshot.docs;
        } else {
          _bandDocuments.addAll(snapshot.docs);
        }
        _lastDocument = snapshot.docs.last;
        _hasMore = snapshot.docs.length == bandsPerPage;
        _isLoading = false;
      });

    } catch (e) {
      print("Error loading bands: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- 3. MANEJO DE SCROLL (Carga Infinita) ---

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading && _hasMore) {
      _loadBands();
    }
  }

  // --- 4. MANEJO DE FILTROS Y BÚSQUEDA ---

  void _applyFilters() {
    // Cuando los filtros cambian, reiniciamos la paginación
    _bandDocuments = [];
    _lastDocument = null;
    _hasMore = true;
    _loadBands(isRefresh: true);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentSearchTerm = value.toLowerCase();
      // Nota: No recargamos aquí para evitar costosas consultas de Firestore.
      // La búsqueda se aplicará localmente en el ListView.builder.
    });
  }

  // --- 5. UI: CHIPS DE FILTRO DE GÉNERO ---

  Widget _buildGenreChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: _availableGenres.map((genre) {
          final isSelected = _selectedGenres.contains(genre);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(genre),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: isSelected ? AppColors.primaryColor : AppColors.secondaryColor, // #2C2828
              onPressed: () {
                setState(() {
                  if (isSelected) {
                    _selectedGenres.remove(genre);
                  } else {
                    _selectedGenres.add(genre);
                  }
                });
                _applyFilters();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- 6. RENDERIZADO DE BANDAS (Filtrado Local por Nombre) ---

  List<DocumentSnapshot> _getFilteredBands() {
    if (_currentSearchTerm.isEmpty) {
      return _bandDocuments;
    }

    return _bandDocuments.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final bandName = (data['name'] as String?)?.toLowerCase() ?? '';
      return bandName.contains(_currentSearchTerm);
    }).toList();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateMetric(String bandId, String metricField, bool shouldIncrement) async {
    // Las transacciones garantizan que no habrá contadores incorrectos si varios usuarios interactúan a la vez.
    final bandRef = _firestore.collection('bands').doc(bandId);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await _firestore.runTransaction((transaction) async {
      final bandSnapshot = await transaction.get(bandRef);
      if (!bandSnapshot.exists) {
        throw Exception("Band does not exist!");
      }

      final currentCount = bandSnapshot.data()?[metricField] ?? 0;
      final newCount = shouldIncrement ? currentCount + 1 : currentCount - 1;

      // 1. Actualizar el contador de la banda (debe ser atómico)
      transaction.update(bandRef, {metricField: newCount});

      // 2. Actualizar la lista del usuario (collection 'users')
      final userRef = _firestore.collection('users').doc(user.uid);
      final listFieldName = metricField == 'followersCount' ? 'followingBands' : 'likedBands';

      if (shouldIncrement) {
        transaction.update(userRef, {
          listFieldName: FieldValue.arrayUnion([bandId])
        });
      } else {
        transaction.update(userRef, {
          listFieldName: FieldValue.arrayRemove([bandId])
        });
      }
    });
  }

  void _toggleFollow(String bandId, bool isFollowing) {
    _updateMetric(bandId, 'followersCount', !isFollowing);
  }

  void _toggleLike(String bandId, bool isLiked) {
    _updateMetric(bandId, 'likesCount', !isLiked);
  }

  // --- CONSTRUCCIÓN DE LA PANTALLA ---
  @override
  Widget build(BuildContext context) {
    final filteredBands = _getFilteredBands();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      // 🚨 CAMBIO CLAVE: Envuelve el cuerpo en SafeArea
      body: SafeArea(
        child: Column(
          children: [
            // Campo de Búsqueda
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'Buscar bandas por nombre...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.secondaryColor.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Chips de Género
            _buildGenreChips(),

            // Lista de Bandas
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadBands(isRefresh: true),
                color: AppColors.primaryColor,
                backgroundColor: AppColors.backgroundDark,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredBands.length + (_hasMore || _isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredBands.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _hasMore ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)) : Text('No hay más bandas.', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      );
                    }

                    final bandDoc = filteredBands[index];
                    final bandData = bandDoc.data() as Map<String, dynamic>;

                    return BandInteractionTile(
                      bandDoc: bandDoc,
                      onFollowToggle: _toggleFollow,
                      onLikeToggle: _toggleLike,
                      onTap: () {
                        final bandId = bandDoc.id;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BandPublicProfileScreen(bandId: bandId),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BandInteractionTile extends StatelessWidget {
  final DocumentSnapshot bandDoc;
  final Function(String, bool) onFollowToggle;
  final Function(String, bool) onLikeToggle;
  final VoidCallback onTap;

  const BandInteractionTile({
    super.key,
    required this.bandDoc,
    required this.onFollowToggle,
    required this.onLikeToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bandId = bandDoc.id;
    final bandData = bandDoc.data() as Map<String, dynamic>;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox.shrink();

    // Stream para obtener las listas de likedBands y followingBands del usuario
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final List<String> likedBands = List<String>.from(userData['likedBands'] ?? []);
        final List<String> followingBands = List<String>.from(userData['followingBands'] ?? []);

        final bool isLiked = likedBands.contains(bandId);
        final bool isFollowing = followingBands.contains(bandId);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          leading: CircleAvatar(
            backgroundColor: AppColors.secondaryColor,
            backgroundImage: bandData['logoUrl'] != null ? NetworkImage(bandData['logoUrl']) : null,
            child: bandData['logoUrl'] == null ? const Icon(Icons.mic, color: AppColors.textWhite) : null,
          ),
          title: Text(bandData['name'] ?? 'Banda Sin Nombre', style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
          subtitle: Text('Géneros: ${(bandData['genres'] as List?)?.join(', ') ?? 'N/A'} | Seguidores: ${bandData['followersCount'] ?? 0}', style: TextStyle(color: AppColors.textSecondary)),
          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón ME GUSTA
              IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                color: isLiked ? AppColors.primaryColor : AppColors.textSecondary,
                onPressed: () => onLikeToggle(bandId, isLiked),
              ),
              // Botón SEGUIR
              IconButton(
                icon: Icon(isFollowing ? Icons.check_circle : Icons.person_add_alt_1),
                color: isFollowing ? AppColors.secondaryColor : AppColors.textSecondary,
                onPressed: () => onFollowToggle(bandId, isFollowing),
              ),
            ],
          ),
        );
      },
    );
  }
}
