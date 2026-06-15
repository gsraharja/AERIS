import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart'; // Import package marquee

class StatusBanner extends StatelessWidget {
  final String statusText;
  final String score;
  final String confidence;
  final Color bannerColor;
  final Color scoreBoxColor;

  const StatusBanner({
    super.key,
    required this.statusText,
    required this.score,
    required this.confidence,
    required this.bannerColor,
    required this.scoreBoxColor,
  });

  @override
  Widget build(BuildContext context) {
    bool isLongText = statusText.length > 10; 

    return Container(
      width: double.infinity,
      height: 100, // Tetapkan tinggi yang tetap agar banner stabil
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bagian Kiri: Teks Status
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "STATUS SAAT INI",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // 🛠️ IMPLEMENTASI RUNNING TEXT
                  SizedBox(
                    height: 35, // Batasi tinggi area teks
                    child: isLongText 
                      ? Marquee(
                          text: statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                          scrollAxis: Axis.horizontal,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          blankSpace: 40.0, // Jarak sebelum teks berulang
                          velocity: 40.0,   // Kecepatan teks berjalan
                          pauseAfterRound: const Duration(seconds: 1),
                          startPadding: 0.0,
                          accelerationDuration: const Duration(seconds: 1),
                          accelerationCurve: Curves.linear,
                          decelerationDuration: const Duration(milliseconds: 500),
                          decelerationCurve: Curves.easeOut,
                        )
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Bagian Kanan: Score dan Confidence ML
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: scoreBoxColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  topLeft: Radius.circular(40), // Sedikit melengkung ke dalam
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Score EIS",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    score,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Menampilkan Confidence Model Random Forest
                  Text(
                    "AI Conf: $confidence%",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}