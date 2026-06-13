import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/friends_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/widgets/rank_badge.dart';
import '../../core/providers/repository_providers.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile     = ref.watch(profileProvider);
    final searchState = ref.watch(userSearchProvider);
    final friendsAsync = ref.watch(friendProfilesProvider(profile.friends));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Friends',
                      style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.blue.withValues(alpha: 0.4)),
                    ),
                    child: Text('${profile.friends.length}',
                        style: GoogleFonts.rajdhani(
                            color: AppColors.blue, fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── Search Bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                  onChanged: (val) =>
                      ref.read(userSearchProvider.notifier).search(val),
                  decoration: InputDecoration(
                    hintText: 'Search by username...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              ref.read(userSearchProvider.notifier).clear();
                            },
                            child: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 350.ms, delay: 50.ms),

            // ── Search Results OR Friends List ───────────────────────────────
            Expanded(
              child: searchState.query.isNotEmpty
                  ? _buildSearchResults(searchState, profile.friends)
                  : _buildFriendList(friendsAsync, profile.friends),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Results ──────────────────────────────────────────────────────────
  Widget _buildSearchResults(UserSearchState state, List<String> myFriends) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue));
    }

    final myUid = ref.watch(authServiceProvider).currentUser?.uid;
    final results = state.results.where((u) => u.uid != myUid).toList();

    if (results.isEmpty) {
      return _emptyState(
        icon: Icons.person_search_rounded,
        title: 'No users found',
        subtitle: 'Try a different username',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final user = results[i];
        final isFriend = myFriends.contains(user.uid);
        return _UserTile(
          user: user,
          isFriend: isFriend,
          onAdd: isFriend
              ? null
              : () async {
                  await ref.read(profileProvider.notifier).addFriend(user.uid);
                  // Invalidate the provider so friends list refreshes
                  final updatedFriends = ref.read(profileProvider).friends;
                  ref.invalidate(friendProfilesProvider(updatedFriends));
                  // Clear search so user sees their new friend in the list
                  _searchCtrl.clear();
                  ref.read(userSearchProvider.notifier).clear();
                },
          onRemove: isFriend
              ? () async {
                  final oldFriends = ref.read(profileProvider).friends;
                  await ref.read(profileProvider.notifier).removeFriend(user.uid);
                  ref.invalidate(friendProfilesProvider(oldFriends));
                }
              : null,
        ).animate().fadeIn(duration: 250.ms, delay: (40 * i).ms);
      },
    );
  }

  // ── Friends List ────────────────────────────────────────────────────────────
  Widget _buildFriendList(
      AsyncValue<List<FriendProfile>> friendsAsync, List<String> myFriends) {
    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return _emptyState(
            icon: Icons.group_add_rounded,
            title: 'No friends yet',
            subtitle: 'Search for users above to add friends',
          );
        }
        return RefreshIndicator(
          color: AppColors.blue,
          backgroundColor: AppColors.card,
          onRefresh: () async {
            ref.invalidate(friendProfilesProvider(myFriends));
            try {
              await ref.read(friendProfilesProvider(myFriends).future);
            } catch (_) {}
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: friends.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, i) {
              final f = friends[i];
              return _UserTile(
                user: f,
                isFriend: true,
                onRemove: () async {
                  final oldFriends = ref.read(profileProvider).friends;
                  await ref.read(profileProvider.notifier).removeFriend(f.uid);
                  ref.invalidate(friendProfilesProvider(oldFriends));
                },
              ).animate().fadeIn(duration: 250.ms, delay: (50 * i).ms);
            },
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.blue)),
      error: (e, _) => _emptyState(
        icon: Icons.error_outline_rounded,
        title: 'Failed to load friends',
        subtitle: 'Check your connection and try again',
      ),
    );
  }

  Widget _emptyState(
      {required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 52),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.rajdhani(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

// ── User Tile ──────────────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final FriendProfile user;
  final bool isFriend;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;

  const _UserTile({
    required this.user,
    required this.isFriend,
    this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRankColor(user.rank);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFriend
                ? AppColors.blue.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  color.withValues(alpha: 0.45),
                  color.withValues(alpha: 0.1),
                ]),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Center(
                child: Text(user.initials,
                    style: GoogleFonts.rajdhani(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(children: [
                    RankBadge(rank: user.rank, fontSize: 10),
                    const SizedBox(width: 6),
                    Text('${user.eloScore.toInt()} ELO',
                        style: GoogleFonts.rajdhani(
                            color: AppColors.textMuted, fontSize: 12)),
                    if (user.gym != null) ...[
                      const SizedBox(width: 6),
                      Text('• ${user.gym}',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action
            if (isFriend && onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text('Remove',
                      style: GoogleFonts.inter(
                          color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              )
            else if (!isFriend && onAdd != null)
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.blue.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, color: AppColors.blue, size: 14),
                      const SizedBox(width: 4),
                      Text('Add',
                          style: GoogleFonts.inter(
                              color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
