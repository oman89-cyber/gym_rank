import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/workout_session.dart';
import '../../core/providers/profile_provider.dart';

class PostWorkoutSummaryScreen extends ConsumerStatefulWidget {
  final WorkoutSession session;
  final double eloGained;

  const PostWorkoutSummaryScreen({
    super.key,
    required this.session,
    required this.eloGained,
  });

  @override
  ConsumerState<PostWorkoutSummaryScreen> createState() => _PostWorkoutSummaryScreenState();
}

class _PostWorkoutSummaryScreenState extends ConsumerState<PostWorkoutSummaryScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final useKg = profile.useKg;
    final vol = useKg ? widget.session.totalVolume : widget.session.totalVolume * 2.20462;
    final unit = useKg ? 'kg' : 'lbs';

    final minutes = widget.session.durationSeconds ~/ 60;
    final seconds = widget.session.durationSeconds % 60;
    final durationStr = '${minutes}m ${seconds}s';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 64),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Workout Complete!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    widget.session.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 48),

                  // ELO Gained
                  if (widget.eloGained > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.blueDark, AppColors.blue]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text('RANK PROGRESS',
                              style: GoogleFonts.inter(color: AppColors.blueLight, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('+${widget.eloGained.toInt()}',
                                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text('ELO',
                                    style: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),
                    const SizedBox(height: 24),
                  ],

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Volume',
                          value: '${vol.toStringAsFixed(0)} $unit',
                          icon: Icons.fitness_center_rounded,
                        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          label: 'Duration',
                          value: durationStr,
                          icon: Icons.timer_outlined,
                        ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _StatCard(
                    label: 'Summary',
                    value: '${widget.session.exercises.length} Exercises, ${widget.session.totalSets} Sets',
                    icon: Icons.list_alt_rounded,
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
                  const SizedBox(height: 48),

                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Continue', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                  ).animate().fadeIn(delay: 1000.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [AppColors.blue, AppColors.gold, AppColors.green, Colors.white],
            createParticlePath: drawStar,
          ),
        ],
      ),
    );
  }

  Path drawStar(Size size) {
    // Star path generator for confetti
    double vw = size.width / 2;
    double vh = size.height / 2;
    Path path = Path();
    path.moveTo(vw, 0);
    path.lineTo(vw + size.width * 0.15, vh - size.height * 0.15);
    path.lineTo(size.width, vh - size.height * 0.15);
    path.lineTo(vw + size.width * 0.25, vh + size.height * 0.1);
    path.lineTo(vw + size.width * 0.35, size.height);
    path.lineTo(vw, vh + size.height * 0.25);
    path.lineTo(vw - size.width * 0.35, size.height);
    path.lineTo(vw - size.width * 0.25, vh + size.height * 0.1);
    path.lineTo(0, vh - size.height * 0.15);
    path.lineTo(vw - size.width * 0.15, vh - size.height * 0.15);
    path.close();
    return path;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.blue, size: 24),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
