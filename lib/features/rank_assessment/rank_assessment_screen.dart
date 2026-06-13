import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';

// ── Assessment Question Model ─────────────────────────────────────────────────
class _AssessmentQuestion {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String unit;
  final int min;
  final int max;
  final double eloMultiplier; // how much each unit of this answer contributes to baseElo

  const _AssessmentQuestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.unit,
    required this.min,
    required this.max,
    required this.eloMultiplier,
  });
}

const _questions = [
  _AssessmentQuestion(
    id: 'pushups',
    title: 'Push-Ups',
    subtitle: 'How many push-ups can you do in one go?',
    icon: Icons.fitness_center_rounded,
    unit: 'reps',
    min: 0,
    max: 100,
    eloMultiplier: 1.5,
  ),
  _AssessmentQuestion(
    id: 'pullups',
    title: 'Pull-Ups',
    subtitle: 'How many pull-ups can you do in one go?',
    icon: Icons.arrow_upward_rounded,
    unit: 'reps',
    min: 0,
    max: 50,
    eloMultiplier: 4.0,
  ),
  _AssessmentQuestion(
    id: 'squats',
    title: 'Bodyweight Squats',
    subtitle: 'How many squats can you do without weight?',
    icon: Icons.directions_run_rounded,
    unit: 'reps',
    min: 0,
    max: 200,
    eloMultiplier: 0.8,
  ),
  _AssessmentQuestion(
    id: 'bench',
    title: 'Bench Press',
    subtitle: 'What\'s your max bench press? (0 if you haven\'t tested)',
    icon: Icons.horizontal_rule_rounded,
    unit: 'kg',
    min: 0,
    max: 250,
    eloMultiplier: 1.2,
  ),
  _AssessmentQuestion(
    id: 'squat_max',
    title: 'Barbell Squat',
    subtitle: 'What\'s your max squat? (0 if you haven\'t tested)',
    icon: Icons.sports_gymnastics_rounded,
    unit: 'kg',
    min: 0,
    max: 350,
    eloMultiplier: 1.0,
  ),
  _AssessmentQuestion(
    id: 'deadlift',
    title: 'Deadlift',
    subtitle: 'What\'s your max deadlift? (0 if you haven\'t tested)',
    icon: Icons.moving_rounded,
    unit: 'kg',
    min: 0,
    max: 400,
    eloMultiplier: 1.1,
  ),
  _AssessmentQuestion(
    id: 'training_years',
    title: 'Training Experience',
    subtitle: 'How many years have you been training consistently?',
    icon: Icons.calendar_today_rounded,
    unit: 'years',
    min: 0,
    max: 20,
    eloMultiplier: 25.0,
  ),
];

// ── Rank Assessment Screen ─────────────────────────────────────────────────────
class RankAssessmentScreen extends ConsumerStatefulWidget {
  const RankAssessmentScreen({super.key});

  @override
  ConsumerState<RankAssessmentScreen> createState() =>
      _RankAssessmentScreenState();
}

class _RankAssessmentScreenState extends ConsumerState<RankAssessmentScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0; // -1 = intro, 0..n-1 = questions, n = result
  final Map<String, int> _answers = {};
  double _computedBaseElo = 0;
  bool _isSaving = false;

  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: 600.ms);
    _currentStep = -1; // Start at intro
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  int get _questionIndex => _currentStep; // 0-based when on a question
  bool get _isIntro => _currentStep == -1;
  bool get _isResult => _currentStep == _questions.length;

  void _startAssessment() {
    setState(() => _currentStep = 0);
  }

  void _answerQuestion(int value) {
    final q = _questions[_questionIndex];
    _answers[q.id] = value;

    _progressController.animateTo((_questionIndex + 1) / _questions.length);

    if (_questionIndex < _questions.length - 1) {
      setState(() => _currentStep++);
    } else {
      _computedBaseElo = _calculateBaseElo();
      setState(() => _currentStep = _questions.length);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else if (_currentStep == 0) {
      setState(() => _currentStep = -1);
    }
  }

  double _calculateBaseElo() {
    double score = 0;
    for (final q in _questions) {
      final answer = _answers[q.id] ?? 0;
      score += answer * q.eloMultiplier;
    }
    // Apply log-scaling similar to EloService
    // Raw score → 0–800 range (so they still have room to grow)
    final scaled = 800 * (1 - (1 / (1 + score / 300)));
    return scaled.clamp(0, 800);
  }

  String _rankFromElo(double elo) {
    if (elo >= 800) return 'A';
    if (elo >= 500) return 'B';
    if (elo >= 300) return 'C';
    if (elo >= 150) return 'D';
    if (elo >= 50) return 'E';
    return 'F';
  }

  String _rankLabelFromElo(double elo) {
    final r = _rankFromElo(elo);
    switch (r) {
      case 'A':  return 'Elite';
      case 'B':  return 'Adept';
      case 'C':  return 'Warrior';
      case 'D':  return 'Strongman';
      case 'E':  return 'Recruit';
      default:   return 'Newbie';
    }
  }

  Color _rankColor(String rank) {
    switch (rank) {
      case 'A':  return const Color(0xFF22D3EE);
      case 'B':  return const Color(0xFF4ADE80);
      case 'C':  return const Color(0xFFFBBF24);
      case 'D':  return const Color(0xFFF97316);
      case 'E':  return const Color(0xFFEC4899);
      default:   return AppColors.textMuted;
    }
  }

  Future<void> _confirmRank() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(profileProvider.notifier);
      // Update baseElo and also set eloScore to this baseElo immediately
      final updated = ref.read(profileProvider).copyWith(
        baseElo: _computedBaseElo,
        eloScore: _computedBaseElo,
      );
      await notifier.updateProfile(updated);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: 400.ms,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: const Offset(0.05, 0), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: _isIntro
              ? _IntroPage(key: const ValueKey('intro'), onStart: _startAssessment)
              : _isResult
                  ? _ResultPage(
                      key: const ValueKey('result'),
                      baseElo: _computedBaseElo,
                      rank: _rankFromElo(_computedBaseElo),
                      rankLabel: _rankLabelFromElo(_computedBaseElo),
                      rankColor: _rankColor(_rankFromElo(_computedBaseElo)),
                      answers: _answers,
                      isSaving: _isSaving,
                      onConfirm: _confirmRank,
                      onRetake: () => setState(() {
                        _currentStep = -1;
                        _answers.clear();
                      }),
                    )
                  : _QuestionPage(
                      key: ValueKey(_currentStep),
                      question: _questions[_questionIndex],
                      questionNumber: _questionIndex + 1,
                      totalQuestions: _questions.length,
                      progress: (_questionIndex) / _questions.length,
                      previousAnswer: _answers[_questions[_questionIndex].id],
                      onAnswer: _answerQuestion,
                      onBack: _currentStep > 0 || _currentStep == 0 ? _goBack : null,
                    ),
        ),
      ),
    );
  }
}

// ── Intro Page ─────────────────────────────────────────────────────────────────
class _IntroPage extends StatelessWidget {
  final VoidCallback onStart;
  const _IntroPage({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.blue.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.shield_outlined, color: AppColors.blue, size: 40),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 28),
            Text(
              'CHECK YOUR\nRANK',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 0.9,
                letterSpacing: 1,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),
            Text(
              'Already strong? Don\'t start from F-rank.\nAnswer ${_questions.length} quick questions about your current fitness level and get placed where you truly belong.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 36),
            // Benefits
            ...[
              ('🏋️', 'Get accurately placed based on real performance'),
              ('📊', 'Skip ranks you\'ve already earned outside the app'),
              ('⚡', 'Takes less than 2 minutes to complete'),
              ('🔒', 'Can only be done once to keep rankings fair'),
            ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(item.$2,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05)),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  shadowColor: AppColors.blue.withValues(alpha: 0.4),
                  elevation: 12,
                ),
                child: Text(
                  'BEGIN ASSESSMENT',
                  style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

// ── Question Page ──────────────────────────────────────────────────────────────
class _QuestionPage extends StatefulWidget {
  final _AssessmentQuestion question;
  final int questionNumber;
  final int totalQuestions;
  final double progress;
  final int? previousAnswer;
  final void Function(int value) onAnswer;
  final VoidCallback? onBack;

  const _QuestionPage({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.progress,
    required this.onAnswer,
    this.previousAnswer,
    this.onBack,
  });

  @override
  State<_QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<_QuestionPage> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.previousAnswer ?? widget.question.min;
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${widget.questionNumber} / ${widget.totalQuestions}',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.progress,
                        backgroundColor: AppColors.border,
                        color: AppColors.blue,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blue.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
            ),
            child: Icon(q.icon, color: AppColors.blue, size: 30),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 24),

          Text(q.title,
              style: GoogleFonts.rajdhani(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900)),

          const SizedBox(height: 8),

          Text(q.subtitle,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 15, height: 1.5)),

          const Spacer(),

          // Big value display
          Center(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: 150.ms,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    '$_value',
                    key: ValueKey(_value),
                    style: GoogleFonts.rajdhani(
                      color: AppColors.blue,
                      fontSize: 90,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                Text(q.unit,
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              activeTrackColor: AppColors.blue,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.blue,
              overlayColor: AppColors.blue.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _value.toDouble(),
              min: q.min.toDouble(),
              max: q.max.toDouble(),
              divisions: q.max - q.min,
              onChanged: (v) => setState(() => _value = v.round()),
            ),
          ),

          // Range labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${q.min} ${q.unit}',
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
                Text('${q.max} ${q.unit}',
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onAnswer(_value),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                widget.questionNumber == widget.totalQuestions
                    ? 'SEE MY RANK'
                    : 'NEXT',
                style: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Result Page ────────────────────────────────────────────────────────────────
class _ResultPage extends StatelessWidget {
  final double baseElo;
  final String rank;
  final String rankLabel;
  final Color rankColor;
  final Map<String, int> answers;
  final bool isSaving;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const _ResultPage({
    super.key,
    required this.baseElo,
    required this.rank,
    required this.rankLabel,
    required this.rankColor,
    required this.answers,
    required this.isSaving,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Big rank display
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rankColor.withValues(alpha: 0.08),
                    border:
                        Border.all(color: rankColor.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: rankColor.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(rank,
                        style: GoogleFonts.rajdhani(
                            color: rankColor,
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            height: 1)),
                    Text(rankLabel,
                        style: GoogleFonts.inter(
                            color: rankColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ],
                ),
              ],
            ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),

            const SizedBox(height: 28),

            Text('YOUR STARTING RANK',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Based on your assessment, you\'ve been placed at ${baseElo.round()} ELO',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 15, height: 1.5),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // Answer summary card
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: _questions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final q = entry.value;
                  final val = answers[q.id] ?? 0;
                  return Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Icon(q.icon, color: AppColors.blueLight, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(q.title,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 14)),
                            ),
                            Text('$val ${q.unit}',
                                style: GoogleFonts.rajdhani(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      if (i < _questions.length - 1)
                        Divider(
                            height: 1,
                            color: AppColors.border.withValues(alpha: 0.6),
                            indent: 16,
                            endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

            const SizedBox(height: 36),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving ? null : onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: rankColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  shadowColor: rankColor.withValues(alpha: 0.4),
                  elevation: 10,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2.5))
                    : Text('CONFIRM MY RANK',
                        style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 1.5)),
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 12),

            // Retake button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onRetake,
                child: Text('Retake Assessment',
                    style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
