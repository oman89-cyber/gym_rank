import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/workout_providers.dart';
import '../../core/models/logged_exercise.dart';
import '../../core/models/exercise_set.dart';
import '../../core/providers/profile_provider.dart';
import 'widgets/exercise_picker_sheet.dart';

class EditWorkoutScreen extends ConsumerWidget {
  const EditWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workoutEditorProvider);
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final useKg = ref.watch(profileProvider).useKg;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Workout', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(workoutEditorProvider.notifier).save();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Changes saved! 🎉', style: GoogleFonts.inter()),
                    backgroundColor: AppColors.blue,
                  ),
                );
              }
            },
            child: Text('Save', style: GoogleFonts.inter(color: AppColors.blueLight, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _NameHeader(name: session.name, ref: ref),
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
                      ref: ref,
                    ),
                  ),
          ),
          _BottomActions(ref: ref, useKg: useKg),
        ],
      ),
    );
  }
}

class _NameHeader extends StatelessWidget {
  final String name;
  final WidgetRef ref;
  const _NameHeader({required this.name, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: TextEditingController(text: name)..selection = TextSelection.collapsed(offset: name.length),
        onChanged: (v) => ref.read(workoutEditorProvider.notifier).updateName(v),
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          hintText: 'Workout Name',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final int index;
  final LoggedExercise exercise;
  final bool useKg;
  final WidgetRef ref;

  const _ExerciseCard({required this.index, required this.exercise, required this.useKg, required this.ref});

  @override
  Widget build(BuildContext context) {
    final unit = useKg ? 'kg' : 'lbs';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(exercise.muscleGroup[0].toUpperCase() + exercise.muscleGroup.substring(1),
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(workoutEditorProvider.notifier).removeExercise(index),
                  child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('Set', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                Expanded(child: Text('Reps', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Weight ($unit)', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600))),
                const SizedBox(width: 32),
              ],
            ),
          ),
          ...exercise.sets.asMap().entries.map((entry) => _SetRow(
            exerciseIndex: index,
            setIndex: entry.key,
            set: entry.value,
            useKg: useKg,
            ref: ref,
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: GestureDetector(
              onTap: () => _showAddSetSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: AppColors.blueLight, size: 18),
                    const SizedBox(width: 6),
                    Text('Add Set', style: GoogleFonts.inter(color: AppColors.blueLight, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSetSheet(exerciseIndex: index, useKg: useKg, ref: ref),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int exerciseIndex;
  final int setIndex;
  final ExerciseSet set;
  final bool useKg;
  final WidgetRef ref;
  const _SetRow({required this.exerciseIndex, required this.setIndex, required this.set, required this.useKg, required this.ref});

  @override
  Widget build(BuildContext context) {
    final weight = useKg ? set.weightKg : set.weightKg * 2.20462;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(child: Text('${setIndex + 1}', style: GoogleFonts.inter(color: AppColors.blueLight, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('${set.reps}', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
          Expanded(child: Text(set.isBodyweight ? 'BW' : '${weight.toStringAsFixed(1)}', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
          GestureDetector(
            onTap: () => ref.read(workoutEditorProvider.notifier).removeSet(exerciseIndex, setIndex),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
          ),
        ],
      ),
    );
  }
}

class _AddSetSheet extends StatefulWidget {
  final int exerciseIndex;
  final bool useKg;
  final WidgetRef ref;
  const _AddSetSheet({required this.exerciseIndex, required this.useKg, required this.ref});
  @override
  State<_AddSetSheet> createState() => _AddSetSheetState();
}

class _AddSetSheetState extends State<_AddSetSheet> {
  int _reps = 10;
  double _weight = 20;
  bool _isBodyweight = false;

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
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 20),
          Text('Log Set', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          _stepper('Reps', _reps, 1, 1, 100, (v) => setState(() => _reps = v.toInt())),
          const SizedBox(height: 16),
          if (!_isBodyweight)
            _stepper('Weight ($unit)', _weight, 2.5, 0, 500, (v) => setState(() => _weight = v)),
          Row(
            children: [
              Checkbox(
                value: _isBodyweight,
                activeColor: AppColors.blue,
                onChanged: (v) => setState(() => _isBodyweight = v ?? false),
              ),
              Text('Bodyweight', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final weightKg = widget.useKg ? _weight : _weight / 2.20462;
                widget.ref.read(workoutEditorProvider.notifier).addSet(
                  widget.exerciseIndex,
                  ExerciseSet(reps: _reps, weightKg: weightKg, isBodyweight: _isBodyweight),
                );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Add Set', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepper(String label, num value, double step, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
        const Spacer(),
        _StepButton(
          icon: Icons.remove_rounded,
          onTap: () { if (value - step >= min) onChanged(value.toDouble() - step); },
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 60,
          child: Center(child: Text(value is int ? value.toString() : (value as double).toStringAsFixed(1),
              style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 16),
        _StepButton(
          icon: Icons.add_rounded,
          onTap: () { if (value + step <= max) onChanged(value.toDouble() + step); },
        ),
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
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final WidgetRef ref;
  final bool useKg;
  const _BottomActions({required this.ref, required this.useKg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ExercisePickerSheet(
                  ref: ref,
                  onSelect: (ex) {
                    ref.read(workoutEditorProvider.notifier).addExercise(ex);
                  },
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: AppColors.blueLight, size: 20),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Add Exercise', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await ref.read(workoutEditorProvider.notifier).save();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Changes saved! 🎉', style: GoogleFonts.inter()),
                    backgroundColor: AppColors.blue,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.blueDark, AppColors.blue]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.edit_note_rounded, color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text('No exercises in this workout', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
