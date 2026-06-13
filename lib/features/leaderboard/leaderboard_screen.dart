import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/mock_data.dart';
import '../../core/widgets/rank_badge.dart';
import '../../core/providers/leaderboard_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/widgets/premium_card.dart';


/// Provider for selected region on the leaderboard.
final regionProvider = StateProvider<String>((ref) => 'Global');

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: leaderboardAsync.when(
          data: (board) {
            return Column(
              children: [
                _buildHeader(board.length),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBoard(_buildFriendsBoard(board, currentUserId)),
                      _buildBoard(_buildGlobalBoard(board, currentUserId)),
                      _buildBoard(_buildGymBoard(board, currentUserId)),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
          error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Text('Leaderboard', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, color: AppColors.blue, size: 14),
                const SizedBox(width: 4),
                Text('$count users', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(30)),
        child: TabBar(
          controller: _tabController,
          padding: const EdgeInsets.all(4),
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.blueDark, AppColors.blue]),
            borderRadius: BorderRadius.circular(30),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Friends'), Tab(text: 'Global'), Tab(text: 'Gym')],
        ),
      ),
    );
  }

  Widget _buildBoard(Widget content) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: content,
  );

  // ── Friends Board ──────────────────────────────────────────────────────────
  Widget _buildFriendsBoard(List<LeaderboardUser> board, String? myId) {
    final myFriendUids = ref.watch(profileProvider).friends.toSet();
    // Include yourself + your friends
    if (myId != null) myFriendUids.add(myId);

    final friends = board.where((u) => myFriendUids.contains(u.userId)).toList();

    if (friends.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              const Icon(Icons.group_off_rounded, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 16),
              Text('No Friends Yet', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Add friends from the Friends tab to see them here.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 24),
          _buildInviteCard(),
        ],
      );
    }

    return Column(
      children: [
        if (friends.length >= 3) _buildPodium(friends.take(3).toList()),
        const SizedBox(height: 16),
        ...friends.asMap().entries.map((e) => _LeaderboardTile(user: e.value, index: e.key, isCurrentUser: e.value.userId == myId)),
        const SizedBox(height: 16),
        _buildInviteCard(),
      ],
    );
  }

  // ── Global Board ───────────────────────────────────────────────────────────
  Widget _buildGlobalBoard(List<LeaderboardUser> board, String? myId) {
    // Find "you" row and show context (5 above + you + 5 below)
    final meIdx = board.indexWhere((u) => u.userId == myId);
    return Column(
      children: [
        if (board.length >= 3) _buildPodium(board.take(3).toList()),
        const SizedBox(height: 16),
        ...board.asMap().entries.map((e) => _LeaderboardTile(user: e.value, index: e.key, isCurrentUser: e.value.userId == myId)),
        if (meIdx >= 0) ...[
          const SizedBox(height: 8),
          Center(child: Text('Your position: #${board[meIdx].position}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12))),
        ],
      ],
    );
  }

  // ── Gym Board ──────────────────────────────────────────────────────────────
  Widget _buildGymBoard(List<LeaderboardUser> board, String? myId) {
    final profile = ref.watch(profileProvider);
    final myGym = profile.gym ?? 'None';
    final filtered = board.where((u) => u.gym == myGym && myGym != 'None').toList();

    return Column(
      children: [
        PremiumCard(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.business_rounded, color: AppColors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR LOCAL GYM', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text(myGym, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(children: [
              const Icon(Icons.location_off_rounded, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text(myGym == 'None' ? 'Set your gym in profile to see local rankings' : 'No other users in this gym yet',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
            ]),
          )
        else
          ...filtered.asMap().entries.map((e) => _LeaderboardTile(user: e.value, index: e.key, isCurrentUser: e.value.userId == myId)),
      ],
    );
  }


  Widget _buildPodium(List<LeaderboardUser> top3) {
    if (top3.length < 3) return const SizedBox();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumCard(user: top3[1], place: 2, height: 100)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumCard(user: top3[0], place: 1, height: 130)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumCard(user: top3[2], place: 3, height: 80)),
      ],
    );
  }

  Widget _buildInviteCard() => PremiumCard(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: const Icon(Icons.group_add_rounded, color: AppColors.blue, size: 32),
      ),
      const SizedBox(height: 16),
      Text('COMPETE WITH FRIENDS', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Text('Invite your gym squad to track progress and climb the global ranks together.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.share_rounded, size: 16),
          label: Text('INVITE SQUAD', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
          ),
        ),
      ),
    ]),
  );

}

// ── Podium Card ────────────────────────────────────────────────────────────────
class _PodiumCard extends StatelessWidget {
  final LeaderboardUser user;
  final int place;
  final double height;
  const _PodiumCard({required this.user, required this.place, required this.height});

  Color get _placeColor => place == 1 ? AppColors.gold : place == 2 ? AppColors.textSecondary : AppColors.orange;
  String get _medal => place == 1 ? '🥇' : place == 2 ? '🥈' : '🥉';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_medal, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_placeColor.withValues(alpha: 0.5), _placeColor.withValues(alpha: 0.2)]),
            border: Border.all(color: _placeColor.withValues(alpha: 0.6), width: 2),
          ),
          child: Center(child: Text(user.avatarInitials, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(height: 6),
        Text(user.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        RankBadge(rank: user.rank, fontSize: 10, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_placeColor.withValues(alpha: 0.2), _placeColor.withValues(alpha: 0.05)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(
              top: BorderSide(color: _placeColor.withValues(alpha: 0.4), width: 1),
              left: BorderSide(color: _placeColor.withValues(alpha: 0.2), width: 0.5),
              right: BorderSide(color: _placeColor.withValues(alpha: 0.2), width: 0.5),
            ),
          ),
          child: Center(child: Text('$place', style: GoogleFonts.rajdhani(color: _placeColor, fontSize: 28, fontWeight: FontWeight.w900))),
        ),
      ],
    );
  }
}

// ── Leaderboard Row Tile ───────────────────────────────────────────────────────
class _LeaderboardTile extends StatelessWidget {
  final LeaderboardUser user;
  final int index;
  final bool isCurrentUser;
  const _LeaderboardTile({required this.user, required this.index, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final rankColor = AppColors.getRankColor(user.rank);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: isCurrentUser ? AppColors.blue.withValues(alpha: 0.08) : AppColors.card,
        borderRadius: 14,
        showBorder: true,

        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text('#${user.position}', style: GoogleFonts.rajdhani(
                color: user.position <= 3 ? AppColors.gold : AppColors.textSecondary,
                fontSize: 13, fontWeight: FontWeight.w700,
              )),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [rankColor.withValues(alpha: 0.4), rankColor.withValues(alpha: 0.1)]),
                border: Border.all(color: rankColor.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Center(child: Text(user.avatarInitials, style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(user.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text('You', style: GoogleFonts.inter(color: AppColors.blue, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                Text(user.gym, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
              ]),
            ),
            Text('${user.score.toInt()}', style: GoogleFonts.rajdhani(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            RankBadge(rank: user.rank, fontSize: 12),
          ],
        ),
      ).animate()
        .fadeIn(duration: 300.ms, delay: (50 * index).ms)
        .slideX(begin: 0.04, end: 0),
    );
  }
}
