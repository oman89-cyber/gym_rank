import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/workout_providers.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/services/elo_service.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/widgets/rank_badge.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'compare_screen.dart';
import '../friends/friends_screen.dart';

class RankScreen extends ConsumerStatefulWidget {
  const RankScreen({super.key});
  @override
  ConsumerState<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends ConsumerState<RankScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final profile  = ref.watch(profileProvider);
    final sessions = ref.watch(sessionsProvider);
    final radarMap = EloService.instance.radarScores(sessions);

    const muscles = ['chest', 'shoulders', 'biceps', 'abs', 'quads', 'calves', 'hamstrings', 'glutes', 'back', 'triceps'];
    final radarPoints = muscles.map((m) {
      final val = radarMap[m] ?? 0;
      String rank;
      if (val >= 80) rank = 'S';
      else if (val >= 60) rank = 'A';
      else if (val >= 40) rank = 'B';
      else if (val >= 20) rank = 'C';
      else rank = 'D';
      
      // Clean label for display
      String label = m[0].toUpperCase() + m.substring(1);
      return RadarPoint(label, val, rank);
    }).toList();

    final rankColor = AppColors.getRankColor(profile.rank);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar(rankColor: rankColor, username: profile.username)),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            // ── Hero License Card ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HeroLicenseCard(profile: profile, rankColor: rankColor),
              ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuart),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            // ── Quick Actions ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _QuickGrid(rankColor: rankColor),
              ).animate().fadeIn(duration: 450.ms, delay: 100.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuart),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            // ── Radar Card ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RadarCard(points: radarPoints),
              ).animate().fadeIn(duration: 450.ms, delay: 200.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuart),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 16)),
            // ── Rank Tiers ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: _RankBreakdown(currentRank: profile.rank),
              ).animate().fadeIn(duration: 450.ms, delay: 300.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutQuart),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final Color rankColor;
  final String username;
  const _TopBar({required this.rankColor, required this.username});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.2), width: 0.5)),
        ),
        child: Row(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('GYM RANK', style: GoogleFonts.rajdhani(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              Text('Rank', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, height: 1)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(children: [
                Icon(Icons.emoji_events_rounded, color: rankColor, size: 14),
                const SizedBox(width: 6),
                Text('@$username', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
      );
}

// ── Hero License Card ──────────────────────────────────────────────────────────
class _HeroLicenseCard extends StatelessWidget {
  final dynamic profile;
  final Color rankColor;
  const _HeroLicenseCard({required this.profile, required this.rankColor});

  @override
  Widget build(BuildContext context) {
    final nextRankElo  = _nextThreshold(profile.eloScore);
    final progressPct  = nextRankElo > 0 ? (profile.eloScore / nextRankElo).clamp(0.0, 1.0) : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            rankColor.withValues(alpha: 0.1),
            AppColors.card,
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(color: AppColors.blue.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.blue.withValues(alpha: 0.1), AppColors.background.withValues(alpha: 0.2)]),
                    border: Border.all(color: AppColors.blue.withValues(alpha: 0.15), width: 0.5),
                    boxShadow: [
                      BoxShadow(color: AppColors.blue.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 0),
                    ],
                  ),
                  child: RankBadge(rank: profile.rank, fontSize: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('GYM RANK LICENSE', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 2),
                    Text('@${profile.username}', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('Lv.${profile.totalSessions}', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Big rank display
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(profile.rankLabel,
                        style: GoogleFonts.rajdhani(
                          color: rankColor,
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          shadows: [Shadow(color: rankColor.withValues(alpha: 0.5), blurRadius: 16)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('ELO  ', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                      Text('${profile.eloScore.toInt()}', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                    ]),
                  ]),
                ),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(profile.topPercent, style: GoogleFonts.inter(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress to next rank', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, letterSpacing: 0.5)),
                Text('${(progressPct * 100).toInt()}%  →  ELO ${nextRankElo.toInt()}', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(height: 6, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6))),
                FractionallySizedBox(
                  widthFactor: progressPct,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [rankColor.withValues(alpha: 0.6), rankColor]),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: rankColor.withValues(alpha: 0.6), blurRadius: 8)],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0);
  }

  double _nextThreshold(double elo) {
    const thresholds = [50.0, 100.0, 200.0, 300.0, 400.0, 500.0, 700.0, 999.0];
    for (final t in thresholds) { if (elo < t) return t; }
    return 999;
  }
}

// ── Quick Grid ─────────────────────────────────────────────────────────────────
class _QuickGrid extends StatelessWidget {
  final Color rankColor;
  const _QuickGrid({required this.rankColor});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.emoji_events_rounded,  'Leaderboard'),
      (Icons.people_rounded,        'Compare'),
      (Icons.group_rounded,         'Friends'),
    ];
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05,
      children: items.map((item) => _QuickButton(
        icon: item.$1,
        label: item.$2,
        rankColor: rankColor,
        onTap: () {
          if (item.$2 == 'Leaderboard') {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const LeaderboardScreen()));
          } else if (item.$2 == 'Compare') {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const CompareScreen()));
          } else if (item.$2 == 'Friends') {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const FriendsScreen()));
          }
        },
      )).toList(),
    );
  }
}

// ── Radar Card ─────────────────────────────────────────────────────────────────
class _RadarCard extends StatelessWidget {
  final List<RadarPoint> points;
  const _RadarCard({required this.points});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border, width: 0.5),
    ),
    child: Column(
      children: [
        Row(children: [
          Text('Strength Radar', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('Per muscle group', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 320, child: RadarChartWidget(points: points)),
        const SizedBox(height: 8),
      ],
    ),
  );
}

// ── Rank Breakdown ─────────────────────────────────────────────────────────────
class _RankBreakdown extends StatelessWidget {
  final String currentRank;
  const _RankBreakdown({required this.currentRank});

  @override
  Widget build(BuildContext context) {
    const tiers = [
      ('F', 0, 50), ('E', 50, 100), ('D', 100, 200),
      ('C', 200, 300), ('B', 300, 400), ('A', 400, 500),
      ('S', 500, 700), ('SS', 700, 999),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rank Tiers', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ...tiers.map((t) {
            final isCurrent = t.$1 == currentRank;
            final color = AppColors.getRankColor(t.$1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isCurrent ? color.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isCurrent ? color.withValues(alpha: 0.5) : AppColors.border, width: isCurrent ? 1 : 0.5),
                  boxShadow: isCurrent ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10)] : null,
                ),
                child: Row(children: [
                  RankBadge(rank: t.$1, fontSize: 13),
                  const SizedBox(width: 12),
                  Text('${t.$2} – ${t.$3 == 999 ? '∞' : t.$3} ELO',
                    style: GoogleFonts.inter(color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withValues(alpha: 0.4))),
                      child: Text('You ←', style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Quick Button ───────────────────────────────────────────────────────────────
class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color rankColor;
  const _QuickButton({required this.icon, required this.label, required this.onTap, required this.rankColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Icon(icon, color: AppColors.blue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, 
            style: GoogleFonts.inter(
              color: AppColors.textPrimary, 
              fontSize: 11, 
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2
            ), 
            textAlign: TextAlign.center,
            maxLines: 1, 
            overflow: TextOverflow.visible
          ),
        ],
      ),
    ),
  );
}
