import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/widgets/rank_badge.dart';
import '../../core/models/user_profile.dart';
import 'gym_member_details_screen.dart';
import 'gym_owner_dashboard.dart'; // For GymAccessGuard

class GymTrainerDashboardScreen extends ConsumerWidget {
  const GymTrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GymAccessGuard(
      requireTrainer: true,
      child: _GymTrainerDashboardContent(),
    );
  }
}

class _GymTrainerDashboardContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final gymName = profile.managedGym;

    if (gymName == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: AppColors.textPrimary)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_rounded, color: AppColors.green, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('Coaching Setup Required', textAlign: TextAlign.center, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('Visit the Admin Console -> User Directory and assign a managed gym to your account to view athlete logs.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
              ),
            ],
          ),
        ),
      );
    }

    final usersAsync = ref.watch(gymUsersProvider(gymName));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top Bar ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRAINER CONSOLE', style: GoogleFonts.inter(color: AppColors.green, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                        Text(gymName, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Athlete Details Information ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tap on any athlete below to view their detailed session logs and track their progressive overload.',
                          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Athlete Roster Header ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Athlete Roster', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('Performance Logs', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Member List ──────────────────────────────────────────────────────
            usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No athletes registered to this gym yet.', style: TextStyle(color: AppColors.textMuted))),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _TrainerAthleteTile(user: users[index]),
                    ),
                    childCount: users.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, __) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _TrainerAthleteTile extends StatelessWidget {
  final UserProfile user;
  const _TrainerAthleteTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GymMemberDetailsScreen(member: user)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
            ),
            child: Center(child: Text(user.username[0].toUpperCase(), style: GoogleFonts.rajdhani(color: AppColors.green, fontSize: 18, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                Text('${user.totalSessions} Recorded Sessions', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RankBadge(rank: user.rank, fontSize: 10),
              Text('${user.eloScore.toInt()} ELO', style: GoogleFonts.rajdhani(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
