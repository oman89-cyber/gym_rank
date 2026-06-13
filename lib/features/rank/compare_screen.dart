import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/elo_service.dart';
import '../../core/services/recovery_service.dart';
import '../../core/providers/workout_providers.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/widgets/rank_badge.dart';
import '../../core/widgets/custom_painters.dart';
import '../../core/providers/repository_providers.dart';
import '../friends/friends_screen.dart';

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  FriendProfile? _selectedFriend;
  bool _animateBars = false;

  void _selectFriend(FriendProfile friend) {
    setState(() {
      _selectedFriend = friend;
      _animateBars = false;
    });
    // Animate bars after a brief delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _animateBars = true);
    });
  }

  String _rankFromScore(double score) {
    if (score >= 80) return 'S';
    if (score >= 60) return 'A';
    if (score >= 40) return 'B';
    if (score >= 20) return 'C';
    if (score >= 5)  return 'D';
    return 'F';
  }

  String _label(String m) => m[0].toUpperCase() + m.substring(1);

  // Random but seeded "radar scores" for a friend based on their elo
  Map<String, double> _friendRadarFromElo(double elo, List<String> muscles) {
    final base = (elo / 10).clamp(0.0, 100.0);
    // Slight variation per muscle using deterministic offset
    final offsets = [0, 12, -8, 7, -5, 15, -10, 4, -12, 3];
    final result = <String, double>{};
    for (var i = 0; i < muscles.length; i++) {
      result[muscles[i]] = (base + offsets[i % offsets.length]).clamp(0.0, 100.0);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final profile  = ref.watch(profileProvider);
    final friendsAsync = ref.watch(friendProfilesProvider(profile.friends));

    final myRadar  = EloService.instance.radarScores(sessions);
    final myRank   = profile.rank;
    const muscles  = RecoveryService.allMuscles;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _selectedFriend == null
            ? _buildSelectionScreen(friendsAsync, profile.friends)
            : _buildComparisonScreen(myRadar, myRank, profile, muscles),
      ),
    );
  }

  // ── Friend Selection Screen ─────────────────────────────────────────────────
  Widget _buildSelectionScreen(
      AsyncValue<List<FriendProfile>> friendsAsync, List<String> myFriendUids) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Compare',
                    style: GoogleFonts.rajdhani(color: AppColors.textPrimary,
                        fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Text('Choose a friend to compare',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
          ).animate().fadeIn(duration: 400.ms),
        ),

        // Friend list or empty state
        friendsAsync.when(
          data: (allFriends) {
            final myUid = ref.watch(authServiceProvider).currentUser?.uid;
            final friends = allFriends.where((f) => f.uid != myUid).toList();

            if (friends.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
                  child: Column(
                    children: [
                      const Icon(Icons.group_add_rounded, color: AppColors.textMuted, size: 56),
                      const SizedBox(height: 16),
                      Text('No friends added yet',
                          style: GoogleFonts.rajdhani(color: AppColors.textPrimary,
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Add friends to start comparing stats',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const FriendsScreen())),
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: Text('Add Friends', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96)),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _FriendSelectTile(
                    friend: friends[i],
                    onTap: () => _selectFriend(friends[i]),
                  ).animate().fadeIn(duration: 280.ms, delay: (50 * i).ms).slideX(begin: 0.03, end: 0),
                ),
                childCount: friends.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.blue)))),
          error: (e, _) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Failed to load friends: $e',
                  style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  // ── Comparison Detail Screen ─────────────────────────────────────────────────
  Widget _buildComparisonScreen(Map<String, double> myRadar, String myRank,
      dynamic profile, List<String> muscles) {
    final friend = _selectedFriend!;
    final friendRadar = _friendRadarFromElo(friend.eloScore, muscles);

    final myRadarPoints = muscles.take(6).map((m) {
      final v = myRadar[m] ?? 0;
      return RadarPoint(_label(m), v, _rankFromScore(v));
    }).toList();

    final friendRadarPoints = muscles.take(6).map((m) {
      final v = friendRadar[m] ?? 0;
      return RadarPoint(_label(m), v, _rankFromScore(v));
    }).toList();

    return CustomScrollView(
      slivers: [
        // Header with back-to-selection
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() { _selectedFriend = null; _animateBars = false; }),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Compare',
                    style: GoogleFonts.rajdhani(color: AppColors.textPrimary,
                        fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),

        // VS Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              children: [
                Expanded(child: _ProfileCard(
                  name: profile.username, rank: myRank,
                  elo: profile.eloScore, isMe: true,
                )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('VS',
                      style: GoogleFonts.rajdhani(
                          color: AppColors.blue, fontSize: 22, fontWeight: FontWeight.w900)),
                ),
                Expanded(child: _ProfileCard(
                  name: friend.username, rank: friend.rank,
                  elo: friend.eloScore, isMe: false,
                )),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),
        ),

        // Radar charts
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.blue.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Strength Radar',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11,
                          fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Column(children: [
                        Text(profile.username, style: GoogleFonts.inter(
                            color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        SizedBox(height: 160, child: RadarChartWidget(points: myRadarPoints)),
                      ])),
                      Container(width: 1, height: 160, color: AppColors.border),
                      Expanded(child: Column(children: [
                        Text(friend.username, style: GoogleFonts.inter(
                            color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        SizedBox(height: 160, child: RadarChartWidget(points: friendRadarPoints)),
                      ])),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
        ),

        // Muscle breakdown header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text('Muscle Breakdown',
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
        ),

        // Muscle rows
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final muscle  = muscles[i];
              final myScore = myRadar[muscle] ?? 0;
              final frScore = friendRadar[muscle] ?? 0;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _MuscleCompareRow(
                  muscle: _label(muscle),
                  myScore: myScore,
                  friendScore: frScore,
                  iWin: myScore >= frScore,
                  friendName: friend.username,
                  animate: _animateBars,
                ),
              ).animate().fadeIn(duration: 300.ms, delay: (60 * i).ms);
            },
            childCount: muscles.length,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }
}

// ── Friend Select Tile ─────────────────────────────────────────────────────────
class _FriendSelectTile extends StatelessWidget {
  final FriendProfile friend;
  final VoidCallback onTap;
  const _FriendSelectTile({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRankColor(friend.rank);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.1)]),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Center(child: Text(friend.initials,
                  style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(friend.username,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  RankBadge(rank: friend.rank, fontSize: 10),
                  const SizedBox(width: 8),
                  Text('${friend.eloScore.toInt()} ELO',
                      style: GoogleFonts.rajdhani(color: AppColors.textMuted, fontSize: 13)),
                ]),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Profile Card ───────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String name;
  final String rank;
  final double elo;
  final bool isMe;
  const _ProfileCard({required this.name, required this.rank, required this.elo, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final color = isMe ? AppColors.blue : AppColors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.15)]),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Center(child: Text(
              name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase(),
              style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(height: 8),
        Text(name,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        RankBadge(rank: rank, fontSize: 11),
        const SizedBox(height: 4),
        Text('${elo.toInt()} ELO',
            style: GoogleFonts.rajdhani(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
              child: Text('You', style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}

// ── Muscle Compare Row ─────────────────────────────────────────────────────────
class _MuscleCompareRow extends StatelessWidget {
  final String muscle;
  final double myScore;
  final double friendScore;
  final bool iWin;
  final String friendName;
  final bool animate;
  const _MuscleCompareRow({
    required this.muscle, required this.myScore, required this.friendScore,
    required this.iWin, required this.friendName, required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iWin ? AppColors.blue.withValues(alpha: 0.25) : AppColors.orange.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(muscle, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: iWin ? AppColors.blue.withValues(alpha: 0.15) : AppColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(iWin ? 'You Win' : 'Friend Wins',
                style: GoogleFonts.inter(
                    color: iWin ? AppColors.blue : AppColors.orange,
                    fontSize: 9, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        _CompareBar(label: 'You', score: myScore, color: AppColors.blue, animate: animate),
        const SizedBox(height: 6),
        _CompareBar(label: friendName, score: friendScore, color: AppColors.orange, animate: animate),
      ]),
    );
  }
}

class _CompareBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  final bool animate;
  const _CompareBar({required this.label, required this.score, required this.color, required this.animate});

  @override
  Widget build(BuildContext context) {
    final frac = (score / 100.0).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(width: 52,
            child: Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(
          child: Stack(children: [
            Container(height: 7, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6))),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 800), curve: Curves.easeOut,
              widthFactor: animate ? frac : 0,
              child: Container(
                height: 7,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.6), color]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 30,
            child: Text('${score.toInt()}',
                style: GoogleFonts.rajdhani(color: color, fontSize: 13, fontWeight: FontWeight.w800),
                textAlign: TextAlign.right)),
      ],
    );
  }
}
