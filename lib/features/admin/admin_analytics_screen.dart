import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/admin_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Advanced analytics dashboard for system insights.
class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('System Analytics', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: analyticsAsync.when(
        data: (data) => _buildBody(data),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.red))),
      ),
    );
  }

  Widget _buildBody(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryGrid(data),
          const SizedBox(height: 32),
          _buildSectionTitle('GROWTH TRENDS'),
          const SizedBox(height: 16),
          _buildGrowthChart([32, 45, 28, 60, 48, 75, 90]), // Mock trend
          const SizedBox(height: 32),
          _buildSectionTitle('USER DISTRIBUTION'),
          const SizedBox(height: 16),
          _buildDistributionCard(data),
        ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2));
  }

  Widget _buildSummaryGrid(Map<String, dynamic> data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3, // Adjusted to prevent overflow
      children: [
        _StatCard(label: 'Total Users', value: '${data['totalUsers'] ?? 0}', color: AppColors.blue, icon: Icons.people_rounded),
        _StatCard(label: 'Pro Users', value: '${data['proUsers'] ?? 0}', color: AppColors.gold, icon: Icons.star_rounded),
        _StatCard(label: 'Daily Active', value: '${data['dau'] ?? 0}', color: AppColors.green, icon: Icons.bolt_rounded),
        _StatCard(label: 'Feed Posts', value: '${data['totalPosts'] ?? 0}', color: AppColors.blueLight, icon: Icons.feed_rounded),
      ],
    );
  }

  Widget _buildGrowthChart(List<double> points) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly New Signups', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              Text('+12% vs last week', style: GoogleFonts.inter(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((p) => _Bar(height: p)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard(Map<String, dynamic> data) {
    final total = (data['totalUsers'] ?? 1) as int;
    final pro = (data['proUsers'] ?? 0) as int;
    final trial = (data['trialUsers'] ?? 0) as int;
    final free = total - pro - trial;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          _DistRow(label: 'Pro Lifters', count: pro, total: total, color: AppColors.gold),
          const SizedBox(height: 12),
          _DistRow(label: 'Trial Users', count: trial, total: total, color: AppColors.blueLight),
          const SizedBox(height: 12),
          _DistRow(label: 'Free Users', count: free, total: total, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label.toUpperCase(), style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  const _Bar({required this.height});
  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: height,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.blue, AppColors.blueLight],
      ),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _DistRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _DistRow({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$count (${(percent * 100).toStringAsFixed(1)}%)', 
                 style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: AppColors.border.withValues(alpha: 0.3),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
