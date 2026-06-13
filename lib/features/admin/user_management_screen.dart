import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/models/user_profile.dart';
import 'user_details_admin_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Screen to manage and browse all users in the system.
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(filteredUsersProvider);
    final searchCtrl = TextEditingController(text: ref.read(adminSearchProvider));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('User Directory', 
          style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchField(ref, searchCtrl),
          Expanded(
            child: usersAsync.when(
              data: (users) => _buildUserList(context, users),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
              error: (e, _) => _ErrorPlaceholder(error: e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(WidgetRef ref, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: TextField(
        controller: ctrl,
        onChanged: (v) => ref.read(adminSearchProvider.notifier).state = v,
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search Name, Email, or ID...',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          filled: true,
          fillColor: AppColors.card.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), 
            borderSide: const BorderSide(color: AppColors.blue, width: 1)
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<UserProfile> users) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_search_rounded, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text('No users found matching your search.', 
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsAdminScreen(user: user))),
          borderRadius: BorderRadius.circular(16),
          child: _UserTile(user: user).animate().fadeIn(delay: (index * 30).ms).slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuart),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserProfile user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final rankColor = AppColors.getRankColor(user.rank);
    final joinDate = user.joinDate != null ? '${user.joinDate!.day}/${user.joinDate!.month}' : 'N/A';
    
    Color subColor = AppColors.textMuted;
    if (user.subscriptionStatus == 'pro') subColor = AppColors.gold;
    if (user.subscriptionStatus == 'trial') subColor = AppColors.blueLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: user.isBanned ? AppColors.red.withValues(alpha: 0.3) : AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.1),
              border: Border.all(color: rankColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?', 
                        style: GoogleFonts.rajdhani(color: rankColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.username, 
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: AppColors.blueLight, size: 12),
                    ],
                    if (user.isBanned) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.block_flipped, color: AppColors.red, size: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: subColor)),
                    const SizedBox(width: 6),
                    Text(user.subscriptionStatus.toUpperCase(), 
                         style: GoogleFonts.inter(color: subColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    Text(' • $joinDate', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          // Rank
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(user.rank, 
                style: GoogleFonts.rajdhani(color: rankColor, fontSize: 20, fontWeight: FontWeight.w900)),
              Text('ELO ${user.eloScore.toInt()}', 
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final String error;
  const _ErrorPlaceholder({required this.error});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Error loading users: $error', 
        textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.red, fontSize: 12)),
    ),
  );
}
