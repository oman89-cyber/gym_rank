import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/elo_service.dart';
import '../../../core/services/recovery_service.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/widgets/rank_badge.dart';

class MuscleProgressSheet extends ConsumerStatefulWidget {
  const MuscleProgressSheet({super.key});

  @override
  ConsumerState<MuscleProgressSheet> createState() => _MuscleProgressSheetState();
}

class _MuscleProgressSheetState extends ConsumerState<MuscleProgressSheet>
    with SingleTickerProviderStateMixin {
  bool _animateBars = false;

  @override
  void initState() {
    super.initState();
    // Delay bar animation so they slide in after sheet opens
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _animateBars = true);
    });
  }

  String _rankFromScore(double score) {
    if (score >= 80) return 'S';
    if (score >= 60) return 'A';
    if (score >= 40) return 'B';
    if (score >= 20) return 'C';
    if (score >= 5)  return 'D';
    return 'F';
  }

  String _label(String m) => m[0].toUpperCase() + m.substring(1);

  @override
  Widget build(BuildContext context) {
    final sessions  = ref.watch(sessionsProvider);
    final radarMap  = EloService.instance.radarScores(sessions);
    const muscles   = RecoveryService.allMuscles;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: AppColors.blueLight, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Muscle Progress', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    Text('Based on your logged sessions', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),

          // Muscle list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: muscles.length,
              itemBuilder: (_, i) {
                final muscle = muscles[i];
                final score  = radarMap[muscle] ?? 0.0;
                final rank   = _rankFromScore(score);
                final color  = AppColors.getRankColor(rank);
                final pct    = score / 100.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _label(muscle),
                              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          RankBadge(rank: rank, fontSize: 11, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 38,
                            child: Text(
                              '${score.toInt()}%',
                              style: GoogleFonts.rajdhani(color: color, fontSize: 15, fontWeight: FontWeight.w800),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        children: [
                          // Background track
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // Animated fill
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOut,
                            widthFactor: _animateBars ? pct.clamp(0.0, 1.0) : 0.0,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
