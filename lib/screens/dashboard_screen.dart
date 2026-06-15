import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/air_quality_provider.dart';
import 'map_screen.dart';
import '../widgets/sensor_card.dart';
import '../widgets/status_banner.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:earis/main.dart';

class DashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const DashboardScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isMqVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AirQualityProvider>(context, listen: false);
      provider.loadNotificationSettings(); 
      provider.startFetchingCurrentData();
    });
  }

  Color _getSensorColor(String sensorType, double? value) {
    if (value == null) return Colors.grey;
    
    switch (sensorType) {
      case "PM2.5": 
        if (value < 15.5) return Colors.green;        // Aman
        if (value < 55.4) return Colors.blue;        // Sedang
        if (value < 150.4) return Colors.orange;      // Berisiko Tinggi
        return Colors.red;                            // Berbahaya
      case "NO2": 
        if (value < 25.0) return Colors.green;        // Aman
        if (value < 100.0) return Colors.blue;       // Sedang
        if (value < 200.0) return Colors.orange;      // Berisiko Tinggi
        return Colors.red;                            // Berbahaya
      case "Suhu": 
        if (value < 30.0) return Colors.green;
        if (value < 35.0) return Colors.blue;
        if (value < 40.0) return Colors.orange;
        return Colors.red;
      case "Kelembapan":
        if (value >= 40.0 && value <= 60.0) return Colors.green;
        if (value >= 30.0 && value <= 75.0) return Colors.blue;
        return Colors.orange;
      case "VOC":
        if (value < 300.0) return Colors.green;       // Aman
        if (value < 660.0) return Colors.blue;       // Sedang (Transisi ASHRAE)
        if (value < 1000.0) return Colors.orange;     // Berisiko Tinggi
        return Colors.red;                            // Berbahaya
      default:
        return Colors.green;
    }
  }

  String _formatSensorValue(double? value, bool isOffline) {
    if (isOffline || value == null) return "--"; 
    
    if (value >= 1000) {
      return value.toStringAsFixed(0);
    } else if (value >= 10) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Color liveColor = widget.isDarkMode ? Colors.greenAccent : const Color.fromARGB(255, 43, 150, 50);

    // 🛠️ TAMBAHAN: Rumus menghitung ukuran kartu agar presisi sama dengan GridView
    final screenWidth = MediaQuery.of(context).size.width;
    // Lebar layar dikurangi padding kiri-kanan (32) dan spasi tengah grid (14), lalu dibagi 2
    final cardWidth = (screenWidth - 32 - 14) / 2; 
    // Tinggi kartu = lebar dibagi childAspectRatio (1.5)
    final cardHeight = cardWidth / 1.5;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Consumer<AirQualityProvider>(
          builder: (context, provider, child) {
            final data = provider.currentData;
            bool isLive = false;

            if (data != null && data.time != null && !provider.isLoadingCurrent) {
              DateTime parsedTime = data.time!.toLocal();
              if (DateTime.now().difference(parsedTime).inMinutes <= 5) {
                isLive = true;
              }
            }

            return Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: isLive ? liveColor : colorScheme.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isLive ? liveColor.withValues(alpha:0.7) : colorScheme.error.withValues(alpha:0.7),
                        blurRadius: 10, spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text("AERIS", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Text(
                  isLive ? "LIVE" : "OFFLINE",
                  style: TextStyle(fontSize: 12, color: isLive ? liveColor : colorScheme.error, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final provider = Provider.of<AirQualityProvider>(context, listen: false);
              
              await provider.toggleNotification();

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).clearSnackBars(); 
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.isNotificationEnabled ? "Notifikasi diaktifkan" : "Notifikasi dimatikan"),
                  duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating, 
                ),
              );
            },
            icon: Consumer<AirQualityProvider>(
              builder: (context, provider, child) {
                return Icon(
                  provider.isNotificationEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: provider.isNotificationEnabled ? colorScheme.secondary : theme.iconTheme.color?.withValues(alpha:0.5), 
                );
              }
            ),
          ),
          // 🛠️ PERBAIKAN TOMBOL TEMA UNTUK MENYIMPAN KE MEMORI
          IconButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              
              if (themeNotifier.value == ThemeMode.light) {
                themeNotifier.value = ThemeMode.dark;
                await prefs.setBool('is_dark_mode', true);
              } else {
                themeNotifier.value = ThemeMode.light;
                await prefs.setBool('is_dark_mode', false);
              }
            },
            icon: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, child) {
                return Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode);
              }
            ),
          ),
          const SizedBox(width: 4), 
        ],
      ),
      
      body: Consumer<AirQualityProvider>(
        builder: (context, provider, child) {
          final data = provider.currentData;
          bool isOffline = true;

          if (data != null && data.time != null) {
            DateTime parsedTime = data.time!.toLocal();
            if (DateTime.now().difference(parsedTime).inMinutes <= 5) {
              isOffline = false;
            }
          }

          String statusText = "OFFLINE";
          Color bannerColor = Colors.grey;
          Color scoreBoxColor = Colors.grey.shade400;

          if (!isOffline) {
            int? predCode = data?.mlpredictionCode;
            if (predCode == 0) {
              statusText = "AMAN";
              bannerColor = Colors.green;
              scoreBoxColor = Colors.green.shade400; 
            } else if (predCode == 1) {
              statusText = "SEDANG";
              bannerColor = Colors.blue; // Kuning/Amber untuk Sedang
              scoreBoxColor = Colors.blue.shade400; 
            } else if (predCode == 2) {
              statusText = "BERISIKO TINGGI"; 
              bannerColor = Colors.orange; // Oranye untuk Berisiko Tinggi
              scoreBoxColor = Colors.orange.shade400; 
            } else if (predCode == 3) {
              statusText = "BERBAHAYA"; 
              bannerColor = Colors.red; // Merah untuk kondisi Berbahaya
              scoreBoxColor = Colors.red.shade400;
            }
          }

          String pm25Val = _formatSensorValue(data?.pm25Filtered, isOffline);
          String no2Val = _formatSensorValue(data?.no2Ugm3, isOffline);
          String suhuVal = _formatSensorValue(data?.suhuCompensated, isOffline);
          String humVal = _formatSensorValue(data?.kelembabanCompensated, isOffline);
          String vocVal = _formatSensorValue(data?.tvocugm3, isOffline);
          
          String riskScoreVal = isOffline ? "--" : data!.irritationRiskScore?.toStringAsFixed(1) ?? "--";
          String confidenceVal = isOffline ? "--" : data!.mlConfidence?.toStringAsFixed(1) ?? "--";

          double lat = isOffline ? -7.747033 : (data!.latitude ?? -7.747033);
          double lon = isOffline ? 110.355398 : (data!.longitude ?? 110.355398);

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadCurrentData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBanner(
                      statusText: statusText,
                      score: riskScoreVal,
                      confidence: confidenceVal,
                      bannerColor: bannerColor,
                      scoreBoxColor: scoreBoxColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Monitoring Sensor",
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.5,
                      ),
                      children: [
                        SensorCard(
                          title: "PM2.5", value: pm25Val, unit: "µg/m³", icon: Icons.cloud,
                          statusColor: isOffline ? Colors.grey : _getSensorColor("PM2.5", data?.pm25Filtered),
                        ),
                        SensorCard(
                          title: "NO₂", value: no2Val, unit: "µg/m³", icon: Icons.air,
                          statusColor: isOffline ? Colors.grey : _getSensorColor("NO2", data?.no2Ugm3),
                        ),
                        SensorCard(
                          title: "Suhu", value: suhuVal, unit: "°C", icon: Icons.thermostat,
                          statusColor: isOffline ? Colors.grey : _getSensorColor("Suhu", data?.suhuCompensated),
                        ),
                        SensorCard(
                          title: "Kelembapan", value: humVal, unit: "%", icon: Icons.water_drop,
                          statusColor: isOffline ? Colors.grey : _getSensorColor("Kelembapan", data?.kelembabanCompensated),
                        ),
                      ],
                    ),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter, 
                      child: SizedBox(
                        width: double.infinity, 
                        child: _isMqVisible
                            ? Column(
                                children: [
                                  const SizedBox(height: 14), 
                                  Center(
                                    child: SizedBox(
                                      // 🛠️ UBAH KEDUA BARIS INI
                                      width: cardWidth,
                                      height: cardHeight,
                                      child: SensorCard(
                                        title: "VOC", value: vocVal, unit: "µg/m³", icon: Icons.local_fire_department_sharp,
                                        statusColor: isOffline ? Colors.grey : _getSensorColor("VOC", data?.tvocugm3),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),

                    Center(
                      child: GestureDetector(
                        onTap: () { setState(() { _isMqVisible = !_isMqVisible; }); },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Icon(
                            _isMqVisible ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 34, color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.7),
                          ),
                        ),
                      ),
                    ),

                    Text("Lokasi Perangkat", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(latitude: lat, longitude: lon),
                          ),
                        );
                      },
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias, 
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: theme.cardColor,   
                        ),
                        child: Stack(
                          children: [
                            isOffline
                                ? Center(child: Icon(Icons.map_rounded, size: 80, color: colorScheme.secondary))
                                : IgnorePointer(
                                    child: FlutterMap(
                                      options: MapOptions(
                                        initialCenter: LatLng(lat, lon),
                                        initialZoom: 14.5,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName: 'com.example.aeris',
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: LatLng(lat, lon),
                                              width: 40, height: 40,
                                              child: Icon(Icons.location_on, color: colorScheme.error, size: 35),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                            Positioned(
                              left: 0, right: 0, bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      theme.cardColor,
                                      theme.cardColor.withValues(alpha: 0.85),
                                      theme.cardColor.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Lokasi Device",
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isOffline ? "Menunggu data GPS dari perangkat..." : provider.currentAddress,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis, 
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}