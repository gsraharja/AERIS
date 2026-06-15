import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Ganti dengan IP VPS Ubuntu kamu
  static const String baseUrl = "https://aeris.cleanairiot.web.id/api"; 

  // Fungsi Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      // 🛠️ UBAH BAGIAN INI AGAR KITA BISA MELIHAT ERROR ASLINYA
      //print("🔴 [API ERROR] $e"); 
      return {'status': 'error', 'message': 'Error VPS: $e'}; 
    }
  }

  // Fungsi Register
  Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Gagal terhubung ke server VPS'};
    }
  }

  Future<Map<String, dynamic>> bindDevice(int userId, String deviceId, String ssid, String wifiPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bind-device'),
        headers: {'Content-Type': 'application/json'},
        // 🛠️ KIRIM SEMUA DATA KE VPS
        body: jsonEncode({
          'user_id': userId, 
          'device_id': deviceId,
          'ssid': ssid,
          'wifi_password': wifiPassword
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      //print("🔴 [API ERROR] $e");
      return {'status': 'error', 'message': 'Gagal terhubung ke server VPS: $e'};
    }
  }
}