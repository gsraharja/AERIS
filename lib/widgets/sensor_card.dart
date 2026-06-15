import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color statusColor;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.2 : 0.35),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3), 
          width: 1.5
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BAGIAN ATAS ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                // 🛠️ PERUBAHAN: Padding diperkecil dari 6 menjadi 4
                padding: const EdgeInsets.all(4), 
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  // 🛠️ PERUBAHAN: Radius diperkecil dari 10 menjadi 8 agar pas dengan ikon yang lebih kecil
                  borderRadius: BorderRadius.circular(8), 
                ),
                // 🛠️ PERUBAHAN: Ukuran ikon diperkecil dari 22 menjadi 18
                child: Icon(icon, size: 18, color: statusColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // --- BAGIAN BAWAH ---
          // 🛠️ PERBAIKAN: Gunakan Expanded agar FittedBox tahu batas maksimal tinggi (height) yang tersisa
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight, // Memastikan teks selalu menempel di kanan bawah
              child: FittedBox(
                fit: BoxFit.scaleDown, // Teks akan otomatis mengecil jika ruang vertikal/horizontal sempit
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end, 
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value, 
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: statusColor, 
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}