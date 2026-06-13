import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/workout_providers.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/gym_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/gym_owner_dashboard.dart';
import '../admin/gym_trainer_dashboard.dart';
import 'subscription_screen.dart';
import 'widgets/rank_progress_bar.dart';
import '../../core/widgets/premium_card.dart';


/// Full-screen profile & settings sheet.
class ProfileSheet extends ConsumerStatefulWidget {
  const ProfileSheet({super.key});
  @override
  ConsumerState<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<ProfileSheet> {
  late TextEditingController _nameCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(profileProvider).username);
    
    // Sync from remote on open to catch manual role promotions (isAdmin)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).syncFromRemote();
    });
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final profile  = ref.watch(profileProvider);
    final sessions = ref.watch(sessionsProvider);

    final totalVolume = sessions.fold<double>(0, (double sum, s) => sum + s.totalVolume);
    final totalSets   = sessions.fold<int>(0, (int sum, s) => sum + s.totalSets);
    final bestSession = sessions.isEmpty ? null :
        sessions.reduce((a, b) => a.totalVolume >= b.totalVolume ? a : b);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('PROFILE & SETTINGS', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)),

        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [AppColors.blueDark, AppColors.blue]),
                      boxShadow: [const BoxShadow(color: Color.fromRGBO(33, 150, 243, 0.4), blurRadius: 20, spreadRadius: 3)],
                    ),
                    child: Center(
                      child: Text(
                        profile.username.isNotEmpty ? profile.username[0].toUpperCase() : 'G',
                        style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _editing
                      ? SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.card,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            onSubmitted: _saveName,
                          ),
                        )
                      : GestureDetector(
                          onTap: () => setState(() => _editing = true),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(profile.username, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 16),
                            ],
                          ),
                        ),
                  if (_editing) ...[
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => _saveName(_nameCtrl.text),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.blue, minimumSize: const Size(120, 36)),
                      child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _RankPill(rank: profile.rank),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Lifetime Stats ──────────────────────────────────────────────
            _SectionLabel('Lifetime Stats'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _StatCard('SESSIONS',   '${profile.totalSessions}',                  Icons.fitness_center_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard('TOTAL SETS', '$totalSets',                                 Icons.repeat_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _StatCard('VOLUME',     '${_fmt(totalVolume)}', Icons.bar_chart_rounded, unit: profile.useKg ? 'kg' : 'lbs')),
              ],
            ),

            const SizedBox(height: 10),
            if (bestSession != null)
              _BestSessionCard(session: bestSession, useKg: profile.useKg),
            const SizedBox(height: 28),

            // ── Settings ────────────────────────────────────────────────────
            _SectionLabel('Settings'),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.star_rounded,
              label: 'Upgrade to PRO',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('PRO', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.scale_rounded,
              label: 'Weight Unit',
              trailing: _UnitToggle(
                useKg: profile.useKg,
                onToggle: () => ref.read(profileProvider.notifier).toggleUnit(),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.monitor_weight_rounded,
              label: 'Body Weight',
              trailing: Text(profile.bodyWeight != null ? '${profile.bodyWeight} ${profile.useKg ? 'kg' : 'lbs'}' : 'Not set', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              onTap: () => _showEditDialog(
                title: 'Body Weight',
                initialValue: profile.bodyWeight?.toString() ?? '',
                onSave: (v) => ref.read(profileProvider.notifier).setWeight(v),
                suffix: profile.useKg ? 'kg' : 'lbs',
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.height_rounded,
              label: 'Height',
              trailing: Text(profile.height != null ? '${profile.height} cm' : 'Not set', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              onTap: () => _showEditDialog(
                title: 'Height (cm)',
                initialValue: profile.height?.toString() ?? '',
                onSave: (v) => ref.read(profileProvider.notifier).setHeight(v),
                suffix: 'cm',
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.person_rounded,
              label: 'Edit Username',
              onTap: () => setState(() { _editing = true; }),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.business_rounded,
              label: 'Gym Name',
              trailing: Text(profile.gym ?? 'Not set', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              onTap: () => _showGymDialog(
                initialValue: profile.gym ?? '',
              ),
            ),
            const SizedBox(height: 8),
            const _GoogleAuthTile(),

            // ── 6. Gym Management ──────────────────────────────────────────────
            if (profile.isAdmin || profile.isGymOwner)
              _SettingsTile(
                icon: Icons.storefront_rounded,
                label: 'Gym Owner Console',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GymOwnerDashboardScreen())),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.blue),
              ),

            if (profile.isAdmin || profile.isGymTrainer) ...[
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.sports_rounded,
                label: 'Gym Trainer Console',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GymTrainerDashboardScreen())),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.blue),
              ),
            ],

            if (profile.isAdmin) ...[
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Admin Console',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminDashboardScreen()))),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.blueLight),
              ),
            ],
            const SizedBox(height: 28),

            // ── ELO Info ────────────────────────────────────────────────────
            _SectionLabel('PROGRESSION'),
            const SizedBox(height: 10),
            PremiumCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: RankProgressBar(eloScore: profile.eloScore),
            ),

          ].animate(interval: 50.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuart),
        ),
      ),
    );
  }

  void _saveName(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      ref.read(profileProvider.notifier).setUsername(trimmed);
    }
    setState(() { _editing = false; });
  }

  Future<void> _showEditDialog({
    required String title,
    required String initialValue,
    required void Function(double) onSave,
    required String suffix,
  }) async {
    final ctrl = TextEditingController(text: initialValue);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            suffixText: suffix,
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null) onSave(val);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGymDialog({
    required String initialValue,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final gymsAsync = ref.watch(gymsProvider);
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Set Your Gym', style: GoogleFonts.inter(color: AppColors.textPrimary)),
            content: gymsAsync.when(
              data: (gyms) {
                final gymOptions = ['None', ...gyms];
                return DropdownButtonFormField<String>(
                  value: gymOptions.contains(initialValue) ? initialValue : null,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: gymOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(profileProvider.notifier).setGym(val);
                      Navigator.pop(ctx);
                    }
                  },
                );
              },
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ],
          );
        },
      ),
    );
  }

  String _fmt(double v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

// ── Small Widgets ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
    Text(text, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700));
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? unit;
  const _StatCard(this.label, this.value, this.icon, {this.unit});
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.blue, size: 18),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(unit!, style: GoogleFonts.rajdhani(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ],
    ),
  );
}


class _BestSessionCard extends StatelessWidget {
  final session;
  final bool useKg;
  const _BestSessionCard({required this.session, required this.useKg});
  @override
  Widget build(BuildContext context) {
    final vol = useKg ? session.totalVolume : session.totalVolume * 2.20462;
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.blue.withValues(alpha: 0.05),
      showBorder: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PERSONAL BEST SESSION', style: GoogleFonts.rajdhani(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 2),
              Text('${session.name}  •  ${vol.toStringAsFixed(0)} ${useKg ? 'kg' : 'lbs'}',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }
}


class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.label, this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: PremiumCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 14),
          Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    ),
  );
}


class _GoogleAuthTile extends ConsumerStatefulWidget {
  const _GoogleAuthTile();
  @override
  ConsumerState<_GoogleAuthTile> createState() => _GoogleAuthTileState();
}

class _GoogleAuthTileState extends ConsumerState<_GoogleAuthTile> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        final isSignedIn = user != null;
        return GestureDetector(
          onTap: () async {
            if (_isLoading) return;
            setState(() => _isLoading = true);
            try {
              if (isSignedIn) {
                await ref.read(authServiceProvider).signOut();
                ref.read(guestModeProvider.notifier).state = false;
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                await ref.read(authServiceProvider).signInWithGoogle();
                if (!mounted) return;
                ref.read(guestModeProvider.notifier).state = false;
                ref.invalidate(sessionsProvider);
                ref.invalidate(routinesProvider);
                ref.invalidate(profileProvider);
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, width: 0.5)),
            child: Row(
              children: [
                Icon(isSignedIn ? Icons.logout_rounded : Icons.login_rounded, 
                     color: isSignedIn ? Colors.redAccent : AppColors.blueLight, size: 20),
                const SizedBox(width: 14),
                Text(isSignedIn ? 'Sign Out' : 'Sign in with Google', 
                     style: GoogleFonts.inter(color: isSignedIn ? Colors.redAccent : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blueLight))
                else if (!isSignedIn)
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  final bool useKg;
  final VoidCallback onToggle;
  const _UnitToggle({required this.useKg, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: 32,
        decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pill('kg',  useKg),
            _pill('lbs', !useKg),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: active ? AppColors.blue : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: GoogleFonts.inter(
      color: active ? Colors.white : AppColors.textSecondary,
      fontSize: 12, fontWeight: FontWeight.w700,
    )),
  );
}

class _RankPill extends StatelessWidget {
  final String rank;
  const _RankPill({required this.rank});
  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRankColor(rank);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('$rank-Rank', style: GoogleFonts.rajdhani(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
    );
  }
}
