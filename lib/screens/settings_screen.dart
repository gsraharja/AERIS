import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // 🛠️ TAMBAHAN IMPORT PROVIDER
import '../providers/air_quality_provider.dart'; // 🛠️ TAMBAHAN IMPORT PROVIDER
import 'login_screen.dart';
import 'qr_scanner_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  const SettingsScreen({super.key, required this.isDarkMode});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- STATE VARIABLES ---
  String _currentUsername = "Memuat...";
  String _alertFrequency = 'first_time'; 
  bool _isVibrateOnly = false;
  
  List<Map<String, dynamic>> _savedDevices = [];
  Map<String, dynamic>? _selectedDevice;

  // 🗑️ Variabel dummy _deviceStatus dan _lastDataTime DIHAPUS karena kita akan pakai data asli

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUsername = prefs.getString('current_username') ?? "User AERIS";
      _alertFrequency = prefs.getString('alert_frequency') ?? 'first_time';
      _isVibrateOnly = prefs.getBool('is_vibrate_only') ?? false;

      String? devicesJson = prefs.getString('saved_devices_list');
      if (devicesJson != null) {
        List<dynamic> decoded = jsonDecode(devicesJson);
        _savedDevices = decoded.map((e) => e as Map<String, dynamic>).toList();
        
        if (_savedDevices.isNotEmpty) {
          _selectedDevice = _savedDevices.first;
        }
      } else {
        _savedDevices = [];
        _selectedDevice = null;
      }
    });
  }

  Future<void> _saveDevicesList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_devices_list', jsonEncode(_savedDevices));
  }

  void _copyToClipboard(String title, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title berhasil disalin!"), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==========================================
          // 1. PROFIL USER 
          // ==========================================
          ListTile(
            contentPadding: EdgeInsets.zero, 
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primary, 
              child: Text(
                _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : "?",
                style: TextStyle(color: theme.cardColor, fontSize: 24, fontWeight: FontWeight.bold),
              ), 
            ),
            title: Text(_currentUsername, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: Icon(Icons.logout, color: colorScheme.error), 
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_logged_in', false);
                await prefs.remove('current_user_id');
                await prefs.remove('current_username');
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false, 
                );
              },
            ),
          ),
          
          Divider(height: 30, color: colorScheme.primary.withValues(alpha:0.2)),

          // ==========================================
          // 2. PENGATURAN ALAT (DEVICE)
          // ==========================================
          Text("Manajemen Perangkat", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:widget.isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_savedDevices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text("Belum ada alat yang terhubung. Silakan scan QR Code alat baru.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  )
                else
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: _selectedDevice,
                    decoration: InputDecoration(
                      labelText: "Pilih ID Alat",
                      labelStyle: TextStyle(color: colorScheme.secondary),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary.withValues(alpha:0.5))),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                    ),
                    items: _savedDevices.map((device) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: device,
                        child: Text(device['device'] ?? 'Unknown Device'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() { 
                        _selectedDevice = value; 
                      });
                    },
                  ),
                
                if (_selectedDevice != null && _selectedDevice!.containsKey('ssid')) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.primary.withValues(alpha:0.3))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("WIFI HOTSPOT SETUP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        const Text("Buat hotspot di HP Anda dengan data berikut agar alat bisa terhubung ke internet:", style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text("Nama WiFi (SSID):", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(_selectedDevice!['ssid'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ]),
                            IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: () => _copyToClipboard("SSID", _selectedDevice!['ssid'])),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text("Kata Sandi (Password):", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(_selectedDevice!['pass'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ]),
                            IconButton(icon: const Icon(Icons.copy, size: 20), onPressed: () => _copyToClipboard("Password", _selectedDevice!['pass'])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ==========================================
                // 🛠️ LOGIKA REAL-TIME STATUS & WAKTU (MENGGUNAKAN PROVIDER)
                // ==========================================
                Consumer<AirQualityProvider>(
                  builder: (context, provider, child) {
                    final data = provider.currentData;
                    
                    String statusText = "OFFLINE";
                    Color statusColor = colorScheme.error;
                    String lastDataTimeText = "Tidak ada data";

                    if (data != null && data.time != null) {
                      try {
                        // Ubah string waktu dari InfluxDB (UTC) menjadi jam lokal HP
                        DateTime parsedTime = data.time!.toLocal();
                        
                        // Hitung selisih waktu masuknya data dengan jam saat ini
                        final diff = DateTime.now().difference(parsedTime);
                        
                        // JIKA DATA USIANYA LEBIH DARI 5 MENIT -> ANGGAP OFFLINE/MATI
                        if (diff.inMinutes > 5) {
                          statusText = "OFFLINE";
                          statusColor = Colors.orange;
                        } else {
                          statusText = "ONLINE";
                          statusColor = Colors.green;
                        }

                        // Format waktu menjadi (DD/MM/YYYY, HH:MM WIB)
                        String day = parsedTime.day.toString().padLeft(2, '0');
                        String month = parsedTime.month.toString().padLeft(2, '0');
                        String year = parsedTime.year.toString();
                        String hour = parsedTime.hour.toString().padLeft(2, '0');
                        String minute = parsedTime.minute.toString().padLeft(2, '0');
                        
                        lastDataTimeText = "$day/$month/$year, $hour:$minute WIB";
                      } catch (e) {
                        lastDataTimeText = "Format waktu salah";
                      }
                    }

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Status Alat:"),
                            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Data Terakhir:"),
                            Text(lastDataTimeText, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.7))),
                          ],
                        ),
                      ],
                    );
                  }
                ),

                const SizedBox(height: 24), 
                
                SizedBox(
                  width: double.infinity, 
                  height: 45,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary, 
                      side: BorderSide(color: colorScheme.primary), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("Tambah Alat Baru (Scan QR)", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final newDeviceData = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                      );

                      if (newDeviceData != null && newDeviceData is Map<String, dynamic>) {
                        setState(() {
                          bool exists = _savedDevices.any((d) => d['device'] == newDeviceData['device']);
                          if (!exists) {
                            _savedDevices.add(newDeviceData);
                            _selectedDevice = newDeviceData;
                            _saveDevicesList();
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ==========================================
          // 3. PENGATURAN NOTIFIKASI 
          // ==========================================
          Text("Preferensi Notifikasi", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:widget.isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _alertFrequency,
                  decoration: InputDecoration(
                    labelText: "Interval Peringatan Udara Buruk",
                    labelStyle: TextStyle(color: colorScheme.secondary),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary.withValues(alpha:0.5))),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'first_time', child: Text("Hanya Saat Udara Buruk")),
                    DropdownMenuItem(value: '30_min', child: Text("Ingatkan setiap 30 Menit")),
                    DropdownMenuItem(value: '1_hour', child: Text("Ingatkan setiap 1 Jam")),
                  ],
                  onChanged: (value) async {
                    setState(() { _alertFrequency = value!; });
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString('alert_frequency', value!);
                  },
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero, 
                  title: Text("Hanya Getar", style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text("Matikan suara ringtone peringatan", style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.7))),
                  value: _isVibrateOnly,
                  onChanged: (bool value) async {
                    setState(() { _isVibrateOnly = value; });
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('is_vibrate_only', value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}