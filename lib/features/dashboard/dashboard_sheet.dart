import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/services/exercise_library.dart';
import '../../navigation/main_navigation.dart';
import '../profile/profile_screen.dart';
import '../../core/models/user_profile.dart';
import '../friends/friends_screen.dart';
import '../admin/admin_dashboard_screen.dart';

// ── Accent Color Provider ──────────────────────────────────────────────────────
final accentColorProvider = StateProvider<Color>((ref) => AppColors.blue);

void showDashboard(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => const DashboardSheet(),
  );
}

/// The sliding "Dashboard" panel opened by the hamburger (≡) icon.
class DashboardSheet extends ConsumerStatefulWidget {
  const DashboardSheet({super.key});
  @override
  ConsumerState<DashboardSheet> createState() => _DashboardSheetState();
}

class _DashboardSheetState extends ConsumerState<DashboardSheet> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final accent  = ref.watch(accentColorProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1830),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.blue.withValues(alpha: 0.15), width: 0.5),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            // ── Header ──────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
              child: Row(
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Dashboard', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w900)),
                    Text('@${profile.username}', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                  ]),
                  const Spacer(),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [accent.withValues(alpha: 0.8), accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 14)],
                    ),
                    child: Center(child: Text(
                      profile.username.isNotEmpty ? profile.username[0].toUpperCase() : 'G',
                      style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    )),
                  ),
                ],
              ),
            ),

            // ── 1. Account Status ──────────────────────────────────────────────
            _PremiumBanner(profile: profile),
            const SizedBox(height: 10),

            // ── 2. Profile ──────────────────────────────────────────────────────
            _DashTile(Icons.person_rounded, 'Profile', subtitle: 'Edit username, rank & stats',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSheet()));
              }),

            // ── 3. Friends ──────────────────────────────────────────────────────
            _DashTile(Icons.people_alt_rounded, 'Friends', subtitle: 'Search & add workout buddies',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
              }),

            // ── 4. Settings ─────────────────────────────────────────────────────
            _DashTile(Icons.settings_rounded, 'Settings', subtitle: 'Units, notifications, account',
              onTap: () => _showSettingsSheet(context, ref)),

            // ── 5. Background Color ─────────────────────────────────────────────
            _DashTile(Icons.palette_rounded, 'Background Color', subtitle: 'Customise accent color',
              trailing: Container(width: 18, height: 18, decoration: BoxDecoration(color: accent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 8)])),
              onTap: () => _showColorPicker(context, ref)),

            _DashTile(Icons.admin_panel_settings_rounded, 'Admin Console', subtitle: 'Global user & gym management',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminDashboardScreen())));
                }),




            // ── 7. Exercises ───────────────────────────────────────────────────
            _DashTile(Icons.fitness_center_rounded, 'Exercises', subtitle: 'Browse 60+ exercises',
              onTap: () => _showExerciseLibrary(context)),

            // ── 8. Feedback & Features ─────────────────────────────────────────
            _DashTile(Icons.feedback_rounded, 'Feedback & Features', subtitle: 'Request a feature or report a bug',
              onTap: () => _showFeedbackSheet(context)),

            // ── 9. Achievements ────────────────────────────────────────────────
            _DashTile(Icons.emoji_events_rounded, 'Achievements', subtitle: 'Daily & weekly quests',
              onTap: () {
                Navigator.pop(context);
                ref.read(navIndexProvider.notifier).state = 1; // Challenges tab
              }),



            const SizedBox(height: 10),
            // App version footer
            Center(child: Text('Gym Rank v1.0.0', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11))),
          ],
        ),
      ),
    );
  }
}

// ── Premium Banner ─────────────────────────────────────────────────────────────
class _PremiumBanner extends StatelessWidget {
  final UserProfile profile;
  const _PremiumBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isPro = profile.subscriptionStatus != 'free';
    final statusLabel = profile.subscriptionStatus.toUpperCase();
    final statusColor = isPro ? AppColors.gold : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isPro ? const Color(0xFF2A1A5E) : const Color(0xFF1A2A5E),
            const Color(0xFF0D1830)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isPro ? AppColors.gold : AppColors.blue).withValues(alpha: 0.2),
        ),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPro 
                ? [AppColors.gold, AppColors.orange] 
                : [AppColors.blue, AppColors.blueDark],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPro ? Icons.workspace_premium_rounded : Icons.person_outline_rounded, 
            color: Colors.white, size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Account Status', 
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(isPro ? 'Premium Member' : 'Standard Account', 
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        ]),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Text(statusLabel, 
            style: GoogleFonts.rajdhani(color: statusColor, fontSize: 14, fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }
}

// ── Dashboard Tile ─────────────────────────────────────────────────────────────
class _DashTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  const _DashTile(this.icon, this.title, {required this.onTap, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111E38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6), width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: AppColors.blueLight, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          if (subtitle != null)
            Text(subtitle!, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
        ])),
        trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Sub-sheets
// ═══════════════════════════════════════════════════════════════════════════════



// ── Settings ───────────────────────────────────────────────────────────────────
void _showSettingsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _SettingsSheet(),
    ),
  );
}

class _SettingsSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  late TextEditingController _nameCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: ref.read(profileProvider).username);
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(color: Color(0xFF0D1830), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
        Text('Settings', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        // Username
        Text('Username', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 8),
        _editing
          ? Row(children: [
              Expanded(child: TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              )),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  if (name.isNotEmpty) ref.read(profileProvider.notifier).setUsername(name);
                  setState(() => _editing = false);
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ])
          : GestureDetector(
              onTap: () => setState(() => _editing = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  Text(profile.username, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 16),
                ]),
              ),
            ),
        const SizedBox(height: 20),
        // Unit toggle
        Text('Weight Unit', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Text('Using ${profile.useKg ? 'Kilograms (kg)' : 'Pounds (lbs)'}', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
            const Spacer(),
            GestureDetector(
              onTap: () => ref.read(profileProvider.notifier).toggleUnit(),
              child: Container(
                height: 32,
                decoration: BoxDecoration(color: AppColors.cardElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _pill('kg', profile.useKg),
                  _pill('lbs', !profile.useKg),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _pill(String label, bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: active ? AppColors.blue : Colors.transparent, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.inter(color: active ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

// ── Accent Color Picker ────────────────────────────────────────────────────────
void _showColorPicker(BuildContext context, WidgetRef ref) {
  const colors = [
    (AppColors.blue,          'Cobalt'),
    (Color(0xFF7C3AED),       'Violet'),
    (Color(0xFF059669),       'Emerald'),
    (Color(0xFFDC2626),       'Crimson'),
    (Color(0xFFEA580C),       'Orange'),
    (Color(0xFFCA8A04),       'Gold'),
    (Color(0xFFDB2777),       'Pink'),
    (Color(0xFF0891B2),       'Cyan'),
  ];
  showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Color(0xFF0D1830), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
        Text('Accent Color', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Changes the app accent highlights', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: colors.map((c) {
            final current = ref.read(accentColorProvider);
            final isSelected = current == c.$1;
            return GestureDetector(
              onTap: () {
                ref.read(accentColorProvider.notifier).state = c.$1;
                Navigator.pop(context);
              },
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: c.$1,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: [BoxShadow(color: c.$1.withValues(alpha: 0.5), blurRadius: 12)],
                  ),
                  child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 24) : null,
                ),
                const SizedBox(height: 6),
                Text(c.$2, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
              ]),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ]),
    ),
  );
}



// ── Exercise Library ───────────────────────────────────────────────────────────
void _showExerciseLibrary(BuildContext context) {
  final muscles = ['all', 'chest', 'back', 'shoulders', 'biceps', 'triceps', 'quads', 'hamstrings', 'glutes', 'calves', 'abs'];
  showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => _ExerciseLibrarySheet(muscles: muscles),
  );
}

class _ExerciseLibrarySheet extends StatefulWidget {
  final List<String> muscles;
  const _ExerciseLibrarySheet({required this.muscles});
  @override
  State<_ExerciseLibrarySheet> createState() => _ExerciseLibrarySheetState();
}

class _ExerciseLibrarySheetState extends State<_ExerciseLibrarySheet> {
  String _query = '';
  String _filter = 'all';

  List<ExerciseItem> get _filtered {
    var list = ExerciseLibrary.all;
    if (_filter != 'all') list = list.where((e) => e.primaryMuscle == _filter).toList();
    if (_query.isNotEmpty) list = list.where((e) => e.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.9, maxChildSize: 0.95, minChildSize: 0.5,
    builder: (ctx, ctrl) => Container(
      decoration: const BoxDecoration(color: Color(0xFF0D1830), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(children: [
            Row(children: [
              Text('Exercise Library', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('${_filtered.length} exercises', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                hintText: 'Search exercises...',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                filled: true, fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView(scrollDirection: Axis.horizontal, children: widget.muscles.map((m) {
                final active = _filter == m;
                return GestureDetector(
                  onTap: () => setState(() => _filter = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.blue : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppColors.blue : AppColors.border),
                    ),
                    child: Text(m == 'all' ? 'All' : _cap(m), style: GoogleFonts.inter(color: active ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList()),
            ),
          ]),
        ),
        Expanded(child: ListView.builder(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final ex = _filtered[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.fitness_center_rounded, color: AppColors.blueLight, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex.name, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(_cap(ex.primaryMuscle), style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                ])),
                if (ex.isBodyweight)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.green.withValues(alpha: 0.3))),
                    child: Text('BW', style: GoogleFonts.inter(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ]),
            );
          },
        )),
      ]),
    ),
  );

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Feedback Sheet ─────────────────────────────────────────────────────────────
void _showFeedbackSheet(BuildContext context) {
  final ctrl = TextEditingController();
  int selectedType = 0; // 0=bug, 1=feature
  showModalBottomSheet(
    context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
    builder: (_) => StatefulBuilder(builder: (ctx, setSt) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF0D1830), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)))),
          Text('Feedback & Features', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _typeBtn('🐛  Bug Report', selectedType == 0, () => setSt(() => selectedType = 0))),
            const SizedBox(width: 10),
            Expanded(child: _typeBtn('💡  Feature', selectedType == 1, () => setSt(() => selectedType = 1))),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            maxLines: 4,
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: selectedType == 0 ? 'Describe the bug...' : 'Describe your idea...',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
              filled: true, fillColor: AppColors.card,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Thank you! Your feedback has been recorded. 🙏', style: GoogleFonts.inter(color: Colors.white)),
                backgroundColor: AppColors.blue, behavior: SnackBarBehavior.floating,
              ));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.blue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
          )),
        ]),
      ),
    )),
  );
}

Widget _typeBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: active ? AppColors.blue.withValues(alpha: 0.15) : AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: active ? AppColors.blue.withValues(alpha: 0.5) : AppColors.border),
    ),
    child: Center(child: Text(label, style: GoogleFonts.inter(color: active ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w400))),
  ),
);


