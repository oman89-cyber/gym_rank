import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/gym_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _selectedGoal = 'Build Muscle';
  String? _selectedGym;
  bool _isSaving = false;

  final List<String> _goals = [
    'Build Muscle',
    'Get Stronger',
    'Lose Fat',
    'General Fitness',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider);
      _nameController.text = profile.username;
      _weightController.text = profile.bodyWeight?.toString() ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _selectedGoal = profile.goal ?? 'Build Muscle';
      _selectedGym = profile.gym;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    if (name.isEmpty || weight == null || height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all mandatory fields'), backgroundColor: AppColors.red),
      );
      return;
    }

    if (_selectedGym == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your home gym'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedProfile = ref.read(profileProvider).copyWith(
        username: name,
        bodyWeight: weight,
        height: height,
        goal: _selectedGoal,
        gym: _selectedGym,
        managedGym: null,
        isOnboarded: true,
      );
      
      await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
      
      // Note: No Navigator.pop() here. AuthWrapper will react to the profile update
      // and automatically switch from CompleteProfileScreen to MainNavigation.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: ${e.toString().contains('permission-denied') ? 'Permission Denied (Admin only)' : e}'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymsAsync = ref.watch(gymsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.fitness_center_rounded, color: AppColors.blue, size: 56),
                const SizedBox(height: 24),
                Text('ATHLETE SETUP', 
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary, 
                    fontSize: 36, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  )),
                const SizedBox(height: 8),
                Text('Complete your profile to join the global rankings.', 
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 15, height: 1.5)),
                const SizedBox(height: 48),
                
                _buildLabel('Display Name'),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _fieldDecoration('Username', Icons.person_outline_rounded),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Weight (kg)'),
                          TextField(
                            controller: _weightController,
                            style: const TextStyle(color: AppColors.textPrimary),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _fieldDecoration('0.0', Icons.scale_outlined),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Height (cm)'),
                          TextField(
                            controller: _heightController,
                            style: const TextStyle(color: AppColors.textPrimary),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _fieldDecoration('0', Icons.height_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildLabel('Primary Fitness Goal'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _goals.map((goal) => GestureDetector(
                    onTap: () => setState(() => _selectedGoal = goal),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedGoal == goal ? AppColors.blue.withValues(alpha: 0.15) : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedGoal == goal ? AppColors.blue : AppColors.border,
                          width: _selectedGoal == goal ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        goal,
                        style: GoogleFonts.inter(
                          color: _selectedGoal == goal ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: _selectedGoal == goal ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 24),

                _buildLabel('Home Gym'),
                gymsAsync.when(
                    data: (gyms) {
                      final gymOptions = ['None', ...gyms];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: (_selectedGym != null && gymOptions.contains(_selectedGym)) ? _selectedGym : null,
                            hint: Text('Select Location', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                            dropdownColor: AppColors.surface,
                            style: const TextStyle(color: AppColors.textPrimary),
                            items: gymOptions.map((g) => DropdownMenuItem(
                              value: g, 
                              child: Text(g, style: GoogleFonts.inter(fontSize: 14))
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedGym = val),
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.blue),
                            decoration: const InputDecoration(border: InputBorder.none),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.blue)),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.red)),
                  ),
                const SizedBox(height: 56),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 12,
                      shadowColor: AppColors.blue.withValues(alpha: 0.3),
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('START TRAINING', 
                          style: GoogleFonts.rajdhani(
                            fontWeight: FontWeight.w900, 
                            fontSize: 20, 
                            letterSpacing: 2,
                            color: Colors.white,
                          )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppColors.textMuted, 
          fontSize: 11, 
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon, color: AppColors.blueLight.withValues(alpha: 0.7), size: 20),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.card.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), 
        borderSide: const BorderSide(color: AppColors.blue, width: 2)
      ),
    );
  }
}
