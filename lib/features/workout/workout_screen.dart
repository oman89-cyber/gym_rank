import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../../core/theme/app_colors.dart';
import '../../core/providers/workout_providers.dart';
import '../../core/services/recovery_service.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/models/workout_session.dart';
import 'edit_workout_screen.dart';
import 'widgets/active_session_view.dart';
import 'widgets/history_sheet.dart';
import 'widgets/muscle_progress_sheet.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../pose_tracker/pose_tracker_screen.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeWorkoutProvider);
    if (active != null) {
      return const ActiveSessionView();
    }
    return const _IdleView();
  }
}

// ── Idle state (no active session) ────────────────────────────────────────────
class _IdleView extends ConsumerWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    final routines = ref.watch(routinesProvider);
    final profile  = ref.watch(profileProvider);
    final recovery = RecoveryService.instance.compute(sessions);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _GlowFab(onTap: () => _showStartSheet(context, ref)),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar(profile.username)),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(child: _QuickGrid(ref: ref)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _MuscleRecoverySection(recovery: recovery, useKg: profile.useKg)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _RoutinesSection(routines: routines, ref: ref)),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  void _showStartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StartWorkoutSheet(ref: ref),
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String username;
  const _TopBar(this.username);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3), width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TRAINING CENTER', style: GoogleFonts.inter(color: AppColors.blueLight, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Workouts', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Grid ─────────────────────────────────────────────────────────────────
class _QuickGrid extends StatelessWidget {
  final WidgetRef ref;
  const _QuickGrid({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Coach',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiCoachScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickButton(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: () => _openHistory(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickButton(
                  icon: Icons.videocam_rounded,
                  label: 'Form AI',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PoseTrackerScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Progress',
                  onTap: () => _openProgress(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HistorySheet(),
    );
  }

  void _openProgress(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => const MuscleProgressSheet(),
      ),
    );
  }
}

// ── Muscle Recovery Section ────────────────────────────────────────────────────
class _MuscleRecoverySection extends StatelessWidget {
  final Map<String, double> recovery;
  final bool useKg;
  const _MuscleRecoverySection({required this.recovery, required this.useKg});

  @override
  Widget build(BuildContext context) {
    const muscles = RecoveryService.allMuscles;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Muscle Recovery', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('48h avg', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: muscles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final muscle = muscles[i];
                final pct = (recovery[muscle] ?? 100).round();
                return _RecoveryCard(muscle: _label(muscle), pct: pct);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _label(String m) => m[0].toUpperCase() + m.substring(1);
}

class _RecoveryCard extends StatelessWidget {
  final String muscle;
  final int pct;
  const _RecoveryCard({required this.muscle, required this.pct});

  @override
  Widget build(BuildContext context) {
    final isReady = pct >= 90;
    final color = isReady ? AppColors.blue
        : pct >= 60 ? AppColors.gold
        : AppColors.orange;

    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady ? AppColors.blue.withValues(alpha: 0.4) : AppColors.border,
          width: isReady ? 1.2 : 0.6,
        ),
        boxShadow: isReady ? [BoxShadow(color: AppColors.blue.withValues(alpha: 0.1), blurRadius: 10)] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.accessibility_new_rounded, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(muscle, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Text('$pct%', style: GoogleFonts.rajdhani(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ── Routines Section ───────────────────────────────────────────────────────────
class _RoutinesSection extends StatelessWidget {
  final List<WorkoutSession> routines;
  final WidgetRef ref;
  const _RoutinesSection({required this.routines, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('My Routines', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('(${routines.length})', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          if (routines.isEmpty) ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.content_paste_search_rounded, color: AppColors.textMuted, size: 72),
                  const SizedBox(height: 16),
                  Text('Tap the + button to start a blank workout', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Save your workouts as routines to see them here', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: routines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _RoutineCard(routine: routines[i], ref: ref),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  final WorkoutSession routine;
  final WidgetRef ref;
  const _RoutineCard({required this.routine, required this.ref});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.7),
          gradient: LinearGradient(
            colors: [AppColors.card, AppColors.card.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref.read(activeWorkoutProvider.notifier).startFromRoutine(routine),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppColors.blueLight, size: 22),
              ),
            ),
            const SizedBox(width: 8),

            // AI Launch
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PoseTrackerScreen(routine: routine),
                ));
              },
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.videocam_rounded, color: AppColors.green, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => ref.read(activeWorkoutProvider.notifier).startFromRoutine(routine),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(routine.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                     Text('${routine.exercises.length} Exercises', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                ref.read(workoutEditorProvider.notifier).init(routine, true);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditWorkoutScreen()));
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Delete routine
                ref.read(routinesProvider.notifier).remove(routine.id);
              },
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Start Workout Sheet ────────────────────────────────────────────────────────
class _StartWorkoutSheet extends StatefulWidget {
  final WidgetRef ref;
  const _StartWorkoutSheet({required this.ref});
  @override
  State<_StartWorkoutSheet> createState() => _StartWorkoutSheetState();
}

class _StartWorkoutSheetState extends State<_StartWorkoutSheet> {
  final _controller = TextEditingController(text: 'My Workout');

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text('Name this workout', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.card,
                hintText: 'e.g. Push Day A',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final name = _controller.text.trim().isEmpty ? 'My Workout' : _controller.text.trim();
                  widget.ref.read(activeWorkoutProvider.notifier).start(name);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Start Workout', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Button ───────────────────────────────────────────────────────────────
class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.cardButton,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.blueLight, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Glow FAB ───────────────────────────────────────────────────────────────────
class _GlowFab extends StatelessWidget {
  final VoidCallback onTap;
  const _GlowFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.blueDark, AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.45), blurRadius: 16, spreadRadius: 2)],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
