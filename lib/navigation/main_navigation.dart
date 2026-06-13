import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/challenges/challenges_screen.dart';
import '../features/home/home_screen.dart';
import '../features/workout/workout_screen.dart';
import '../features/rank/rank_screen.dart';
import '../features/trainers/trainers_screen.dart';
import '../core/theme/app_colors.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    WorkoutScreen(),
    TrainersScreen(),
    ChallengesScreen(),
    RankScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(navIndexProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(index: idx, children: _screens),
      bottomNavigationBar: _BottomNav(currentIndex: idx),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const items = [
      ('Home',       Icons.home_rounded,              Icons.home_outlined),
      ('Workout',    Icons.accessibility_new_rounded, Icons.accessibility_new_outlined),
      ('Trainers',   Icons.sports_rounded,            Icons.sports_outlined),
      ('Challenges', Icons.bolt_rounded,              Icons.bolt_outlined),
      ('Rank',       Icons.emoji_events_rounded,      Icons.emoji_events_outlined),
    ];

    // Determine the width for each item to fit exactly without overflow
    // Calculate width dynamically or let Row spaceAround do the spacing natively
    final itemWidth = (MediaQuery.of(context).size.width - 32) / items.length;

    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () => ref.read(navIndexProvider.notifier).state = i,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: itemWidth.clamp(50.0, 70.0), // Give it responsive width bounds
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.$2 : item.$3,
                        color: selected ? AppColors.blue : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$1,
                        style: TextStyle(
                          color: selected ? AppColors.blue : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
        ),
      ),
    );
  }
}
