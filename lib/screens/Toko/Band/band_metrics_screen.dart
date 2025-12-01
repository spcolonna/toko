import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 📌 Importación necesaria

import 'package:toko/theme/AppColors.dart';

// Constantes
const double chartBorderWidth = 0.5;
const String rewardedInterstitialAdUnitId = 'ca-app-pub-9552343552775183/6647242359';
const String kMetricsUnlockTimeKey = 'metricsUnlockTime'; // Clave para SharedPreferences

// --- WIDGET AUXILIAR: Gráfica de Crecimiento (BandGrowthChart) ---
class BandGrowthChart extends StatelessWidget {
  final String bandId;
  const BandGrowthChart({super.key, required this.bandId});

  List<double> _generatePlaceholderData() {
    return List<double>.generate(6, (i) => 100 + i * 50 + Random().nextDouble() * 20);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bands')
          .doc(bandId)
          .collection('metrics_history')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
        }

        final rawDocs = snapshot.data?.docs.reversed.toList() ?? [];

        final bool usePlaceholder = rawDocs.isEmpty;
        final List<double> followers = usePlaceholder
            ? _generatePlaceholderData()
            : List<double>.from(rawDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['followers'] ?? 0.0).toDouble();
        }));

        final List<String> dates = usePlaceholder
            ? ['Mes 1', 'Mes 2', 'Mes 3', 'Mes 4', 'Mes 5', 'Mes 6']
            : rawDocs.map((doc) {
          try {
            return DateFormat('MMM d').format(DateTime.parse(doc.id));
          } catch (e) {
            return 'N/A';
          }
        }).toList();

        if (followers.length < 2) return const SizedBox.shrink();

        List<FlSpot> spots = followers.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value);
        }).toList();

        final double minY = followers.isNotEmpty ? (followers.reduce(min) * 0.95).floorToDouble() : 0;
        final double maxY = followers.isNotEmpty ? (followers.reduce(max) * 1.05).ceilToDouble() : 100;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usePlaceholder ? 'Tendencia Estimada (Datos Ficticios)' : 'Tendencia de Seguidores',
                style: const TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots, isCurved: true,
                        gradient: const LinearGradient(colors: [AppColors.primaryColor, AppColors.secondaryColor], begin: Alignment.centerLeft, end: Alignment.centerRight),
                        barWidth: 3, isStrokeCapRound: true,
                        dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppColors.primaryColor, strokeColor: AppColors.backgroundDark, strokeWidth: 1)),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(colors: [AppColors.primaryColor.withOpacity(0.3), AppColors.secondaryColor.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final String date = dates[touchedSpot.x.toInt()];
                            return LineTooltipItem(
                              '$date\n${touchedSpot.y.toInt()} seg.',
                              const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                    ),
                    minY: minY, maxY: maxY, minX: 0, maxX: dates.length - 1.toDouble(),
                    borderData: FlBorderData(show: true, border: Border.all(color: AppColors.secondaryColor, width: chartBorderWidth)),
                    gridData: FlGridData(
                      show: true, drawVerticalLine: false, horizontalInterval: (maxY - minY) / 4,
                      getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.textSecondary, strokeWidth: 0.5),
                    ),
                    titlesData: FlTitlesData(
                      show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1, getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < dates.length) {
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(dates[value.toInt()], style: TextStyle(color: AppColors.textSecondary, fontSize: 10), textAlign: TextAlign.center));
                        }
                        return const Text('');
                      },),),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.left);
                      }, interval: (maxY - minY) / 4,),),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


// --- WIDGET PRINCIPAL BandMetricsScreen ---
class BandMetricsScreen extends StatefulWidget {
  final String bandId;
  const BandMetricsScreen({super.key, required this.bandId});

  @override
  State<BandMetricsScreen> createState() => _BandMetricsScreenState();
}

class _BandMetricsScreenState extends State<BandMetricsScreen> {
  // LÓGICA DE PUBLICIDAD
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoaded = false;

  // ESTADO DE LA RECOMPENSA (Controlado por SharedPreferences)
  bool _premiumMetricsUnlocked = false;
  DateTime? _accessUnlockTime;

  @override
  void initState() {
    super.initState();
    _checkAndLoadUnlockStatus(); // 📌 CARGA EL ESTADO PERSISTENTE AL INICIO
    _loadRewardedInterstitialAd();
  }

  @override
  void dispose() {
    _rewardedInterstitialAd?.dispose();
    super.dispose();
  }

  // --- LÓGICA DE PERSISTENCIA (CARGA) ---
  Future<void> _checkAndLoadUnlockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final int? savedTimestamp = prefs.getInt(kMetricsUnlockTimeKey);

    if (savedTimestamp != null) {
      final savedTime = DateTime.fromMillisecondsSinceEpoch(savedTimestamp);

      // 1. Si el tiempo aún no ha expirado, desbloquear y actualizar el estado
      if (DateTime.now().isBefore(savedTime)) {
        setState(() {
          _accessUnlockTime = savedTime;
          _premiumMetricsUnlocked = true;
        });
        return;
      }

      // 2. Si expiró, limpiar el valor
      prefs.remove(kMetricsUnlockTimeKey);
    }

    // Asegurar el estado de bloqueo si no hay tiempo válido
    setState(() {
      _premiumMetricsUnlocked = false;
    });
  }

  // --- LÓGICA DE PERSISTENCIA (GUARDADO) ---
  Future<void> _saveUnlockTime(DateTime expirationTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kMetricsUnlockTimeKey, expirationTime.millisecondsSinceEpoch);
  }

  void _loadRewardedInterstitialAd() {
    // ... (Lógica de carga del anuncio se mantiene igual)
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          setState(() { _isAdLoaded = true; });

          _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadRewardedInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          setState(() { _isAdLoaded = false; });
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedInterstitialAd == null || !_isAdLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anuncio aún no cargado. Intenta en un momento.')),
      );
      _loadRewardedInterstitialAd();
      return;
    }

    _rewardedInterstitialAd!.show(onUserEarnedReward: (ad, reward) async {
      // 1. Calcular el tiempo de expiración (24 horas)
      final expirationTime = DateTime.now().add(const Duration(hours: 24));

      // 2. GUARDAR EN SHARED PREFERENCES
      await _saveUnlockTime(expirationTime);

      // 3. Actualizar estado local (para forzar el redibujado inmediato)
      setState(() {
        _accessUnlockTime = expirationTime;
        _premiumMetricsUnlocked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Métricas Premium desbloqueadas por 24h!')),
      );
    });
  }


  // --- Widget para mostrar métricas individuales (Se mantiene) ---
  Widget _buildMetricCard(String title, dynamic value, IconData icon) {
    return Card(
      color: AppColors.secondaryColor.withOpacity(0.3),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 36),
            const SizedBox(height: 8),
            Text(value.toString(), style: const TextStyle(color: AppColors.textWhite, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // Consulta Asíncrona para Vistas (Placeholder)
  Future<int> _fetchTotalViews(String bandId) async {
    final snapshot = await FirebaseFirestore.instance.collection('bands').doc(bandId).get();
    final data = snapshot.data();
    return data?['viewsCount'] ?? 0;
  }

  // Consulta Asíncrona para Interesados en Toques (Placeholder)
  Future<int> _fetchInterestedInShows(String bandId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('bandId', isEqualTo: bandId)
        .get();

    int totalRsvp = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalRsvp += (data['rsvpCount'] ?? 0) as int;
    }
    return totalRsvp;
  }


  @override
  Widget build(BuildContext context) {
    // 📌 VERIFICACIÓN DE EXPIRACIÓN EN EL BUILD:
    // Si el tiempo expiró mientras el widget estaba cargado, reseteamos el estado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_accessUnlockTime != null && DateTime.now().isAfter(_accessUnlockTime!)) {
        if (_premiumMetricsUnlocked) {
          setState(() {
            _premiumMetricsUnlocked = false; // Desbloqueo expirado
            _accessUnlockTime = null;
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bands').doc(widget.bandId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primaryColor)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Error: Datos de la banda no disponibles.', style: TextStyle(color: AppColors.textWhite)));
          }

          final bandData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final followersCount = bandData['followersCount'] ?? 0;
          final likesCount = bandData['likesCount'] ?? 0;
          final postsCount = bandData['postsCount'] ?? 0;

          // 📌 CONTENIDO DE BLOQUEO: Si el acceso no está desbloqueado
          if (!_premiumMetricsUnlocked) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Card(
                  color: AppColors.secondaryColor.withOpacity(0.5),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.lock, color: AppColors.primaryColor, size: 36),
                    title: const Text('Métricas de la Banda Bloqueadas', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        _isAdLoaded ? 'Para acceder a tus estadísticas, visualiza un anuncio.' : 'Cargando datos del anuncio...',
                        style: TextStyle(color: AppColors.textSecondary)
                    ),
                    trailing: ElevatedButton(
                      onPressed: _isAdLoaded ? _showRewardedAd : null,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                      child: _isAdLoaded
                          ? const Text('Ver Anuncio', style: TextStyle(color: AppColors.textWhite))
                          : const Text('Cargando...', style: TextStyle(color: AppColors.textWhite)),
                    ),
                  ),
                ),
              ),
            );
          }


          // 📌 CONTENIDO DESBLOQUEADO: Se muestra si _premiumMetricsUnlocked es true
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estadísticas en Tiempo Real', style: TextStyle(color: AppColors.textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                const Divider(color: AppColors.secondaryColor),

                // 1. Métricas de Interacción Directa
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16, mainAxisSpacing: 16,
                  children: [
                    _buildMetricCard('Seguidores', followersCount, Icons.group),
                    _buildMetricCard('Me Gusta (Total)', likesCount, Icons.favorite),
                    _buildMetricCard('Posteos Publicados', postsCount, Icons.post_add),
                    _buildMetricCard('Vistas de Posteo', 0, Icons.remove_red_eye),
                  ],
                ),

                const SizedBox(height: 32),
                const Text('Métricas de Compromiso', style: TextStyle(color: AppColors.textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                const Divider(color: AppColors.secondaryColor),

                // 2. Métricas de Vistas (FutureBuilder para cálculos pesados)
                FutureBuilder<int>(
                  future: _fetchTotalViews(widget.bandId),
                  builder: (context, viewsSnapshot) {
                    final views = viewsSnapshot.data ?? 0;
                    return GridView.count(
                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16, mainAxisSpacing: 16,
                      children: [
                        _buildMetricCard('Vistas del Perfil', views, Icons.visibility),

                        // Métricas de Eventos (Interesados en toques)
                        FutureBuilder<int>(
                          future: _fetchInterestedInShows(widget.bandId),
                          builder: (context, rsvpSnapshot) {
                            final rsvpCount = rsvpSnapshot.data ?? 0;
                            return _buildMetricCard('Interesados en Toques', rsvpCount, Icons.calendar_month);
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // 3. 📈 GRÁFICO DE TENDENCIA (Implementación Real/Ficticia)
                BandGrowthChart(bandId: widget.bandId),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
