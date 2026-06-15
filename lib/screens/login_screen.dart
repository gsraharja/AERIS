import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart'; 
import 'register_screen.dart';
import 'qr_scanner_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Variabel untuk menyimpan daftar akun yang pernah login
  List<String> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  // 🛠️ FUNGSI MEMBACA HISTORI AKUN
  Future<void> _loadSavedAccounts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedAccounts = prefs.getStringList('saved_accounts') ?? [];
    });
  }

  // 🛠️ FUNGSI MENYIMPAN SESI & HISTORI SAAT LOGIN SUKSES
  Future<void> _saveSession(String username, int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // 1. Simpan sesi aktif
    await prefs.setBool('is_logged_in', true);
    await prefs.setInt('current_user_id', userId);
    await prefs.setString('current_username', username);

    // 2. Simpan histori akun (Account Chooser)
    List<String> accounts = prefs.getStringList('saved_accounts') ?? [];
    if (!accounts.contains(username)) {
      accounts.add(username);
      await prefs.setStringList('saved_accounts', accounts);
    }
  }

  // 🛠️ FUNGSI LOGIN DENGAN LOGIKA BYPASS ALAT BARU
  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String inputUsername = _usernameController.text.trim();
      final result = await _authService.login(inputUsername, _passwordController.text);

      setState(() => _isLoading = false);
      if (!mounted) return;

      if (result['status'] == 'success') {
        int userId = result['user_id'];
        bool hasDevice = result['has_device'] ?? false; // Cek apakah sudah punya alat
        
        // 1. Panggil fungsi simpan sesi user
        await _saveSession(inputUsername, userId);

        // 2. Simpan data alat ke memori jika akun ini sudah punya alat
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (hasDevice) {
          await prefs.setBool('is_device_bound', true); // Penanda bypass QR
          
          String dId = result['device_id'] ?? '';
          String dSsid = result['ssid'] ?? '';
          String dPass = result['wifi_password'] ?? '';

          await prefs.setString('device_id', dId);
          await prefs.setString('wifi_ssid', dSsid);
          await prefs.setString('wifi_password', dPass);

          // =======================================================
          // 🛠️ PERBAIKAN: SIMPAN JUGA KE 'saved_devices_list' UNTUK SETTINGS
          // =======================================================
          String? existingList = prefs.getString('saved_devices_list');
          List<dynamic> savedList = existingList != null ? jsonDecode(existingList) : [];
          
          bool exists = savedList.any((d) => d['device'] == dId);
          if (!exists) {
            savedList.add({
              'device': dId, 
              'ssid': dSsid, 
              'pass': dPass
            });
            await prefs.setString('saved_devices_list', jsonEncode(savedList));
          }
          // =======================================================
        }

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Berhasil!"), backgroundColor: Colors.green),
        );

        // 3. LOGIKA NAVIGASI (DASHBOARD VS SCANNER)
        if (hasDevice) {
          // Jika sudah punya alat, langsung ke Dashboard Utama
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(
                isDarkMode: false, 
                onToggleTheme: () {}, 
              ),
            ),
          );
        } else {
          // Jika pengguna baru / belum punya alat, lempar ke Scanner QR
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const QRScannerScreen(), 
            ),
          );
        }

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login Gagal'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4), 
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1F8EF), 
                        borderRadius: BorderRadius.circular(12), 
                      ),
                      child: Image.asset(
                        'assets/images/app1_logo.png',
                        height: 100, 
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // 🛠️ TAMPILAN ACCOUNT CHOOSER
                  if (_savedAccounts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text("Akun Tersimpan:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: _savedAccounts.map((accountName) {
                        return ActionChip(
                          avatar: const Icon(Icons.account_circle, color: Colors.blue),
                          label: Text(accountName),
                          onPressed: () {
                            setState(() {
                              _usernameController.text = accountName;
                              _passwordController.clear(); 
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    const SizedBox(height: 32),
                  ],

                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Username tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value!.isEmpty ? 'Password tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                    },
                    child: const Text("Belum punya akun? Daftar di sini"),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}