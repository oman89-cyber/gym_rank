import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/ai_coach_provider.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _customNotesController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _customNotesController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachWizardProvider);
    final notifier = ref.read(aiCoachWizardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('AI Coach Wizard', style: GoogleFonts.rajdhani(
          color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800,
        )),
        actions: [
          if (state.generatedProgram.isNotEmpty && !state.isGenerating)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.blueLight),
              onPressed: () => notifier.reset(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Step Progress
          if (state.generatedProgram.isEmpty)
            _ProgressHeader(currentStep: state.currentStep),

          Expanded(
            child: state.generatedProgram.isNotEmpty
                ? _ProgramResultView(
                    program: state.generatedProgram, 
                    isGenerating: state.isGenerating,
                    routinesAdded: state.routinesAdded,
                  )
                : PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => notifier.setStep(idx),
                    children: [
                      _StepFrequency(
                        value: state.frequency,
                        onChanged: (v) {
                          notifier.setFrequency(v);
                          _nextPage();
                        },
                      ),
                      _StepSplit(
                        frequency: state.frequency,
                        selected: state.split,
                        onChanged: (v) {
                          notifier.setSplit(v);
                          _nextPage();
                        },
                      ),
                      _StepEquipment(
                        selected: state.equipment,
                        onToggle: notifier.toggleEquipment,
                        onNext: _nextPage,
                      ),
                      _StepStyle(
                        selected: state.style,
                        onChanged: (v) {
                          notifier.setStyle(v);
                          _nextPage();
                        },
                      ),
                      _StepCustomization(
                        controller: _customNotesController,
                        onChanged: notifier.setCustomNotes,
                        onCreate: notifier.generateProgram,
                        isGenerating: state.isGenerating,
                      ),
                    ],
                  ),
          ),

          // Bottom Navigation
          if (state.generatedProgram.isEmpty)
            _BottomNav(
              currentStep: state.currentStep,
              onBack: _previousPage,
              onNext: _nextPage,
              showNext: state.currentStep == 2, // Only show "Next" for multi-select (Equipment)
            ),
        ],
      ),
    );
  }
}

// ── Progress Header ───────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final int currentStep;
  const _ProgressHeader({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${currentStep + 1}/5', style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700,
              )),
              if (currentStep > 0)
                _PremiumBanner(),
            ],
          ),
        ),
        Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (currentStep + 1) / 5,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.5), blurRadius: 4)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Text('Premium only - Free to preview', style: GoogleFonts.inter(
        color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic,
      )),
    );
  }
}

// ── Step 1: Frequency ─────────────────────────────────────────────────────────

class _StepFrequency extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _StepFrequency({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      title: 'How often would you like to train?',
      children: [
        for (int i = 2; i <= 6; i++)
          _SelectionCard(
            label: '$i times per week',
            isSelected: value == i,
            onTap: () => onChanged(i),
          ).animate().fadeIn(delay: (i * 100).ms).slideY(begin: 0.1),
      ],
    );
  }
}

// ── Step 2: Split ─────────────────────────────────────────────────────────────

class _StepSplit extends StatelessWidget {
  final int frequency;
  final String? selected;
  final ValueChanged<String> onChanged;
  const _StepSplit({required this.frequency, required this.selected, required this.onChanged});

  List<(String, String)> get _splits {
    if (frequency <= 3) {
      return [
        ('Full Body', 'Ideal for busy schedules. Hits every muscle group in one session.'),
        ('Push/Pull/Legs', 'A classic high-frequency split for muscle growth.'),
      ];
    } else if (frequency == 4) {
      return [
        ('Upper/Lower Split', 'Two upper and two lower body workouts per week. Balanced volume.'),
        ('Push/Pull/Legs - Full Body', 'Three days of PPL followed by a full body workout.'),
      ];
    } else {
      return [
        ('Push/Pull/Legs', 'Classic 6-day split. The gold standard for bodybuilding.'),
        ('Arnold Split', 'Antagonistic training (Chest/Back, Shoulders/Arms, Legs). High volume.'),
        ('Bro Split', 'Hit each muscle group once per week with maximum intensity.'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      title: 'Program for ${frequency}x per week',
      children: [
        for (var (name, desc) in _splits)
          _SelectionCard(
            label: name,
            subtitle: desc,
            isSelected: selected == name,
            onTap: () => onChanged(name),
          ).animate().fadeIn().slideX(begin: 0.1),
      ],
    );
  }
}

// ── Step 3: Equipment ─────────────────────────────────────────────────────────

class _StepEquipment extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;
  const _StepEquipment({required this.selected, required this.onToggle, required this.onNext});

  static const _options = [
    ('Free Weights', 'Barbells, dumbbells, kettlebells, etc.'),
    ('Machines', 'Cable, smith, and leverage machines'),
    ('Bodyweight', 'Bodyweight exercises with optional assistance'),
    ('Accessories', 'Bands, balls, and other equipment'),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      title: 'Choose 1 or more of the following options',
      children: [
        for (var (name, desc) in _options)
          _EquipmentTile(
            title: name,
            subtitle: desc,
            isSelected: selected.contains(name),
            onToggle: () => onToggle(name),
          ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98)),
      ],
    );
  }
}

// ── Step 4: Training Style ────────────────────────────────────────────────────

class _StepStyle extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;
  const _StepStyle({required this.selected, required this.onChanged});

  static const _styles = [
    ('Balanced', '1-2 min Rest Time\nA mix of strength & hypertrophy benefits', '6-10', '3-4', '3-5'),
    ('Strength', '2-5 min Rest Time\nMax force output & neural adaptations', '3-6', '3-5', '3-5'),
    ('Hypertrophy', '60-90 sec Rest Time\nIncreasing muscle size through volume', '8-12', '3-4', '4-6'),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      title: 'Training Style',
      children: [
        for (var (name, desc, reps, sets, ex) in _styles)
          _StyleCard(
            title: name,
            description: desc,
            reps: reps,
            sets: sets,
            exercises: ex,
            isSelected: selected == name,
            onTap: () => onChanged(name),
          ).animate().fadeIn().slideY(begin: 0.05),
      ],
    );
  }
}

// ── Step 5: Customization ─────────────────────────────────────────────────────

class _StepCustomization extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCreate;
  final bool isGenerating;
  const _StepCustomization({
    required this.controller,
    required this.onChanged,
    required this.onCreate,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      title: 'Customize Your Program',
      children: [
        Row(children: [
          Expanded(child: Text('Add extra details or preferences (optional)',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13))),
          const Icon(Icons.auto_awesome_rounded, color: AppColors.textMuted, size: 18),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 6,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter your extra details (optional)...',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _QuickTag(label: 'Include Cardio', onTap: () {
               controller.text += 'Include cardio. ';
               onChanged(controller.text);
            }),
            _QuickTag(label: 'Short Workouts', onTap: () {
               controller.text += '30-45 min max. ';
               onChanged(controller.text);
            }),
            _QuickTag(label: 'Home Gym', onTap: () {
               controller.text += 'I work out at home. ';
               onChanged(controller.text);
            }),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isGenerating ? null : onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isGenerating
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text('Create', style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

// ── Shared UI Components ──────────────────────────────────────────────────────

class _StepLayout extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _StepLayout({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(
            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  const _SelectionCard({required this.label, this.subtitle, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue.withValues(alpha: 0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.blue : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.inter(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontSize: 15, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            )),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 12,
              )),
            ]
          ],
        ),
      ),
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onToggle;
  const _EquipmentTile({required this.title, required this.subtitle, required this.isSelected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.blue : AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.blue,
              side: const BorderSide(color: AppColors.textMuted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final String title;
  final String description;
  final String reps;
  final String sets;
  final String exercises;
  final bool isSelected;
  final VoidCallback onTap;
  const _StyleCard({
    required this.title, required this.description,
    required this.reps, required this.sets, required this.exercises,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.blue : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.blue, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              _StatItem(label: 'Reps', value: reps),
              const _StatDivider(),
              _StatItem(label: 'Sets', value: sets),
              const _StatDivider(),
              _StatItem(label: 'Exercises', value: exercises),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
    ]));
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1.5, height: 20, color: AppColors.blue.withValues(alpha: 0.3));
  }
}

class _QuickTag extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickTag({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
      backgroundColor: AppColors.cardElevated,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentStep;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool showNext;
  const _BottomNav({required this.currentStep, required this.onBack, required this.onNext, required this.showNext});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool hasBoth = showNext && currentStep > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding + 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Very important
        children: [
          Row(
            children: [
              if (currentStep > 0)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Back', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              if (hasBoth) const SizedBox(width: 12),
              if (showNext)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Next', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Program Result View ───────────────────────────────────────────────────────

class _ProgramResultView extends StatelessWidget {
  final String program;
  final bool isGenerating;
  final bool routinesAdded;
  const _ProgramResultView({required this.program, required this.isGenerating, required this.routinesAdded});

  @override
  Widget build(BuildContext context) {
    // Hide the JSON block from final display
    final cleanProgram = program.split('---JSON---').first.trim();

    return Column(
      children: [
        if (isGenerating)
          const LinearProgressIndicator(backgroundColor: Colors.transparent, color: AppColors.blue),
        if (routinesAdded && !isGenerating)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              border: const Border(bottom: BorderSide(color: AppColors.blue, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sessions added to your Workout tab!',
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: MarkdownBody(
              data: cleanProgram.isEmpty ? 'Generating your program...' : cleanProgram,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, height: 1.6),
                h1: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                h2: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                strong: GoogleFonts.inter(color: AppColors.blueLight),
                listBullet: GoogleFonts.inter(color: AppColors.blueLight),
              ),
            ),
          ),
        ),
        if (!isGenerating && program.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  shadowColor: AppColors.blue.withValues(alpha: 0.5),
                ),
                child: Text('FINISH & VIEW WORKOUTS', style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}
