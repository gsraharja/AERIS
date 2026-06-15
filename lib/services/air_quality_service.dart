import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality_model.dart';

class AirQualityService {
  final String baseUrl = "https://aeris.cleanairiot.web.id/api/air-quality";

  // 🛡️ Header Keamanan untuk melewati hadangan Cloudflare & Nginx
  final Map<String, String> customHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
  };

  // 1. Fetch Data Real-Time
  // 🛠️ UBAH: Menerima userId dari Provider
  Future<AirQualityModel> fetchCurrentData(String userId) async {
    try {
      // 🛠️ UBAH: Sisipkan ?user_id=$userId ke URL
      final response = await http.get(Uri.parse('$baseUrl/current?user_id=$userId'), headers: customHeaders);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        return AirQualityModel.fromJson(decodedData['data']);
      } else {
        throw Exception('Gagal memuat data (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Eror data terbaru: $e');
    }
  }

  // 2. Fetch Data Histori (Grafik)
  // 🛠️ UBAH: Menerima userId dari Provider
  Future<List<AirQualityModel>> fetchHistoricalData(String userId, String range) async {
    try {
      // 🛠️ UBAH: Sisipkan &user_id=$userId ke URL (karena sudah pakai ?range=)
      final response = await http.get(Uri.parse('$baseUrl/history?range=$range&user_id=$userId'), headers: customHeaders);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> rawDataList = decodedData['data'];
        return rawDataList.map((item) => AirQualityModel.fromJson(item)).toList();
      } else {
        throw Exception('Gagal memuat grafik (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Eror data grafik: $e');
    }
  }

  // 3. Fetch Data Summary (Rata-rata Score)
  // 🛠️ UBAH: Menerima userId dari Provider
  Future<Map<String, dynamic>> fetchSummaryData(String userId) async {
    try {
      // 🛠️ UBAH: Sisipkan ?user_id=$userId ke URL
      final response = await http.get(Uri.parse('$baseUrl/summary?user_id=$userId'), headers: customHeaders);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        return decodedData['data'];
      } else {
        throw Exception('Gagal memuat ringkasan (Status: ${response.statusCode})');
      }
    } catch (e) {
      // Re-throw langsung pesannya agar mudah di-debug di layar
      throw Exception(e.toString());
    }
  }
  
  Future<Map<String, dynamic>> checkAlertStatus(String userId, String interval) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check-alert?user_id=$userId&interval=$interval'), 
        headers: customHeaders
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal memuat status peringatan (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Eror cek alert: $e');
    }
  }
}