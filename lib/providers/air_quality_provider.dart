import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import '../models/air_quality_model.dart';
import '../services/air_quality_service.dart';
import '../services/notification_service.dart'; 

class AirQualityProvider with ChangeNotifier {
  final AirQualityService _apiService = AirQualityService();

  AirQualityModel? _currentData;
  bool _isLoadingCurrent = false;

  List<AirQualityModel> _historyData = [];
  bool _isLoadingHistory = false;

  Map<String, dynamic>? _summaryData;
  bool _isLoadingSummary = false;

  String _errorMessage = '';
  String _currentAddress = "Mencari lokasi perangkat...";

  DateTime? _lastNotificationTime;

  // 🛠️ 1. VARIABEL GLOBAL UNTUK LONCENG DASHBOARD
  bool _isNotificationEnabled = true;
  bool get isNotificationEnabled => _isNotificationEnabled;

  AirQualityModel? get currentData => _currentData;
  bool get isLoadingCurrent => _isLoadingCurrent;
  List<AirQualityModel> get historyData => _historyData;
  bool get isLoadingHistory => _isLoadingHistory;
  Map<String, dynamic>? get summaryData => _summaryData;
  bool get isLoadingSummary => _isLoadingSummary;
  String get errorMessage => _errorMessage;
  String get currentAddress => _currentAddress;

  Timer? _realtimeTimer;

  Future<String?> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userIdInt = prefs.getInt('current_user_id'); 
    if (userIdInt != null) {
      return userIdInt.toString();
    }
    return null;
  }

  // 🛠️ 2. FUNGSI MEMBACA STATUS LONCENG SAAT APLIKASI DIBUKA
  Future<void> loadNotificationSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isNotificationEnabled = prefs.getBool('is_notification_enabled') ?? true;
    notifyListeners();
  }

  // 🛠️ 3. FUNGSI UNTUK MENGUBAH STATUS LONCENG (DIPANGGIL DARI DASHBOARD)
  Future<void> toggleNotification() async {
    _isNotificationEnabled = !_isNotificationEnabled;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_notification_enabled', _isNotificationEnabled);
    notifyListeners();
  }

  void startFetchingCurrentData() {
    _realtimeTimer?.cancel();
    loadCurrentData();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      loadCurrentData();
    });
  }

  Future<void> loadCurrentData() async {
    _errorMessage = '';
    if (_currentData == null) {
      _isLoadingCurrent = true;
      notifyListeners();
    }

    try {
      String? userId = await _getUserId();
      if (userId == null) {
        throw Exception("Sesi telah habis. Silakan login ulang.");
      }

      final newData = await _apiService.fetchCurrentData(userId);
      
      if (_currentData?.latitude != newData.latitude || _currentData?.longitude != newData.longitude) {
        if (newData.latitude != null && newData.longitude != null) {
          _convertToAddress(newData.latitude!, newData.longitude!);
        }
      }
      
      _currentData = newData;

      _checkAndTriggerNotification(userId);

    } catch (e) {
      _errorMessage = e.toString();
      _currentAddress = "Gagal mengambil data dari perangkat";
    } finally {
      _isLoadingCurrent = false;
      notifyListeners();
    }
  }

  Future<void> _checkAndTriggerNotification(String userId) async {
    try {
      // 🛠️ 4. BACA LANGSUNG DARI VARIABEL PROVIDER
      if (!_isNotificationEnabled) return; 

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String interval = prefs.getString('alert_frequency') ?? 'first_time';

      final alertData = await _apiService.checkAlertStatus(userId, interval);
      bool shouldTrigger = alertData['trigger_notification'] ?? false;

      if (shouldTrigger) {
        final now = DateTime.now();
        
        if (_lastNotificationTime == null || now.difference(_lastNotificationTime!).inMinutes >= 5) {
          
          String waktuTeks = "Saat Ini";
          if (interval == '30_min') waktuTeks = "30 Menit Terakhir";
          if (interval == '1_hour') waktuTeks = "1 Jam Terakhir";

          NotificationService.showWarningNotification(
            title: '⚠️ AWAS! Risiko Iritasi Mata BURUK',
            body: 'Rata-rata kualitas udara $waktuTeks terdeteksi buruk. Segera gunakan pelindung mata!',
          );
          
          _lastNotificationTime = now; 
        }
      }
    } catch (e) {
      debugPrint("Info Alert: $e");
    }
  }

  Future<void> _convertToAddress(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = "${place.street}, ${place.subLocality}, ${place.locality}";
      } else {
        _currentAddress = "Alamat tidak ditemukan";
      }
    } catch (e) {
      _currentAddress = "Lat: $lat, Lon: $lon";
    }
    notifyListeners(); 
  }

  Future<void> loadHistoricalData(String range) async {
    _isLoadingHistory = true;
    _errorMessage = '';
    notifyListeners();
    try {
      String? userId = await _getUserId();
      if (userId == null) throw Exception("Sesi habis.");
      _historyData = await _apiService.fetchHistoricalData(userId, range);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadSummaryData() async {
    _isLoadingSummary = true;
    _errorMessage = '';
    notifyListeners();
    try {
      String? userId = await _getUserId();
      if (userId == null) throw Exception("Sesi habis.");
      _summaryData = await _apiService.fetchSummaryData(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }
}