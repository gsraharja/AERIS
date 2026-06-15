import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {

  // =====================
  // DARK MODE (MODE GELAP) - Tetap menggunakan palet sebelumnya
  // =====================
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121358), 
    cardColor: const Color(0xFF2F578A),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF232F72),
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Color(0xFF36ADA3)),
    ),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF36ADA3), 
      secondary: Color(0xFF36ADA3), 
      surface: Color(0xFF2F578A),
      error: Colors.redAccent,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF232F72),
      selectedItemColor: Color(0xFF36ADA3), 
      unselectedItemColor: Colors.white54,
    ),

    iconTheme: const IconThemeData(
      color: Color(0xFF36ADA3),
    ),

    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );


  // =====================
  // LIGHT MODE (MODE TERANG) - MENGGUNAKAN PALET BARU
  // =====================
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    
    // Background Utama menggunakan warna D1F8EF (Mint/Cyan Paling Pucat)
    scaffoldBackgroundColor: const Color(0xFFD1F8EF), 
    
    // Card menggunakan putih murni agar teks dan angka terbaca jelas
    cardColor: Colors.white,

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFA1E3F9), // Biru muda (A1E3F9) untuk AppBar
      elevation: 0,
      centerTitle: false,
      // Ikon dan Teks di AppBar menggunakan biru paling gelap (3674B5) untuk kontras
      iconTheme: IconThemeData(color: Color(0xFF3674B5)),
      titleTextStyle: TextStyle(
        color: Color(0xFF3674B5), 
        fontSize: 20, 
        fontWeight: FontWeight.bold,
      ),
    ),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF578FCA),   // Biru Medium
      secondary: Color(0xFF3674B5), // Biru Paling Gelap untuk interaktif
      tertiary: Color(0xFFA1E3F9),  // Biru Muda
      surface: Colors.white,
      error: Colors.redAccent,
      onSurface: Color(0xFF3674B5),
      onSurfaceVariant: Color(0xFF578FCA),
    ),
    
      switchTheme: SwitchThemeData(
      // 1. Warna tombol bulat (Thumb)
      thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF3674B5); // Biru Gelap saat ON
        }
        return const Color(0xFF578FCA); // Biru Medium saat OFF (Bukan hitam lagi!)
      }),
      
      // 2. Warna jalur lintasan (Track)
      trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF578FCA).withValues(alpha: 0.5); // Biru Medium transparan saat ON
        }
        return const Color(0xFFA1E3F9).withValues(alpha: 0.5); // Biru Muda transparan saat OFF
      }),
      
      // 3. Warna garis luar (Outline)
      trackOutlineColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent; // Hilangkan garis saat ON
        }
        return const Color(0xFF578FCA); // Garis Biru Medium saat OFF
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFFA1E3F9), // Sama dengan AppBar
      selectedItemColor: const Color(0xFF3674B5), // Ikon aktif berwarna biru gelap
      unselectedItemColor: const Color(0xFF578FCA).withValues(alpha:0.7), // Ikon tidak aktif
    ),

    iconTheme: const IconThemeData(
      color: Color(0xFF3674B5), // Ikon default biru gelap
    ),

    // Teks di mode terang menggunakan warna biru paling gelap (3674B5)
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData.light().textTheme,
    ).apply(
      bodyColor: const Color(0xFF3674B5),
      displayColor: const Color(0xFF3674B5),
    ),
  );
}