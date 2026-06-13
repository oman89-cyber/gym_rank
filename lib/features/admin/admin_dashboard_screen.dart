import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/profile_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'user_management_screen.dart';
import 'admin_analytics_screen.dart';
import 'gym_management_screen.dart';

/// The high-fidelity dashboard for gym administrators.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Admin Console', 
          style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.textPrimary, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.15),
              ),
            ).animate().fadeIn(duration: 1.2.seconds).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          ),
          
          stats.when(
            data: (data) => _buildDashboard(context, ref, data),
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
            error: (e, _) => _ErrorState(error: e.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsGrid(data),
            const SizedBox(height: 40),
            _buildActionSection(context),
          ].animate(interval: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutQuart),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _StatCard(label: 'Total Users', value: '${data['totalUsers']}', icon: Icons.people_rounded, color: AppColors.blueLight),
        _StatCard(label: 'Total Sessions', value: '${data['totalSessions']}', icon: Icons.fitness_center_rounded, color: AppColors.gold),
        _StatCard(label: 'Active Today', value: '${data['activeToday']}', icon: Icons.local_fire_department_rounded, color: AppColors.orange),
        const _StatCard(label: 'Health Score', value: '98%', icon: Icons.auto_awesome_rounded, color: AppColors.green),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Management Tools', 
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _AdminActionTile(
          label: 'User Directory',
          subtitle: 'Manage user profiles, ranks, and access',
          icon: Icons.manage_accounts_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGuard(child: UserManagementScreen()))),
        ),
        const SizedBox(height: 12),
        _AdminActionTile(
          label: 'System Analytics',
          subtitle: 'Real-time sync and performance tracking',
          icon: Icons.analytics_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminAnalyticsScreen()))),
        ),
        const SizedBox(height: 12),
        _AdminActionTile(
          label: 'Gym Management',
          subtitle: 'Add or remove official gym locations',
          icon: Icons.business_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGuard(child: GymManagementScreen()))),
        ),

      ],
    );
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
                    Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AdminActionTile({required this.label, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.blueLight, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 48),
          const SizedBox(height: 16),
          Text('Dashboard Error', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    ),
  );
}

/// Security wrapper for admin features.
class AdminGuard extends ConsumerWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (!profile.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded, color: AppColors.red, size: 64),
              const SizedBox(height: 24),
              Text('Access Denied', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('This area is restricted to administrators only.', 
                   textAlign: TextAlign.center,
                   style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                child: const Text('Return Safety'),
              ),
            ],
          ),
        ),
      );
    }
    return child;
  }
}
