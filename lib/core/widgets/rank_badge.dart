import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// A pill-shaped rank badge widget (e.g. "S+" or "A-Rank").
class RankBadge extends StatelessWidget {
  final String rank;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const RankBadge({
    super.key,
    required this.rank,
    this.fontSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    // Determine the base rank to load the correct image
    String baseRank = rank.toUpperCase();
    if (baseRank.contains('+')) baseRank = baseRank.replaceAll('+', '');
    if (baseRank.contains('-')) baseRank = baseRank.replaceAll('-', '');
    
    // Map of valid image ranks
    final validRanks = {'A', 'B', 'C', 'D', 'E', 'F', 'S', 'SS'};
    final hasAsset = validRanks.contains(baseRank);
    final assetPath = 'assets/rank_badge/$baseRank.png';

    if (hasAsset) {
      return Image.asset(
        assetPath,
        width: fontSize * 3.5, // Scale image relative to requested font size
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallbackBadge(context),
      );
    }
    
    return _fallbackBadge(context);
  }

  Widget _fallbackBadge(BuildContext context) {
    final color = AppColors.getRankColor(rank);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Text(
        rank,
        style: GoogleFonts.rajdhani(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Small colored dot indicator for rank tier.
class RankDot extends StatelessWidget {
  final String rank;
  final double size;
  const RankDot({super.key, required this.rank, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.getRankColor(rank),
      ),
    );
  }
}
