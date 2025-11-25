import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:toko/theme/AppColors.dart';

// Constantes de diseño para la gráfica
const double chartBorderWidth = 0.5;

// --- WIDGET AUXILIAR: Gráfica de Crecimiento ---
class BandGrowthChart extends StatelessWidget {
  final String bandId;
  const BandGrowthChart({super.key, required this.bandId});

  @override
  Widget build(BuildContext context) {
    // Escuchar el historial de métricas de la banda (últimos 6 registros)
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

        // Si no hay datos, mostrar mensaje
        if (rawDocs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No hay datos históricos disponibles para el gráfico.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        // --- PREPARACIÓN DE DATOS REALES ---
        final List<String> dates = rawDocs.map((doc) => DateFormat('MMM d').format(DateTime.parse(doc.id))).toList();

        // ✅ CORRECCIÓN: Usamos List<double>.from() para asegurar el tipo.
        final List<double> followers = List<double>.from(rawDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Se asegura de que el valor sea un double, usando 0.0 si es nulo
          return (data['followers'] ?? 0.0).toDouble();
        }));

        // Convertir a FlSpot para fl_chart
        List<FlSpot> spots = followers.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value);
        }).toList();

        // Calcular el rango Y seguro
        final double minY = followers.isNotEmpty ? (followers.reduce(min) * 0.95).floorToDouble() : 0;
        final double maxY = followers.isNotEmpty ? (followers.reduce(max) * 1.05).ceilToDouble() : 100;

        // --- RENDERIZADO DEL GRÁFICO (FlChart) ---
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tendencia de Seguidores (Últimos 6 Registros)',
                style: TextStyle(color: AppColors.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true, drawVerticalLine: false,
                      horizontalInterval: (maxY - minY) / 4,
                      getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.textSecondary, strokeWidth: 0.5),
                    ),
                    titlesData: FlTitlesData(
                      show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 30, interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < dates.length) {
                              return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(dates[value.toInt()], style: TextStyle(color: AppColors.textSecondary, fontSize: 10), textAlign: TextAlign.center));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(value.toInt().toString(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.left);
                          },
                          interval: (maxY - minY) / 4,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: AppColors.secondaryColor, width: chartBorderWidth)),
                    minX: 0, maxX: dates.length - 1.toDouble(),
                    minY: minY, maxY: maxY,
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
class BandMetricsScreen extends StatelessWidget {
  final String bandId;
  const BandMetricsScreen({super.key, required this.bandId});

  // --- Widget para mostrar métricas individuales ---
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
            Text(
              value.toString(),
              style: const TextStyle(color: AppColors.textWhite, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('bands').doc(bandId).snapshots(),
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
                  future: _fetchTotalViews(bandId),
                  builder: (context, viewsSnapshot) {
                    final views = viewsSnapshot.data ?? 0;
                    return GridView.count(
                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16, mainAxisSpacing: 16,
                      children: [
                        _buildMetricCard('Vistas del Perfil', views, Icons.visibility),

                        // Métricas de Eventos (Interesados en toques)
                        FutureBuilder<int>(
                          future: _fetchInterestedInShows(bandId),
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

                // 3. 📈 GRÁFICO DE TENDENCIA (Implementación Real)
                BandGrowthChart(bandId: bandId),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
