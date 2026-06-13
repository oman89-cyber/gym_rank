import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class RankProgressBar extends StatelessWidget {
  final double eloScore;

  const RankProgressBar({super.key, required this.eloScore});

  // Returns (currentRankName, nextRankName, progressToNextRank, color)
  (String, String, double, Color) _calculateProgress() {
    if (eloScore < 50) return ('F', 'E', eloScore / 50.0, AppColors.getRankColor('F'));
    if (eloScore < 100) return ('E', 'D', (eloScore - 50) / 50.0, AppColors.getRankColor('E'));
    if (eloScore < 200) return ('D', 'C', (eloScore - 100) / 100.0, AppColors.getRankColor('D'));
    if (eloScore < 300) return ('C', 'B', (eloScore - 200) / 100.0, AppColors.getRankColor('C'));
    if (eloScore < 400) return ('B', 'A', (eloScore - 300) / 100.0, AppColors.getRankColor('B'));
    if (eloScore < 500) return ('A', 'S', (eloScore - 400) / 100.0, AppColors.getRankColor('A'));
    if (eloScore < 700) return ('S', 'SS', (eloScore - 500) / 200.0, AppColors.getRankColor('S'));
    return ('SS', 'MAX', 1.0, AppColors.getRankColor('SS'));
  }

  @override
  Widget build(BuildContext context) {
    final (currentRank, nextRank, progress, color) = _calculateProgress();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.military_tech_rounded, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$currentRank-Rank',
                  style: GoogleFonts.rajdhani(color: color, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Text(
              eloScore >= 700 ? 'Max Rank Reached' : 'Next: $nextRank-Rank',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Progress Bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Stack(
            children: [
              // Filled portion (Animated)
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 0),
                      ],
                    ),
                  )
                  .animate()
                  .custom(
                    duration: 1.5.seconds,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: child,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Bottom Points
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${eloScore.toStringAsFixed(0)} EXP',
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}
