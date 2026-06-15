import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'graph_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainNavigationScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // Default ke Beranda (Tengah)
  
  // 🛠️ 1. TAMBAHKAN PENGONTROL HALAMAN
  late PageController _pageController; 

  @override
  void initState() {
    super.initState();
    // 🛠️ 2. INISIALISASI PENGONTROL SESUAI INDEX AWAL
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    // 🛠️ 3. BERSIHKAN PENGONTROL SAAT LAYAR DITUTUP
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MEMPROSES ULANG HALAMAN DI SINI AGAR TEMA TIDAK MEMBEKU
    final List<Widget> screens = [
      SettingsScreen(isDarkMode: widget.isDarkMode),
      DashboardScreen(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
      GraphScreen(isDarkMode: widget.isDarkMode),
    ];

    return Scaffold(
      // 🛠️ 4. GANTI INDEXEDSTACK MENJADI PAGEVIEW
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(), // Memberikan efek mantul saat mentok di pinggir
        onPageChanged: (index) {
          // Fungsi ini dipanggil saat layarnya digeser pakai jari
          setState(() {
            _currentIndex = index;
          });
        },
        children: screens, 
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // 🛠️ 5. BERIKAN ANIMASI SAAT IKON BAWAH DITEKAN
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: "Pengaturan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: "Grafik",
          ),
        ],
      ),
    );
  }
}