import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../main.dart'; // 🛠️ WAJIB DITAMBAHKAN: Untuk membaca status tema saat ini
import 'main_navigation.dart'; // 🛠️ WAJIB DITAMBAHKAN: Untuk rute ke Dashboard Utama

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    facing: CameraFacing.back,
  );
  final AuthService _authService = AuthService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  // =========================================================
  // FUNGSI 1: EKSEKUSI API KE VPS (SUDAH DIPERBAIKI BUG BLACK SCREEN)
  // =========================================================
  Future<void> _executeBindingApi(String deviceId, {String? ssid, String? pass}) async {
    // 1. Ambil KTP user
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('current_user_id');

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sesi tidak valid, silakan login ulang"), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Menghubungkan alat $deviceId ke akun Anda..."), duration: const Duration(seconds: 1)),
      );
    }

    // 2. Tembak API VPS (Kirim semua paket datanya: ID, SSID, Pass)
    final result = await _authService.bindDevice(
      userId, 
      deviceId, 
      ssid ?? '', 
      pass ?? ''
    );

    if (!mounted) return;

    // 3. Tangani Hasil
    if (result['status'] == 'success') {
      
      // 🛠️ SIMPAN KE MEMORI INDIVIDU (Untuk Auto-Login)
      await prefs.setBool('is_device_bound', true);
      await prefs.setString('device_id', deviceId);
      await prefs.setString('wifi_ssid', ssid ?? '');
      await prefs.setString('wifi_password', pass ?? '');

      // =======================================================
      // 🛠️ PERBAIKAN: SIMPAN JUGA KE 'saved_devices_list' UNTUK SETTINGS
      // =======================================================
      String? existingList = prefs.getString('saved_devices_list');
      List<dynamic> savedList = existingList != null ? jsonDecode(existingList) : [];
      
      Map<String, dynamic> newDevice = {
        'device': deviceId,
        'ssid': ssid ?? 'Tidak ada (Scan Manual)',
        'pass': pass ?? 'Tidak ada (Scan Manual)'
      };

      // Cek apakah alat sudah ada di list untuk mencegah duplikat
      bool exists = savedList.any((d) => d['device'] == deviceId);
      if (!exists) {
        savedList.add(newDevice);
        await prefs.setString('saved_devices_list', jsonEncode(savedList));
      }
      // =======================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      
      // 🛡️ OTAK NAVIGASI (SOLUSI BLACK SCREEN)
      if (Navigator.canPop(context)) {
        // KONDISI A: Dipanggil dari Settings (Ada layar di bawahnya) -> Kembali dan bawa data
        Navigator.pop(context, {
          'device': deviceId,
          'ssid': ssid ?? 'Tidak ada (Scan Manual)',
          'pass': pass ?? 'Tidak ada (Scan Manual)'
        }); 
      } else {
        // KONDISI B: Dipanggil dari Login (Berdiri sendiri) -> Lompat ke Dashboard Utama
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(
              isDarkMode: themeNotifier.value == ThemeMode.dark, 
              onToggleTheme: () {}, 
            ),
          ),
        );
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal menghubungkan alat'), backgroundColor: Colors.red),
      );
      // Nyalakan kamera lagi jika gagal
      _cameraController.start();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // =========================================================
  // FUNGSI 2: POP-UP KONFIRMASI (KHUSUS QR JSON)
  // =========================================================
  void _showDeviceActionDialog(String deviceId, String ssid, String password) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        title: const Text("Alat AERIS Ditemukan!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID Alat: $deviceId", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Siapkan Hotspot di HP Anda dengan data berikut agar alat bisa terhubung ke internet:"),
            const SizedBox(height: 8),
            Text("SSID: $ssid", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            Text("Sandi: $password", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              _cameraController.start(); // Nyalakan kamera lagi
              setState(() { _isProcessing = false; });
            },
            child: const Text("Batal", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              // Panggil eksekusi API dengan ID Alat yang sudah BERSIH
              _executeBindingApi(deviceId, ssid: ssid, pass: password);
            },
            child: const Text("Hubungkan & Daftarkan"),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FUNGSI 3: PEMBACA KAMERA UTAMA
  // =========================================================
  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessing) return; 

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() {
        _isProcessing = true;
      });

      String rawData = barcodes.first.rawValue!;
      
      // 🛑 REM DARURAT: Langsung matikan kamera agar tidak kesurupan (looping)
      await _cameraController.stop();

      try {
        // Coba bedah sebagai JSON
        Map<String, dynamic> qrData = jsonDecode(rawData);
        
        if (qrData.containsKey('device') && qrData.containsKey('ssid') && qrData.containsKey('pass')) {
          String deviceId = qrData['device'];
          String hotspotSsid = qrData['ssid'];
          String hotspotPass = qrData['pass'];

          // Tampilkan pop up, biarkan tombol di pop-up yang mengeksekusi API
          if (mounted) {
            _showDeviceActionDialog(deviceId, hotspotSsid, hotspotPass);
          }
          return; // Selesai.
        } else {
          throw const FormatException("Format JSON tidak sesuai standar AERIS");
        }
      } catch (e) {
        // --- JIKA BUKAN JSON (Atau JSON rusak) ---
        
        // 🛡️ CEGAH ERROR POSTGRESQL: Tolak jika teks > 50 karakter
        if (rawData.length > 50) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("QR Code salah! Data terlalu panjang."), backgroundColor: Colors.red),
            );
            // Beri jeda sedikit lalu nyalakan lagi
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _cameraController.start();
                setState(() { _isProcessing = false; });
              }
            });
          }
          return;
        }

        // Jika teks pendek (< 50 huruf), anggap ini QR Code teks biasa (Format lama)
        String scannedDeviceId = rawData;
        debugPrint("Scan terbaca sebagai teks biasa: $scannedDeviceId");
        
        // Langsung eksekusi API tanpa pop-up hotspot
        _executeBindingApi(scannedDeviceId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code Alat'),
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.bolt), 
            iconSize: 32.0,
            onPressed: () => _cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _handleScan,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
          if (!_isProcessing)
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          if (!_isProcessing)
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                "Arahkan kamera ke stiker QR Code di alat AERIS",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }
}