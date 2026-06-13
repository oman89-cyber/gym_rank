import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/exercise_library_provider.dart';
import '../../../core/models/logged_exercise.dart';
import '../../../core/providers/workout_providers.dart';

/// Bottom sheet that lets the user search and pick an exercise.
class ExercisePickerSheet extends StatefulWidget {
  final WidgetRef ref;
  final void Function(LoggedExercise)? onSelect;
  const ExercisePickerSheet({super.key, required this.ref, this.onSelect});
  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Add Exercise', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, _) {
                  final asyncExercises = ref.watch(exerciseLibraryProvider);
                  
                  return asyncExercises.when(
                    data: (exercises) {
                      final q = _query.toLowerCase();
                      final results = q.isEmpty
                          ? exercises
                          : exercises.where((e) => e.name.toLowerCase().contains(q)).toList();

                      return ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (_, i) {
                          final ex = results[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fitness_center_rounded, color: AppColors.blueLight, size: 20),
                    ),
                    title: Text(ex.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      ex.primaryMuscle[0].toUpperCase() + ex.primaryMuscle.substring(1),
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: ex.isBodyweight
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('BW', style: GoogleFonts.inter(color: AppColors.blueLight, fontSize: 11, fontWeight: FontWeight.w600)),
                          )
                        : null,
                    onTap: () {
                      final loggedEx = LoggedExercise(
                        name: ex.name,
                        muscleGroup: ex.primaryMuscle,
                        rawMuscles: ex.rawMuscles,
                        sets: [],
                      );

                      if (widget.onSelect != null) {
                        widget.onSelect!(loggedEx);
                      } else {
                        widget.ref.read(activeWorkoutProvider.notifier).addExercise(loggedEx);
                      }
                      Navigator.pop(context);
                    },
                  );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blueLight)),
                    error: (err, stack) => Center(child: Text('Error loading exercises\n$err')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
