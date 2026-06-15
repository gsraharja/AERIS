import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart'; 

import 'theme/app_theme.dart'; 
import 'screens/main_navigation.dart';
import 'providers/air_quality_provider.dart'; 
import 'services/notification_service.dart';
import 'screens/login_screen.dart'; 
import 'services/air_quality_service.dart'; 

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// ======================================================================
// 🛠️ FUNGSI LATAR BELAKANG (BERJALAN WALAUPUN APLIKASI DITUTUP)
// ======================================================================
@pragma('vm:entry-point') 
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await NotificationService.initialize();
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      bool isNotificationEnabled = prefs.getBool('is_notification_enabled') ?? true;
      if (!isNotificationEnabled) return Future.value(true);

      int? userIdInt = prefs.getInt('current_user_id');
      if (userIdInt == null) return Future.value(true);
      String userId = userIdInt.toString();

      String interval = prefs.getString('alert_frequency') ?? 'first_time';

      final apiService = AirQualityService();
      final alertData = await apiService.checkAlertStatus(userId, interval);
      bool shouldTrigger = alertData['trigger_notification'] ?? false;

      if (shouldTrigger) {
        String waktuTeks = "Saat Ini";
        if (interval == '30_min') waktuTeks = "30 Menit Terakhir";
        if (interval == '1_hour') waktuTeks = "1 Jam Terakhir";

        await NotificationService.showWarningNotification(
          title: '⚠️ AWAS! Risiko Udara BURUK',
          body: 'Sistem latar belakang mendeteksi rata-rata $waktuTeks memburuk. Segera gunakan pelindung mata!',
        );
      }
    } catch (e) {
      debugPrint("Error Background Task: $e");
    }
    return Future.value(true);
  });
}

// ======================================================================
// FUNGSI UTAMA (APLIKASI SAAT DIBUKA)
// ======================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🛠️ 1. BACA MEMORI HP TERLEBIH DAHULU (Paling Aman dan Cepat)
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  bool isDarkMode = prefs.getBool('is_dark_mode') ?? false;
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // 🛠️ 2. INISIALISASI NOTIFIKASI DENGAN PELINDUNG (TRY-CATCH)
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint("🔴 [AERIS-TRACKER] Error Notifikasi: $e");
  }
  
  // 🛠️ 3. INISIALISASI WORKMANAGER DENGAN PELINDUNG (TRY-CATCH)
  try {
    Workmanager().initialize(
      callbackDispatcher,
    );

    Workmanager().registerPeriodicTask(
      "aeris_air_check_1", 
      "checkAirQualityBackground", 
      frequency: const Duration(minutes: 15), 
      constraints: Constraints(
        networkType: NetworkType.connected, 
      ),
    );
  } catch (e) {
    debugPrint("🔴 [AERIS-TRACKER] Error Workmanager: $e");
  }

  // 🛠️ 4. JALANKAN UI (Tidak akan terblokir lagi)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AirQualityProvider()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn), 
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AERIS',
          theme: AppTheme.lightTheme, 
          darkTheme: AppTheme.darkTheme, 
          themeMode: currentMode,
          home: isLoggedIn 
              ? MainNavigationScreen(
                  isDarkMode: currentMode == ThemeMode.dark,
                  onToggleTheme: () {},
                )
              : const LoginScreen(), 
        );
      },
    );
  }
}