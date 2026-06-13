import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/services/storage_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      
      // Cloud data has been downloaded into Hive and the providers will automatically refresh via Stream.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGuestMode() async {
    await StorageService.instance.setGuestMode(true);
    // Force a UI refresh by invalidating a lightweight provider or just letting AuthWrapper rebuild
    // Since AuthWrapper checks Provider + Storage, we actually need to invalidate the auth state
    // so it rebuilds, or we can just pushReplacement to MainNavigation.
    // Riverpod can watch a guestModeProvider, but sticking to pushing is simplest if needed, 
    // but a StateProvider for guestMode is better. We'll handle it nicely.
    ref.read(guestModeProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // App Logo / Title
              Icon(Icons.fitness_center_rounded, size: 80, color: AppColors.blue),
              const SizedBox(height: 24),
              Text(
                'GYM RANK',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Level up your strength.\nTrack workouts, earn EXP, and climb the ranks globally.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const Spacer(),

              // Sign in Buttons
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.blue))
              else ...[
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 32),
                  label: Text(
                    'Continue with Google',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _handleGuestMode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Continue as Guest (Offline)',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple provider to trigger rebuilds when guest mode toggles
final guestModeProvider = StateProvider<bool>((ref) {
  return StorageService.instance.isGuestMode;
});
