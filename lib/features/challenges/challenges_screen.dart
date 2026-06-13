import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/workout_providers.dart';
import '../../core/services/challenges_service.dart';
import 'package:gym_rank/core/models/challenge.dart';
import '../../core/constants/exclusive_challenges.dart';
import '../../core/providers/challenge_providers.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/widgets/premium_card.dart';


// View filter provider (0=To do, 1=Progress, 2=Activity, 3=Exclusive)
final _viewProvider = StateProvider<int>((ref) => 3); // Default to Exclusive per user request

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions  = ref.watch(sessionsProvider);
    final profile   = ref.watch(profileProvider); // For rank and titles
    final rankColor = AppColors.getRankColor(profile.rank);
    final allQuests = ChallengesService.instance.compute(sessions);
    final view      = ref.watch(_viewProvider);

    final todo     = allQuests.where((q) => !q.isComplete).toList();
    final done     = allQuests.where((q) => q.isComplete).toList();
    final daily    = allQuests.where((q) => q.type == 'daily').toList();
    final weekly   = allQuests.where((q) => q.type == 'weekly').toList();

    // ── Get Joined Exclusive Challenges ──────────────────────────────────────
    final joinedMap = ref.watch(joinedChallengesProvider);
    final joinedChallenges = exclusiveChallenges.where((c) => joinedMap.containsKey(c.id)).toList();

    // Convert Exclusive to Quests for ToDo/Progress
    final exclusiveQuests = joinedChallenges.map((c) {
      final userC = joinedMap[c.id]!;
      return Quest(
        id: c.id,
        title: c.title,
        subtitle: userC.isCompleted ? 'CHALLENGE COMPLETED!' : (userC.isExpired ? 'EXPIRED' : c.description),
        type: 'exclusive',
        target: c.goalValue,
        current: userC.currentValue,
        unit: c.goalType == ChallengeGoalType.sessions ? 'sessions' : (c.goalType == ChallengeGoalType.volume ? 'kg' : 'sets'),
      );
    }).toList();

    final todoPlus = [...todo, ...exclusiveQuests];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // ── Header (Simple Style) ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GYM RANK', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('Challenges', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w900, height: 1)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rankColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: rankColor, size: 14),
                      const SizedBox(width: 6),
                      Text(profile.rank, style: GoogleFonts.inter(color: rankColor, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // ── View Filter (Premium Segmented Control) ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 50,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  _ViewChip('To do',    Icons.list_alt_rounded,    0, ref, view),
                  _ViewChip('Progress', Icons.show_chart_rounded,  1, ref, view),
                  _ViewChip('Activity',  Icons.history_rounded,     2, ref, view),
                  _ViewChip('Exclusive', Icons.star_rounded,        3, ref, view),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _getContentWidget(view, todoPlus, done, daily, weekly, exclusiveQuests),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _getContentWidget(int view, List<Quest> todo, List<Quest> done, List<Quest> daily, List<Quest> weekly, List<Quest> exclusive) {
    switch (view) {
      case 0:  return _questList(todo); 
      case 1:  return _progressView(daily, weekly, exclusive); 
      case 2:  return _questList(done); 
      default: return _ExclusiveChallengeList(challenges: exclusiveChallenges);
    }
  }

  Widget _questList(List<Quest> quests) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
    itemCount: quests.length,
    itemBuilder: (_, i) => _QuestCard(quest: quests[i])
        .animate()
        .fadeIn(duration: 300.ms, delay: (60 * i).ms)
        .slideY(begin: 0.04, end: 0),
  );

  Widget _progressView(List<Quest> daily, List<Quest> weekly, List<Quest> exclusive) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (exclusive.isNotEmpty) ...[
        Text('EXCLUSIVE PROGRAMMES', style: GoogleFonts.rajdhani(color: AppColors.blue, fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...exclusive.map((q) => _ProgressRow(quest: q, color: AppColors.blue)),
        const SizedBox(height: 24),
      ],
      Text('DAILY CHALLENGES', style: GoogleFonts.rajdhani(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...daily.map((q) => _ProgressRow(quest: q, color: AppColors.blue)),
      const SizedBox(height: 20),
      Text('WEEKLY CHALLENGES', style: GoogleFonts.rajdhani(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...weekly.map((q) => _ProgressRow(quest: q, color: AppColors.gold)),

    ]),
  );
}

// ── View Filter Chip ───────────────────────────────────────────────────────────
class _ViewChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final int index;
  final WidgetRef ref;
  final int current;
  const _ViewChip(this.label, this.icon, this.index, this.ref, this.current);

  @override
  Widget build(BuildContext context) {
    final selected = current == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(_viewProvider.notifier).state = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected ? [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 16, 
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                label, 
                style: GoogleFonts.inter(
                  color: selected ? Colors.white : AppColors.textSecondary, 
                  fontSize: 10, 
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Progress Row ───────────────────────────────────────────────────────────────
class _ProgressRow extends StatelessWidget {
  final Quest quest;
  final Color color;
  const _ProgressRow({required this.quest, required this.color});

  @override
  Widget build(BuildContext context) => PremiumCard(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(quest.title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${quest.current}/${quest.target}', style: GoogleFonts.rajdhani(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),

      const SizedBox(height: 8),
      Stack(children: [
        Container(height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
        FractionallySizedBox(
          widthFactor: quest.progress.clamp(0.0, 1.0),
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
            ),
          ),
        ),
      ]),
    ]),
  );
}

// ── Quest Card ─────────────────────────────────────────────────────────────────
class _QuestCard extends StatelessWidget {
  final Quest quest;
  const _QuestCard({required this.quest});

  @override
  Widget build(BuildContext context) {
    final isExclusive = quest.type == 'exclusive';
    final color = quest.isComplete ? AppColors.green : 
                  (isExclusive ? AppColors.blue : (quest.type == 'daily' ? AppColors.blue : AppColors.gold));
    final progPct = quest.progress.clamp(0.0, 1.0);

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      color: quest.isComplete ? AppColors.green.withValues(alpha: 0.05) : 
             (isExclusive ? AppColors.blue.withValues(alpha: 0.05) : AppColors.card),
      showBorder: true,
      borderRadius: 16,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
            ),

            child: Icon(
              quest.isComplete ? Icons.check_circle_rounded : 
              (quest.type == 'exclusive' ? Icons.stars_rounded : Icons.bolt_rounded), 
              color: color, size: 22
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(quest.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            Text(quest.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(
              color: quest.subtitle.contains('COMPLETED') ? AppColors.green : (quest.subtitle == 'EXPIRED' ? AppColors.red : AppColors.textSecondary), 
              fontSize: 12,
              fontWeight: (quest.subtitle.contains('COMPLETED') || quest.subtitle == 'EXPIRED') ? FontWeight.w800 : FontWeight.normal,
            )),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text('${quest.current}/${quest.target} ${quest.unit}', style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Stack(children: [
          Container(height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(
            widthFactor: progPct,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
              ),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            quest.type == 'exclusive' ? 'Special High-Priority Quest' :
            (quest.type == 'daily' ? 'Resets at midnight' : 'Resets Monday'), 
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)
          ),
          Text('${(progPct * 100).toInt()}%', style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

// ── Exclusive Challenge Components ───────────────────────────────────────────

class _ExclusiveChallengeList extends StatefulWidget {
  final List<Challenge> challenges;
  const _ExclusiveChallengeList({required this.challenges});

  @override
  State<_ExclusiveChallengeList> createState() => _ExclusiveChallengeListState();
}

class _ExclusiveChallengeListState extends State<_ExclusiveChallengeList> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.challenges.where((c) => 
      c.title.toLowerCase().contains(_search.toLowerCase()) || 
      c.description.toLowerCase().contains(_search.toLowerCase())
    ).toList();

    return Column(
      children: [
        // Search bar for Exclusive
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PremiumCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            borderRadius: 12,
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search exclusive challenges...',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                icon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => _ExclusiveChallengeCard(challenge: filtered[i])
              .animate()
              .fadeIn(duration: 400.ms, delay: (80 * i).ms)
              .slideY(begin: 0.05, end: 0),
          ),
        ),
      ],
    );
  }
}

class _ExclusiveChallengeCard extends ConsumerWidget {
  final Challenge challenge;
  const _ExclusiveChallengeCard({required this.challenge});

  Color get _difficultyColor {
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:    return AppColors.green;
      case ChallengeDifficulty.medium:  return AppColors.gold;
      case ChallengeDifficulty.hard:    return AppColors.red;
      case ChallengeDifficulty.extreme: return const Color(0xFFFF5500);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showChallengeDetails(context, ref, challenge),
      child: PremiumCard(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Area ────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.blueDark, AppColors.blue.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(challenge.icon ?? Icons.bolt_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      challenge.description,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Tags Area ──────────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(challenge.difficulty.name.toUpperCase(), _difficultyColor),
              ...challenge.tags.map((t) => _pill(t, AppColors.textSecondary.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 20),

          // ── Stats Grid ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _statItem(challenge.duration, 'Duration')),
                Expanded(child: _statItem(challenge.timePerDay, 'Per day')),
                Expanded(child: _activeStatItem(challenge.activeCount.toString(), 'Active')),
                Expanded(child: _statItem(challenge.joinedCount.toString(), 'Joined')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Footer ─────────────────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.blue.withValues(alpha: 0.2),
                child: Text(
                  challenge.creatorName[0],
                  style: GoogleFonts.inter(color: AppColors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                challenge.creatorName,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
              Text(' 5.0', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (challenge.isTrending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6366f1).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.north_east_rounded, color: Color(0xFF818cf8), size: 12),
                      const SizedBox(width: 4),
                      Text('Trending', style: GoogleFonts.inter(color: const Color(0xFF818cf8), fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Start/Join Button Area ─────────────────────────────────────────
          _ActionButton(challenge: challenge),
        ],
      ),
    ),
  );
}

  void _showChallengeDetails(BuildContext context, WidgetRef ref, Challenge challenge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(challenge.icon ?? Icons.bolt_rounded, color: AppColors.blue, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(challenge.title, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                Text('By ${challenge.creatorName}', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              ])),

            ]),
            const SizedBox(height: 24),
            Text('CHALLENGE GOAL', style: GoogleFonts.rajdhani(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.blue.withValues(alpha: 0.3))),
              child: Row(children: [
                const Icon(Icons.track_changes_rounded, color: AppColors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(
                  'Log ${challenge.goalValue} ${challenge.goalType.name} ${challenge.targetMuscle != null ? "of ${challenge.targetMuscle}" : ""} over ${challenge.duration}.',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                )),
              ]),
            ),
            const SizedBox(height: 24),
            Text('HOW TO COMPLETE', style: GoogleFonts.rajdhani(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),

            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: challenge.steps.length,
                itemBuilder: (ctx, idx) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${idx + 1}.', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(challenge.steps[idx], style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, height: 1.5))),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 12),
                Text('Reward: +${challenge.eloReward} ELO Points', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 24),
            _ActionButton(challenge: challenge),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _activeStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: AppColors.green, fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final Challenge challenge;
  const _ActionButton({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedMap = ref.watch(joinedChallengesProvider);
    final isJoined = joinedMap.containsKey(challenge.id);
    final userC = joinedMap[challenge.id];
    final isCompleted = userC?.isCompleted ?? false;
    final isExpired = userC?.isExpired ?? false;

    return GestureDetector(
      onTap: () {
        if (!isJoined) {
          ref.read(joinedChallengesProvider.notifier).join(challenge.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined ${challenge.title}!'),
              backgroundColor: AppColors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (Navigator.canPop(context)) Navigator.pop(context);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: isJoined ? Colors.transparent : AppColors.blue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? AppColors.green : (isExpired ? AppColors.red : (isJoined ? AppColors.blue.withValues(alpha: 0.5) : Colors.transparent)),
            width: 1.5,
          ),
          boxShadow: (isJoined) ? [] : [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted ? Icons.check_circle_rounded : (isExpired ? Icons.timer_off_rounded : (isJoined ? Icons.sync_rounded : Icons.play_arrow_rounded)),
                color: isCompleted ? AppColors.green : (isExpired ? AppColors.red : (isJoined ? AppColors.blue : Colors.white)),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCompleted ? 'COMPLETED' : (isExpired ? 'EXPIRED' : (isJoined ? 'IN PROGRESS' : 'START CHALLENGE')),
                style: GoogleFonts.rajdhani(
                  color: isCompleted ? AppColors.green : (isExpired ? AppColors.red : (isJoined ? AppColors.blue : Colors.white)),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
