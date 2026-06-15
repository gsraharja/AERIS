import 'dart:math'; // 🛠️ TAMBAHAN: Untuk fungsi hitung matematika (min/max)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/air_quality_provider.dart';
import '../models/air_quality_model.dart';

class GraphScreen extends StatefulWidget {
  final bool isDarkMode;
  const GraphScreen({super.key, required this.isDarkMode});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  String _selectedSensor = "Score Iritasi";
  String _selectedRange = "24h"; 

  final List<String> _sensorTabs = [
    "Score Iritasi", "PM2.5", "NO2", "Suhu", "Kelembapan", "VOC"
  ];

  final Map<String, String> _timeFilters = {
    "1 Jam": "1h",
    "24 Jam": "24h",
    "7 Hari": "7d",
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AirQualityProvider>(context, listen: false);
      provider.loadSummaryData();
      provider.loadHistoricalData(_selectedRange); 
    });
  }

  Color _getStatusColor(String? status) {
    if (status == "AMAN") return Colors.green; 
    if (status == "SEDANG") return Colors.blue; 
    if (status == "BURUK") return Colors.orange; 
    if (status == "BERBAHAYA") return Colors.red; 
    return Colors.grey;
  }

  double _getYValue(AirQualityModel data) {
    switch (_selectedSensor) {
      case "Score Iritasi": return data.irritationRiskScore ?? 0.0; 
      case "PM2.5": return data.pm25Filtered ?? 0.0;
      case "NO2": return data.no2Ugm3 ?? 0.0;
      case "Suhu": return data.suhuCompensated ?? 0.0;
      case "Kelembapan": return data.kelembabanCompensated ?? 0.0;
      case "VOC": return data.tvocugm3 ?? 0.0;
      default: return 0.0;
    }
  }

  // ========================================================
  // 🛠️ LOGIKA BARU: MEMAKSA GRAFIK MENGHORMATI GARIS THRESHOLD
  // ========================================================
  double _getMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    double minData = spots.map((s) => s.y).reduce(min);
    
    switch (_selectedSensor) {
      case "Suhu": return min(minData - 2, 25); // Paksa sumbu Y turun ke 25 agar garis 30 terlihat
      case "Kelembapan": return min(minData - 5, 20); // Paksa turun ke 20 agar garis 40 terlihat
      default: return 0; // Sensor polusi (PM2.5, NO2, VOC, Score) selalu mulai dari 0
    }
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    double maxData = spots.map((s) => s.y).reduce(max);
    
    switch (_selectedSensor) {
      // 🛠️ UBAH DISINI: Paksa minimal tinggi grafik 250 agar garis batas 200 selalu terlihat
      case "Score Iritasi": return max(maxData + 10, 250); 
      case "PM2.5": return max(maxData + 5, 200);
      case "NO2": return max(maxData + 5, 250);
      case "Suhu": return max(maxData + 2, 40);
      case "Kelembapan": return max(maxData + 5, 100);
      case "VOC": return max(maxData + 100, 2500);
      default: return maxData + 10;
    }
  }

  List<HorizontalLine> _getThresholdLines(ColorScheme colorScheme) {
    final Color blueLine = Colors.blue.withValues(alpha: 0.8);
    final Color orangeLine = Colors.orange.withValues(alpha: 0.8);
    final Color redLine = Colors.red.withValues(alpha: 0.8);

    const textStyle = TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey);

    switch (_selectedSensor) {
      case "Score Iritasi":
        return [
          HorizontalLine(y: 50.0, color: blueLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Sedang (50)", style: textStyle)),
          HorizontalLine(y: 100.0, color: orangeLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Berisiko Tinggi (100)", style: textStyle)),
          HorizontalLine(y: 200.0, color: redLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Berbahaya (200)", style: textStyle)),
        ];
      case "PM2.5":
        return [
          HorizontalLine(y: 15.0, color: blueLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Sedang (15)", style: textStyle)),
          HorizontalLine(y: 55.0, color: orangeLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Berisiko Tinggi (55)", style: textStyle)),
          HorizontalLine(y: 150.0, color: redLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Berbahaya (150)", style: textStyle)),
        ];
      case "NO2":
        return [
          HorizontalLine(y: 25.0, color: blueLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Sedang (25)", style: textStyle)),
          HorizontalLine(y: 100.0, color: orangeLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Berisiko Tinggi (100)", style: textStyle)),
          HorizontalLine(y: 200.0, color: redLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Berbahaya (200)", style: textStyle)),
        ];
      case "Suhu":
        return [
          HorizontalLine(y: 30.0, color: blueLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Sedang (30°C)", style: textStyle)),
          HorizontalLine(y: 35.0, color: orangeLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Berisiko Tinggi (35°C)", style: textStyle)),
        ];
      case "Kelembapan":
        return [
          HorizontalLine(y: 40.0, color: orangeLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Batas Bawah (40%)", style: textStyle)),
          HorizontalLine(y: 60.0, color: orangeLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Batas Atas (60%)", style: textStyle)),
        ];
      case "VOC":
        return [
          HorizontalLine(y: 220.0, color: blueLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Sedang (220)", style: textStyle)),
          HorizontalLine(y: 660.0, color: orangeLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Berisiko Tinggi (660)", style: textStyle)),
          HorizontalLine(y: 2200.0, color: redLine, strokeWidth: 1.5, dashArray: [6, 4], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, labelResolver: (_) => "Berbahaya (2200)", style: textStyle)),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Statistik Sensor")),
      body: RefreshIndicator(
        onRefresh: () async {
          final provider = Provider.of<AirQualityProvider>(context, listen: false);
          await Future.wait([
            provider.loadSummaryData(),
            provider.loadHistoricalData(_selectedRange),
          ]);
        },
        child: Consumer<AirQualityProvider>(
          builder: (context, provider, child) {
            final summary = provider.summaryData;
            final score1Day = summary?['average_1_day']?['score']?.toString() ?? "--";
            final status1Day = summary?['average_1_day']?['status'] as String?;
            final score1Week = summary?['average_1_week']?['score']?.toString() ?? "--";
            final status1Week = summary?['average_1_week']?['status'] as String?;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(), 
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context, 
                        "Score Hari Ini", 
                        provider.isLoadingSummary ? "..." : score1Day, 
                        _getStatusColor(status1Day)
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        context, 
                        "Score Minggu Ini", 
                        provider.isLoadingSummary ? "..." : score1Week, 
                        _getStatusColor(status1Week)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pilih Data Grafik",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRange,
                          icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                          items: _timeFilters.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.value,
                              child: Text(entry.key),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null && newValue != _selectedRange) {
                              setState(() {
                                _selectedRange = newValue;
                              });
                              provider.loadHistoricalData(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sensorTabs.map((sensor) {
                      bool isSelected = _selectedSensor == sensor;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(sensor),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() { _selectedSensor = sensor; });
                            }
                          },
                          selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                          backgroundColor: theme.cardColor,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colorScheme.secondary
                                : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  height: 350, 
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildChartArea(provider, colorScheme),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChartArea(AirQualityProvider provider, ColorScheme colorScheme) {
    if (provider.isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage.isNotEmpty) {
      return Center(child: Text("Eror: ${provider.errorMessage}", textAlign: TextAlign.center));
    }

    if (provider.historyData.isEmpty) {
      return const Center(child: Text("Belum ada data grafik di database."));
    }

    final history = provider.historyData;
    
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), _getYValue(history[i])));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Grafik $_selectedSensor",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: LineChart(
            LineChartData(
              // 🛠️ SETTING MIN/MAX AGAR GARIS TIDAK TERPOTONG
              minY: _getMinY(spots),
              maxY: _getMaxY(spots),
              extraLinesData: ExtraLinesData(
                horizontalLines: _getThresholdLines(colorScheme),
              ),
              gridData: FlGridData(
                show: true, 
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1, 
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      
                      int step = (history.length / 5).ceil();
                      if (step == 0) step = 1;

                      if (index >= 0 && index < history.length && index % step == 0) {
                        final time = history[index].time;
                        if (time != null) {
                          String labelText = "";
                          if (_selectedRange == "7d") {
                            labelText = "${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}";
                          } else {
                            labelText = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labelText, 
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.secondary.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                              )
                            ),
                          );
                        }
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45, 
                    getTitlesWidget: (value, meta) {
                      String valText;
                      if (value >= 1000) {
                        valText = value.toStringAsFixed(0);
                      } else {
                        valText = value.toStringAsFixed(1);
                      }
                      return Text(valText, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, Color statusColor) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(bottom: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}