import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/admin_providers.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/repository_providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Comprehensive admin view for a specific user.
class UserDetailsAdminScreen extends ConsumerStatefulWidget {
  final UserProfile user;
  const UserDetailsAdminScreen({super.key, required this.user});

  @override
  ConsumerState<UserDetailsAdminScreen> createState() => _UserDetailsAdminScreenState();
}

class _UserDetailsAdminScreenState extends ConsumerState<UserDetailsAdminScreen> {
  late bool _isAdmin;
  late bool _isBanned;
  String? _managedGym;
  late bool _isGymOwner;
  late bool _isGymTrainer;
  List<String> _availableGyms = [];
  bool _saving = false;
  bool _loadingGyms = true;

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.user.isAdmin;
    _isBanned = widget.user.isBanned;
    _managedGym = widget.user.managedGym;
    _isGymOwner = widget.user.isGymOwner;
    _isGymTrainer = widget.user.isGymTrainer;
    _fetchGyms();
  }

  Future<void> _fetchGyms() async {
    try {
      final remote = ref.read(remoteServiceProvider);
      final gyms = await remote.fetchGyms();
      if (mounted) {
        setState(() {
          _availableGyms = gyms;
          _loadingGyms = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingGyms = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final remote = ref.read(remoteServiceProvider);
      await remote.updateUserStatus(
        widget.user.uid!,
        isAdmin: _isAdmin,
        isBanned: _isBanned,
        managedGym: _managedGym ?? '', // Empty string will be converted to null in FirebaseRemoteService
        isGymOwner: _isGymOwner,
        isGymTrainer: _isGymTrainer,
      );
      
      if (mounted) {
        // Force immediate profile sync if editing the CURRENT user
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && widget.user.uid == currentUser.uid) {
          await ref.read(profileProvider.notifier).syncFromRemote();
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully'), backgroundColor: AppColors.green),
        );
        ref.invalidate(allUsersProvider); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final joinDateStr = widget.user.joinDate != null 
        ? '${widget.user.joinDate!.day}/${widget.user.joinDate!.month}/${widget.user.joinDate!.year}'
        : 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Manage User', style: GoogleFonts.rajdhani(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_saving)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue)))
          else
            TextButton(
              onPressed: _saveChanges,
              child: Text('SAVE', style: GoogleFonts.inter(color: AppColors.blueLight, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSectionTitle('ACCOUNT OVERVIEW'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _InfoRow(label: 'User ID', value: widget.user.uid ?? 'N/A', isCopyable: true),
              _InfoRow(label: 'Email', value: widget.user.email ?? 'N/A', isCopyable: true),
              _InfoRow(label: 'Joined', value: joinDateStr),
            ]),
            const SizedBox(height: 32),
            _buildSectionTitle('ADMIN CONTROLS'),
            const SizedBox(height: 16),
            _buildControlCard(),
            const SizedBox(height: 32),
            _buildSectionTitle('GYM OWNERSHIP'),
            const SizedBox(height: 16),
            _buildGymOwnerCard(),
          ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.05),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final rankColor = AppColors.getRankColor(widget.user.rank);
    return Row(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [rankColor, rankColor.withValues(alpha: 0.6)]),
            boxShadow: [BoxShadow(color: rankColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2)],
          ),
          child: Center(
            child: Text(widget.user.username[0].toUpperCase(), 
                      style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.username, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
              Text('${widget.user.rankLabel} • ${widget.user.eloScore.toInt()} ELO', 
                   style: GoogleFonts.inter(color: rankColor, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2));
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildControlCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Administrator Privileges', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Allows access to this admin console', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            value: _isAdmin,
            activeThumbColor: AppColors.blue,
            onChanged: (v) => setState(() => _isAdmin = v),
          ),
          const Divider(color: AppColors.border),
          SwitchListTile(
            title: Text('Account Suspended', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Prevents user from logging in', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            value: _isBanned,
            activeThumbColor: AppColors.red,
            onChanged: (v) => setState(() => _isBanned = v),
          ),
        ],
      ),
    );
  }

  Widget _buildGymOwnerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gym Management', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Choose the gym this user will manage.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          if (_loadingGyms)
            const Center(child: CircularProgressIndicator(color: AppColors.blue))
          else if (_availableGyms.isEmpty)
             const Text('No gyms available. Add gyms in Gym Management first.', style: TextStyle(color: AppColors.red, fontSize: 12))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _managedGym,
                  hint: Text('None (Regular User)', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                  isExpanded: true,
                  dropdownColor: AppColors.card,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.blue),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('None (Regular User)', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
                    ),
                    ..._availableGyms.map((g) => DropdownMenuItem(
                      value: g,
                      child: Text(g, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
                    )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _managedGym = v;
                      if (v == null) {
                        _isGymOwner = false;
                        _isGymTrainer = false;
                      }
                    });
                  },
                ),
              ),
            ),
          
          if (_managedGym != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            SwitchListTile(
              title: Text('Gym Owner', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('Full administrative control over this location', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              value: _isGymOwner,
              activeThumbColor: AppColors.blue,
              onChanged: (v) => setState(() => _isGymOwner = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text('Gym Trainer', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('Read-access to registered members\' logs', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              value: _isGymTrainer,
              activeThumbColor: AppColors.gold,
              onChanged: (v) => setState(() => _isGymTrainer = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCopyable;
  const _InfoRow({required this.label, required this.value, this.isCopyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 20),
          Expanded(
            child: Text(value, 
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
