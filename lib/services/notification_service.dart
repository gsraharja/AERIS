import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/launcher_icon');
        
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(initSettings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showWarningNotification({
    required String title,
    required String body,
  }) async {
    // 🛠️ 1. BACA STATUS TOMBOL "HANYA GETAR" DARI MEMORI
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isVibrateOnly = prefs.getBool('is_vibrate_only') ?? false;

    // 🛠️ 2. PERSIAPKAN DUA JALUR (CHANNEL) YANG BERBEDA
    AndroidNotificationDetails androidDetails;

    if (isVibrateOnly) {
      // JALUR 1: HANYA GETAR (Tanpa Suara)
      androidDetails = const AndroidNotificationDetails(
        'air_quality_alert_vibrate', // ID Khusus Getar
        'Peringatan (Hanya Getar)', 
        channelDescription: 'Notifikasi peringatan tanpa suara ringtone',
        importance: Importance.max, 
        priority: Priority.high,
        enableVibration: true,
        playSound: false, // MATIKAN SUARA
      );
    } else {
      // JALUR 2: BERSUARA (Ringtone Default HP)
      androidDetails = const AndroidNotificationDetails(
        'air_quality_alert_sound_v2', // 🛠️ UBAH JADI v2 DI SINI
        'Peringatan Udara Buruk', // Ganti nama agar terlihat beda di pengaturan HP
        channelDescription: 'Notifikasi dengan alarm suara',
        importance: Importance.max, 
        priority: Priority.high,
        enableVibration: true,
        playSound: true, // NYALAKAN SUARA
      );
    }

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    // 🛠️ 3. TEMBAKKAN NOTIFIKASI
    await _notificationsPlugin.show(
      0, 
      title,
      body,
      platformDetails,
    );
  }
}