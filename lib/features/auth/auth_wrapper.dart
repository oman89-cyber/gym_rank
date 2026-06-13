import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/profile_provider.dart';
import '../../navigation/main_navigation.dart';
import '../../core/theme/app_colors.dart';
import 'login_screen.dart';
import 'suspended_screen.dart';
import '../profile/complete_profile_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isGuest = ref.watch(guestModeProvider);

    return authState.when(
      data: (user) {
        if (isGuest) return const MainNavigation();
        if (user == null) return const LoginScreen();

        final profile = ref.watch(profileProvider);
        final profileAsync = ref.watch(latestProfileProvider);

        // Instant check from local state (only if complete)
        if (profile.isBanned) {
          return const SuspendedScreen();
        }
        if (profile.isProfileComplete) {
          return const MainNavigation();
        }

        // If local profile is incomplete, we MUST wait for the remote sync
        // to confirm if data truly doesn't exist in Firestore.
        return profileAsync.when(
          data: (remoteProfile) {
            if (remoteProfile != null) {
              // Ensure local StateNotifier is in sync with the remote data we just fetched
              Future.microtask(() => ref.read(profileProvider.notifier).refresh());

              if (remoteProfile.isBanned) return const SuspendedScreen();
              if (remoteProfile.isProfileComplete) return const MainNavigation();
            }
            // Data is truly missing or incomplete -> Onboarding
            return const CompleteProfileScreen();
          },
          loading: () => const _LoadingView(),
          error: (e, __) => const CompleteProfileScreen(), // Fallback to setup if sync fails
        );
      },
      loading: () => const _LoadingView(),
      error: (_, __) => const LoginScreen(),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      ),
    );
  }
}
