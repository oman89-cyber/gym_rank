import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/models/logged_exercise.dart';
import '../../../core/models/exercise_set.dart';
import '../../../core/providers/profile_provider.dart';
import 'exercise_picker_sheet.dart';
import '../../../core/models/workout_session.dart';
import '../post_workout_summary_screen.dart';

/// Shown when there is an active workout session in progress.
class ActiveSessionView extends ConsumerWidget {
  const ActiveSessionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(activeWorkoutProvider);
    
    // Safety check: state cleared after finishing — return invisible widget
    // so the parent WorkoutScreen transitions cleanly to idle view.
    if (session == null) {
      return const SizedBox.shrink();
    }
    
    final useKg = ref.watch(profileProvider).useKg;
    final unit = useKg ? 'kg' : 'lbs';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _SessionHeader(
                    name: session.name,
                    volume: session.totalVolume,
                    unit: unit,
                    isStarted: session.isStarted),
                const _RestTimerBanner(),
                Expanded(
                  child: session.exercises.isEmpty
                      ? const _EmptyHint()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: session.exercises.length,
                          itemBuilder: (ctx, i) => _ExerciseCard(
                            index: i,
                            exercise: session.exercises[i],
                            useKg: useKg,
                          ),
                        ),
                ),
                if (session.isStarted) _BottomActions(ref: ref),
              ],
            ),
            if (!session.isStarted) Positioned.fill(child: _StartOverlay(ref: ref)),
          ],
        ),
      ),
    );
  }
}

class _StartOverlay extends StatelessWidget {
  final WidgetRef ref;
  const _StartOverlay({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.7),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: AppColors.blueLight, size: 64),
              ),
              const SizedBox(height: 24),
              Text('Ready to Level Up?',
                  style: GoogleFonts.rajdhani(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Your timer will start once you hit the button.',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: () =>
                      ref.read(activeWorkoutProvider.notifier).startWorkout(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('START WORKOUT',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Session Header ─────────────────────────────────────────────────────────────
class _SessionHeader extends StatelessWidget {
  final String name;
  final double volume;
  final String unit;
  final bool isStarted;
  const _SessionHeader(
      {required this.name,
      required this.volume,
      required this.unit,
      required this.isStarted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${volume.toStringAsFixed(0)} $unit total volume',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (isStarted) const _LiveTimer() else _InactiveTimerPlaceholder(),
        ],
      ),
    );
  }
}

class _InactiveTimerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('00:00',
          style: GoogleFonts.rajdhani(
              color: AppColors.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _LiveTimer extends ConsumerStatefulWidget {
  const _LiveTimer();
  @override
  ConsumerState<_LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends ConsumerState<_LiveTimer> {
  late final Stream<int> _ticks;
  @override
  void initState() {
    super.initState();
    _ticks = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  @override
  Widget build(BuildContext context) {
    final startTime =
        ref.watch(activeWorkoutProvider)?.startTime ?? DateTime.now();

    return StreamBuilder<int>(
      stream: _ticks,
      builder: (_, snap) {
        final now = DateTime.now();
        final diff = now.difference(startTime).inSeconds;
        final s = diff > 0 ? diff : 0;
        final m = s ~/ 60;
        final sec = s % 60;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
              '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
              style: GoogleFonts.rajdhani(
                  color: AppColors.blueLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        );
      },
    );
  }
}

// ── Rest Timer Banner ──────────────────────────────────────────────────────────
class _RestTimerBanner extends ConsumerWidget {
  const _RestTimerBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);
    if (timer == null || timer <= 0) return const SizedBox.shrink();

    final m = timer ~/ 60;
    final s = timer % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.blue.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.blueLight, size: 18),
          const SizedBox(width: 8),
          Text('Resting: $timeStr',
              style: GoogleFonts.rajdhani(
                  color: AppColors.blueLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: () => ref.read(restTimerProvider.notifier).addTime(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('+30s',
                  style: GoogleFonts.inter(
                      color: AppColors.blueLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => ref.read(restTimerProvider.notifier).stop(),
            child: Text('Skip',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Card ──────────────────────────────────────────────────────────────
class _ExerciseCard extends ConsumerWidget {
  final int index;
  final LoggedExercise exercise;
  final bool useKg;

  const _ExerciseCard({
    required this.index,
    required this.exercise,
    required this.useKg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastPerf = ref.watch(lastExercisePerformanceProvider(exercise.name));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Exercise Name and Options
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text(
                          exercise.muscleGroup[0].toUpperCase() +
                              exercise.muscleGroup.substring(1),
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded,
                      color: AppColors.textMuted),
                  onPressed: () => _showExerciseOptions(context, ref),
                ),
              ],
            ),
          ),

          // Column Headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                    width: 30,
                    child: Text('SET',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5))),
                const SizedBox(width: 8),
                Expanded(
                    flex: 1,
                    child: Text('WEIGHT',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5))),
                Expanded(
                    flex: 1,
                    child: Text('REPS',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5))),
                const SizedBox(width: 44), // For the checkmark
              ],
            ),
          ),

          // Sets list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exercise.sets.length,
            itemBuilder: (ctx, setIdx) {
              return _SetRow(
                key: ValueKey(exercise.sets[setIdx].id),
                exerciseIndex: index,
                exerciseName: exercise.name,
                setIndex: setIdx,
                set: exercise.sets[setIdx],
                useKg: useKg,
              );
            },
          ),

          // Add Set Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                // Determine values for new set from last performance or sensible defaults
                int reps = 10;
                double weight = 20;

                if (exercise.sets.isNotEmpty) {
                    reps = exercise.sets.last.reps;
                    weight = exercise.sets.last.weightKg;
                } else if (lastPerf != null && lastPerf.sets.isNotEmpty) {
                    reps = lastPerf.sets.first.reps;
                    weight = lastPerf.sets.first.weightKg;
                }

                ref.read(activeWorkoutProvider.notifier).addSet(
                      index,
                      ExerciseSet(
                        reps: reps,
                        weightKg: weight,
                        isBodyweight: false,
                      ),
                    );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: AppColors.blueLight, size: 20),
                    const SizedBox(width: 8),
                    Text('ADD SET',
                        style: GoogleFonts.inter(
                            color: AppColors.blueLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline_rounded, color: AppColors.red),
              title: Text('Remove Exercise',
                  style: GoogleFonts.inter(color: AppColors.red)),
              onTap: () {
                ref.read(activeWorkoutProvider.notifier).removeExercise(index);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Set Row ────────────────────────────────────────────────────────────────────
class _SetRow extends ConsumerStatefulWidget {
  final int exerciseIndex;
  final String exerciseName;
  final int setIndex;
  final ExerciseSet set;
  final bool useKg;

  const _SetRow({
    super.key,
    required this.exerciseIndex,
    required this.exerciseName,
    required this.setIndex,
    required this.set,
    required this.useKg,
  });

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSetSheet(
        exerciseIndex: widget.exerciseIndex,
        setIndex: widget.setIndex,
        set: widget.set,
        useKg: widget.useKg,
        ref: ref,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.set.isCompleted;
    final weightValue = widget.useKg ? widget.set.weightKg : widget.set.weightKg * 2.20462;

    return GestureDetector(
      onTap: () => _showEditSheet(context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isCompleted
            ? AppColors.blue.withValues(alpha: 0.05)
            : Colors.transparent,
        child: Row(
          children: [
            // Set Index Circle
            SizedBox(
              width: 30,
              child: Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.blue.withValues(alpha: 0.2)
                      : AppColors.border.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.setIndex + 1}',
                    style: GoogleFonts.rajdhani(
                      color: isCompleted ? AppColors.blueLight : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Weight Display
            Expanded(
              flex: 1,
              child: Text(
                widget.set.isBodyweight ? 'BW' : weightValue.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Reps Display
            Expanded(
              flex: 1,
              child: Text(
                '${widget.set.reps}',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Complete Toggle
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(activeWorkoutProvider.notifier).toggleSetComplete(
                      widget.exerciseIndex,
                      widget.setIndex,
                    );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.blue : AppColors.border.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: isCompleted ? Colors.white : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSetSheet extends StatefulWidget {
  final int exerciseIndex;
  final int setIndex;
  final ExerciseSet set;
  final bool useKg;
  final WidgetRef ref;

  const _EditSetSheet({
    required this.exerciseIndex,
    required this.setIndex,
    required this.set,
    required this.useKg,
    required this.ref,
  });

  @override
  State<_EditSetSheet> createState() => _EditSetSheetState();
}

class _EditSetSheetState extends State<_EditSetSheet> {
  late int _reps;
  late double _weight;
  late bool _isBodyweight;

  @override
  void initState() {
    super.initState();
    _reps = widget.set.reps;
    _weight = widget.useKg ? widget.set.weightKg : widget.set.weightKg * 2.20462;
    _isBodyweight = widget.set.isBodyweight;
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.useKg ? 'kg' : 'lbs';
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Edit Set ${widget.setIndex + 1}',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          _stepper('Reps', _reps, 1, 0, 100,
              (v) => setState(() => _reps = v.toInt())),
          const SizedBox(height: 16),
          if (!_isBodyweight)
            _stepper('Weight ($unit)', _weight, 2.5, 0, 1000,
                (v) => setState(() => _weight = v)),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _isBodyweight,
                activeColor: AppColors.blue,
                onChanged: (v) => setState(() => _isBodyweight = v ?? false),
              ),
              Text('Bodyweight Exercise',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.ref
                        .read(activeWorkoutProvider.notifier)
                        .removeSet(widget.exerciseIndex, widget.setIndex);
                    Navigator.pop(context);
                  },
                  child: Text('Delete Set',
                      style: GoogleFonts.inter(
                          color: AppColors.red, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    final weightKg = widget.useKg ? _weight : _weight / 2.20462;
                    widget.ref.read(activeWorkoutProvider.notifier).updateSet(
                          widget.exerciseIndex,
                          widget.setIndex,
                          widget.set.copyWith(
                              reps: _reps,
                              weightKg: weightKg,
                              isBodyweight: _isBodyweight),
                        );
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Changes',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepper(String label, num value, double step, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        _StepButton(
            icon: Icons.remove_rounded,
            onTap: () {
              if (value - step >= min) onChanged(value.toDouble() - step);
            }),
        const SizedBox(width: 20),
        SizedBox(
          width: 70,
          child: Center(
            child: Text(
                value is int ? value.toString() : value.toStringAsFixed(1),
                style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 20),
        _StepButton(
            icon: Icons.add_rounded,
            onTap: () {
              if (value + step <= max) onChanged(value.toDouble() + step);
            }),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 24),
      ),
    );
  }
}

// ── Bottom Actions ─────────────────────────────────────────────────────────────
class _BottomActions extends StatelessWidget {
  final WidgetRef ref;
  const _BottomActions({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(
        children: [
          // Discard
          GestureDetector(
            onTap: () => _confirmDiscard(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.red, size: 20),
            ),
          ),
          const SizedBox(width: 8),

          // Save as Routine
          GestureDetector(
            onTap: () {
               final session = ref.read(activeWorkoutProvider);
               if (session != null && session.exercises.isNotEmpty) {
                  final routine = WorkoutSession(
                    id: const Uuid().v4(),
                    date: DateTime.now(),
                    name: session.name,
                    exercises: session.exercises,
                    durationSeconds: 0,
                  );
                  ref.read(routinesProvider.notifier).save(routine);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved as routine', style: GoogleFonts.inter(color: Colors.white)),
                      backgroundColor: AppColors.blue,
                      duration: const Duration(seconds: 2),
                    )
                  );
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Add exercises first', style: GoogleFonts.inter(color: Colors.white)),
                      backgroundColor: AppColors.card,
                    )
                  );
               }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.bookmark_add_rounded,
                  color: AppColors.gold, size: 20),
            ),
          ),
          const SizedBox(width: 8),

          // Add Exercise
          Expanded(
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ExercisePickerSheet(ref: ref),
              ),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: AppColors.blueLight, size: 20),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ADD',
                          style: GoogleFonts.inter(
                              color: AppColors.blueLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Finish
          GestureDetector(
            onTap: () => _finish(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.blueDark, AppColors.blue]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text('FINISH',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish(BuildContext context) async {
    final session = ref.read(activeWorkoutProvider);
    if (session == null || session.exercises.isEmpty) {
      ref.read(activeWorkoutProvider.notifier).discard();
      return;
    }
    
    // Capture ELO before saving
    final oldElo = ref.read(profileProvider).eloScore;

    final result = await ref.read(activeWorkoutProvider.notifier).finish(const Uuid().v4());
    
    if (result != null && context.mounted) {
       final newElo = ref.read(profileProvider).eloScore;
       // Push the Summary Screen over the main app structure. 
       // When user taps continue, they will pop back to the idle WorkoutScreen.
       Navigator.of(context).push(
         MaterialPageRoute(
           builder: (_) => PostWorkoutSummaryScreen(
             session: result,
             eloGained: newElo - oldElo,
           ),
         ),
       );
    }
  }

  void _confirmDiscard(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Discard workout?',
            style: GoogleFonts.inter(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('All logged progress will be lost.',
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).discard();
              Navigator.pop(context);
            },
            child: Text('Discard',
                style: GoogleFonts.inter(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Empty hint ─────────────────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded,
                color: AppColors.textMuted, size: 64),
          ),
          const SizedBox(height: 24),
          Text('Your workout is empty',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Tap "Add Exercise" to start tracking',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
