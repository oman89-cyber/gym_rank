import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/widgets/rank_badge.dart';
import '../../core/models/user_profile.dart';

/// Ensures the user has appropriate permissions for the accessed console.
class GymAccessGuard extends ConsumerWidget {
  final Widget child;
  final bool requireOwner;
  final bool requireTrainer;

  const GymAccessGuard({
    super.key, 
    required this.child, 
    this.requireOwner = false, 
    this.requireTrainer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    
    bool hasAccess;
    
    // Admin Overpass: Global admins can access any console
    if (profile.isAdmin) {
      hasAccess = true;
    } else {
      // Allow if user has the specific role, even if gym isn't assigned yet
      // The dashboard screens will show a setup message if gym is null
      if (requireOwner && profile.isGymOwner) {
        hasAccess = true;
      } else if (requireTrainer && profile.isGymTrainer) {
        hasAccess = true;
      } else {
        hasAccess = false;
      }
    }

    if (!hasAccess) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: AppColors.textPrimary)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded, color: AppColors.red, size: 48),
              const SizedBox(height: 16),
              Text('Access Denied', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('You do not have the required role to view this console.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return child;
  }
}

class GymOwnerDashboardScreen extends ConsumerWidget {
  const GymOwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GymAccessGuard(
      requireOwner: true,
      child: _GymOwnerDashboardContent(),
    );
  }
}

class _GymOwnerDashboardContent extends ConsumerWidget {
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
              const Icon(Icons.business_rounded, color: AppColors.blue, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('Master Gym Required', textAlign: TextAlign.center, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text('Visit the Admin Console -> User Directory and assign a managed gym to your account to access its analytics.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, height: 1.5)),
              ),
            ],
          ),
        ),
      );
    }

    final statsAsync = ref.watch(gymStatsProvider(gymName));
    final usersAsync = ref.watch(gymUsersProvider(gymName));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top Bar ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                        Text('OWNER CONSOLE', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                        Text(gymName, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Stats ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: statsAsync.when(
                  data: (stats) => Row(
                    children: [
                      _StatCard(label: 'Total Members', value: '${stats['totalMembers']}', icon: Icons.people_rounded, color: AppColors.blue),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Pro Members', value: '${stats['proMembers']}', icon: Icons.verified_rounded, color: AppColors.gold),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Avg. ELO', value: '${(stats['averageElo'] as double).toInt()}', icon: Icons.bolt_rounded, color: AppColors.blueLight),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ),


            // ── Member List Header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('Registered Members', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('Overview Only', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    child: Center(child: Text('No members registered to this gym.', style: TextStyle(color: AppColors.textMuted))),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _OwnerMemberTile(user: users[index]),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _OwnerMemberTile extends StatelessWidget {
  final UserProfile user;
  const _OwnerMemberTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: AppColors.blue.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
            ),
            child: Center(child: Text(user.username[0].toUpperCase(), style: GoogleFonts.rajdhani(color: AppColors.blueLight, fontSize: 18, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                Text(user.subscriptionStatus.toUpperCase(), style: GoogleFonts.inter(color: user.subscriptionStatus == 'free' ? AppColors.textMuted : AppColors.gold, fontSize: 10, fontWeight: FontWeight.w800)),
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
    );
  }
}
