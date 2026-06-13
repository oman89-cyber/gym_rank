import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/workout_providers.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/utils/muscle_mapper.dart';
import 'package:flutter_body_atlas/flutter_body_atlas.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import '../profile/profile_screen.dart';
import '../../core/models/user_profile.dart';
import '../../core/widgets/rank_badge.dart';
import '../rank_assessment/rank_assessment_screen.dart';
import 'widgets/gym_ai_chat_screen.dart';
import 'widgets/live_coach_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _focusedMonth = DateTime(2026, 3);

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final profile  = ref.watch(profileProvider);

    // Build muscle activation from last 7 days of sessions
    final recentActivation = <String, double>{};
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    for (final s in sessions.where((s) => s.date.isAfter(cutoff))) {
      for (final entry in s.muscleActivation.entries) {
        recentActivation[entry.key] =
            ((recentActivation[entry.key] ?? 0) + entry.value).clamp(0.0, 1.0);
      }
    }

    // Count sessions this week (Mon–Sun)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final sessionsThisWeek = sessions.where((s) =>
        s.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).length;

    // Days with sessions (for calendar dots)
    final workedDays = sessions.map((s) =>
        DateTime(s.date.year, s.date.month, s.date.day)).toSet();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(profile: profile),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                child: Column(
                  children: [
                    RepaintBoundary(child: _RankBanner(profile: profile)),
                    if (profile.baseElo == 0)
                      _RankAssessmentBanner(),
                    _LiveCoachBanner(),
                    RepaintBoundary(child: _QuickStatsRow(profile: profile, sessionsThisWeek: sessionsThisWeek)),
                    RepaintBoundary(child: _MuscleCard(activation: recentActivation, sessionsThisWeek: sessionsThisWeek)),
                    const SizedBox(height: 16),
                    RepaintBoundary(child: _CalendarCard(focusedMonth: _focusedMonth, workedDays: workedDays, onMonthChanged: (m) => setState(() => _focusedMonth = m))),
                  ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuart),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70), 
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => const GymAiChatScreen(),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.blue, AppColors.blueDark, AppColors.gold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final UserProfile profile;
  const _TopBar({required this.profile});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3), width: 1)),
          ),
          child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_greeting, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
            Text(profile.username, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
          ]),
          const Spacer(),
          // Avatar → Profile
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileSheet())),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.blueDark, AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: AppColors.getRankColor(profile.rank), width: 1.5),
              ),
              child: Center(child: Text(
                profile.username.isNotEmpty ? profile.username[0].toUpperCase() : 'G',
                style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              )),
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }
}


// ── Rank Assessment Banner ─────────────────────────────────────────────────────
class _RankAssessmentBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RankAssessmentScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.blue.withValues(alpha: 0.15), AppColors.gold.withValues(alpha: 0.1)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Already Strong?',
                      style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  Text('Check your real rank — don\'t start at F!',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.gold, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Muscle Card ────────────────────────────────────────────────────────────────
class _MuscleCard extends StatelessWidget {
  final Map<String, double> activation;
  final int sessionsThisWeek;
  const _MuscleCard({required this.activation, required this.sessionsThisWeek});

  @override
  Widget build(BuildContext context) {
    const weekGoal = 6;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Muscles trained this week', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.settings_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Days: $sessionsThisWeek/$weekGoal', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              _legendBox(AppColors.blueMuted, '1x'),
              const SizedBox(width: 8),
              _legendBox(AppColors.blue.withValues(alpha: 0.7), '2x'),
              const SizedBox(width: 8),
              _legendBox(AppColors.blue, '3x+'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: Row(
              children: [
                Expanded(
                  child: BodyAtlasView<MuscleInfo>(
                    view: AtlasAsset.musclesFront,
                    resolver: const MuscleResolver(),
                    colorMapping: _buildColorMap(),
                  ),
                ),
                Expanded(
                  child: BodyAtlasView<MuscleInfo>(
                    view: AtlasAsset.musclesBack,
                    resolver: const MuscleResolver(),
                    colorMapping: _buildColorMap(),
                  ),
                ),
              ],
            ),
          ),
          if (activation.isEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.blueLight, size: 16),
                  const SizedBox(width: 8),
                  Text('Log your first workout to see heat map', style: GoogleFonts.inter(color: AppColors.blueLight, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendBox(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 14, height: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
    ],
  );

  Map<MuscleInfo, Color> _buildColorMap() {
    final mapping = <MuscleInfo, Color>{};
    for (final entry in activation.entries) {
      final double intensity = entry.value;
      if (intensity <= 0) continue;

      List<MuscleInfo> muscles = mapDbMusclesToAtlas([entry.key]);
      if (muscles.isEmpty) continue;

      Color c = AppColors.blueMuted;
      if (intensity >= 0.6) c = AppColors.blue;
      else if (intensity >= 0.3) c = AppColors.blue.withValues(alpha: 0.7);

      for (var m in muscles) {
        mapping[m] = c;
      }
    }
    return mapping;
  }
}

// ── Calendar Card ──────────────────────────────────────────────────────────────
class _CalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final Set<DateTime> workedDays;
  final ValueChanged<DateTime> onMonthChanged;

  const _CalendarCard({required this.focusedMonth, required this.workedDays, required this.onMonthChanged});

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = DateTime(focusedMonth.year, focusedMonth.month, 1).weekday;
    final rows = ((startWeekday - 1 + daysInMonth) / 7).ceil();
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workout Calendar', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month - 1)),
                child: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Text('${_month(focusedMonth.month)} ${focusedMonth.year}',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + 1)),
                child: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: dayNames.map((d) => Expanded(child: Center(child: Text(d, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))))).toList()),
          const SizedBox(height: 8),
          ...List.generate(rows, (row) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: List.generate(7, (col) {
                final day = row * 7 + col - (startWeekday - 1) + 1;
                if (day < 1 || day > daysInMonth) return const Expanded(child: SizedBox());
                final date = DateTime(focusedMonth.year, focusedMonth.month, day);
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                final hasSession = workedDays.contains(date);
                return Expanded(
                  child: Center(
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday ? AppColors.blue : hasSession ? AppColors.blue.withValues(alpha: 0.25) : Colors.transparent,
                        border: hasSession && !isToday ? Border.all(color: AppColors.blue.withValues(alpha: 0.5)) : null,
                      ),
                      child: Center(
                        child: Text('$day', style: GoogleFonts.inter(
                          color: isToday ? Colors.white : hasSession ? AppColors.blueLight : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: (isToday || hasSession) ? FontWeight.w700 : FontWeight.w400,
                        )),
                      ),
                    ),
                  ),
                );
              }),
            ),
          )),
        ],
      ),
    );
  }

  String _month(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}

// ── Rank Banner ──────────────────────────────────────────────────────────────
class _RankBanner extends StatelessWidget {
  final UserProfile profile;
  const _RankBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rankColor = AppColors.getRankColor(profile.rank);
    // Calculate progress to next rank
    double getProgress() {
      final s = profile.eloScore;
      if (s < 50) return s / 50;
      if (s < 100) return (s - 50) / 50;
      if (s < 200) return (s - 100) / 100;
      if (s < 300) return (s - 200) / 100;
      if (s < 400) return (s - 300) / 100;
      if (s < 500) return (s - 400) / 100;
      if (s < 700) return (s - 500) / 200;
      return 1.0;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            rankColor.withValues(alpha: 0.15),
            AppColors.card,
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: rankColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT STANDING',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    profile.rankLabel,
                    style: GoogleFonts.rajdhani(color: rankColor, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1),
                  ),
                ),
                Text(
                  '${profile.eloScore.toInt()} Elo Points',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: getProgress(),
                    minHeight: 6,
                    backgroundColor: AppColors.background.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation(rankColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rankColor.withValues(alpha: 0.05),
                  border: Border.all(color: rankColor.withValues(alpha: 0.2), width: 2),
                ),
              ),
              RankBadge(rank: profile.rank, fontSize: 32),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Stats Row ──────────────────────────────────────────────────────────
class _QuickStatsRow extends StatelessWidget {
  final UserProfile profile;
  final int sessionsThisWeek;
  const _QuickStatsRow({required this.profile, required this.sessionsThisWeek});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: _StatPill(icon: Icons.fitness_center_rounded, label: 'Workouts', value: '${profile.totalSessions}', color: AppColors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _StatPill(icon: Icons.trending_up_rounded, label: 'Standing', value: profile.topPercent, color: AppColors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _StatPill(icon: Icons.local_fire_department_rounded, label: 'This Week', value: '$sessionsThisWeek/6', color: AppColors.red)),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatPill({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color.withValues(alpha: 0.8)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Live Coach Banner ────────────────────────────────────────────────────────
class _LiveCoachBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LiveCoachScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppColors.blue, AppColors.gold, AppColors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.videocam_rounded, color: AppColors.blueLight, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE FORM COACHING',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.blueLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Point camera for real-time AI advice',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: GoogleFonts.inter(
                        color: AppColors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).shimmer(duration: 2.seconds, color: Colors.white24);
  }
}
