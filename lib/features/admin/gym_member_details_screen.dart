import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/workout_session.dart';
import '../../core/models/logged_exercise.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/rank_badge.dart';

class GymMemberDetailsScreen extends ConsumerWidget {
  final UserProfile member;
  const GymMemberDetailsScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Because uid might be missing in early versions of the app, fallback to username if uid is not present. 
    // Ideally, member.uid is always set.
    final uid = member.uid ?? member.username; 
    final sessionsAsync = ref.watch(memberSessionsProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────────
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
                        Text('MEMBER LOGS', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700)),
                        Text(member.username, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Profile Overview ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          RankBadge(rank: member.rank, fontSize: 16),
                          const SizedBox(height: 4),
                          Text('${member.eloScore.toInt()} ELO', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Column(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: member.subscriptionStatus != 'free' ? AppColors.gold : AppColors.textMuted, size: 28),
                          const SizedBox(height: 4),
                          Text(member.subscriptionStatus.toUpperCase(), style: GoogleFonts.inter(color: member.subscriptionStatus != 'free' ? AppColors.gold : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: AppColors.border),
                      Column(
                        children: [
                          const Icon(Icons.fitness_center_rounded, color: AppColors.blueLight, size: 28),
                          const SizedBox(height: 4),
                          Text('${member.totalSessions} Sessions', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // ── Logs Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Workout History', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),

            // ── Session Logs List ────────────────────────────────────────────────
            sessionsAsync.when(
              data: (maps) {
                if (maps.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No workouts logged yet.', style: TextStyle(color: AppColors.textMuted))),
                  );
                }
                
                final sessions = maps.map((m) => WorkoutSession.fromMap(m)).toList();
                
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final session = sessions[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _SessionLogCard(session: session),
                      );
                    },
                    childCount: sessions.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.blue))),
              error: (e, __) => SliverFillRemaining(child: Center(child: Text('Error loading sessions: $e', style: const TextStyle(color: AppColors.red)))),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _SessionLogCard extends StatefulWidget {
  final WorkoutSession session;
  const _SessionLogCard({required this.session});

  @override
  State<_SessionLogCard> createState() => _SessionLogCardState();
}

class _SessionLogCardState extends State<_SessionLogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
    final durationMins = (widget.session.durationSeconds / 60).round();
    final volume = widget.session.exercises.fold(0.0, (sum, ex) => sum + ex.totalVolume);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _expanded ? AppColors.blue.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.fitness_center_rounded, color: AppColors.blueLight, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.session.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(dateFormat.format(widget.session.date), style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
          
          if (_expanded) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LogMiniStat(icon: Icons.timer_outlined, label: '$durationMins min'),
                _LogMiniStat(icon: Icons.monitor_weight_outlined, label: '${volume.toInt()} kg'),
                _LogMiniStat(icon: Icons.format_list_bulleted_rounded, label: '${widget.session.exercises.length} Exs'),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.session.exercises.map((ex) => _ExerciseLogEntry(exercise: ex)),
          ],
        ],
      ),
    );
  }
}

class _LogMiniStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LogMiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 14),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ExerciseLogEntry extends StatelessWidget {
  final LoggedExercise exercise;
  const _ExerciseLogEntry({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(exercise.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(exercise.muscleGroup.toUpperCase(), style: GoogleFonts.inter(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ...exercise.sets.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final set = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text('Set $idx', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${set.weightKg.toInt()} kg  ×  ${set.reps} reps', style: GoogleFonts.rajdhani(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
