import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/workout_providers.dart';
import '../../../core/models/workout_session.dart';
import '../edit_workout_screen.dart';

class HistorySheet extends ConsumerWidget {
  const HistorySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.97,
      minChildSize: 0.4,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text('Workout History', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${sessions.length} sessions', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? Center(child: Text('No workouts yet', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)))
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: sessions.length,
                      itemBuilder: (_, i) => _SessionTile(session: sessions[i], ref: ref),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WorkoutSession session;
  final WidgetRef ref;
  const _SessionTile({required this.session, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dur = Duration(seconds: session.durationSeconds);
    final mins = dur.inMinutes;
    final dateStr = '${session.date.day}/${session.date.month}/${session.date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.fitness_center_rounded, color: AppColors.blueLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('$dateStr • ${mins}min • ${session.totalSets} sets • ${session.totalVolume.toStringAsFixed(0)} kg',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(workoutEditorProvider.notifier).init(session, false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditWorkoutScreen()));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete session?', style: GoogleFonts.inter(color: AppColors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              ref.read(sessionsProvider.notifier).remove(session.id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.inter(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
