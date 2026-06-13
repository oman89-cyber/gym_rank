import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/models/user_profile.dart';
import '../../core/widgets/rank_badge.dart';

/// Read-only interface for Gym Owners to view their active coaching staff.
class TrainerManagementScreen extends ConsumerWidget {
  const TrainerManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final gymName = profile.managedGym ?? 'Unknown Gym';
    final trainersAsync = ref.watch(gymTrainersProvider(gymName));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Trainer Roster', 
          style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Text(
              'Currently displaying fitness coaches employed at $gymName. To modify trainer privileges, please contact global administration.',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: trainersAsync.when(
              data: (trainers) => _buildTrainerList(context, trainers),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerList(BuildContext context, List<UserProfile> trainers) {
    if (trainers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.card.withValues(alpha: 0.5)),
              child: const Icon(Icons.group_off_rounded, color: AppColors.textMuted, size: 48),
            ),
            const SizedBox(height: 16),
            Text('No Active Trainers', 
              style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('There are currently no coaches registered to this location.', 
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: trainers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trainer = trainers[index];
        return _TrainerCard(trainer: trainer)
            .animate()
            .fadeIn(delay: (index * 50).ms)
            .slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuart);
      },
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final UserProfile trainer;
  const _TrainerCard({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(trainer.username.isNotEmpty ? trainer.username[0].toUpperCase() : '?', 
                        style: GoogleFonts.rajdhani(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(trainer.username, 
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: Text('STAFF', style: GoogleFonts.inter(color: AppColors.green, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_rounded, color: AppColors.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(trainer.email ?? 'No email on file', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Rank
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RankBadge(rank: trainer.rank, fontSize: 14),
              const SizedBox(height: 4),
              Text('ELO ${trainer.eloScore.toInt()}', 
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
