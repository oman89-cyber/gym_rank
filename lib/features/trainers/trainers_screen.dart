import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;

import '../../core/theme/app_colors.dart';

class MockTrainer {
  final String name;
  final String specialization;
  final String experience;
  final String cost;
  final double rating;
  final String bio;
  final List<String> tags;

  const MockTrainer({
    required this.name,
    required this.specialization,
    required this.experience,
    required this.cost,
    required this.rating,
    required this.bio,
    required this.tags,
  });
}

const mockTrainers = [
  MockTrainer(
    name: 'Arjun Sharma',
    specialization: 'Strength & Conditioning',
    experience: '8 Yrs Exp',
    cost: '₹1500',
    rating: 4.9,
    bio: 'Former national powerlifter helping you build raw strength and muscle mass safely and effectively.',
    tags: ['Powerlifting', 'Hypertrophy', 'Form Correction'],
  ),
  MockTrainer(
    name: 'Priya Desai',
    specialization: 'Yoga & Mobility',
    experience: '5 Yrs Exp',
    cost: '₹1200',
    rating: 4.8,
    bio: 'Certified Ashtanga yoga teacher focusing on functional mobility, breathwork, and deep flexibility recovery.',
    tags: ['Ashtanga', 'Flexibility', 'Recovery'],
  ),
  MockTrainer(
    name: 'Vikram Singh',
    specialization: 'HIIT & Fat Loss',
    experience: '6 Yrs Exp',
    cost: '₹1000',
    rating: 4.7,
    bio: 'High-energy coach specialized in intense caloric burn workouts and athletic conditioning that gets you shredded.',
    tags: ['HIIT', 'Cardio', 'Endurance'],
  ),
];

class TrainersScreen extends ConsumerWidget {
  const TrainersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _TrainerCard(trainer: mockTrainers[index])
                          .animate()
                          .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                          .slideY(begin: 0.1, curve: Curves.easeOutCubic),
                    );
                  },
                  childCount: mockTrainers.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for bottom nav
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.8),
            border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3), width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EXPERT GUIDANCE', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Coaches', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final MockTrainer trainer;
  const _TrainerCard({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background glowing orb
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue.withValues(alpha: 0.05),
                  boxShadow: [
                    BoxShadow(color: AppColors.blue.withValues(alpha: 0.1), blurRadius: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.blue, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blue.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            trainer.name.substring(0, 1),
                            style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trainer.name,
                              style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trainer.specialization,
                              style: GoogleFonts.inter(color: AppColors.blueLight, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  trainer.rating.toString(),
                                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.work_history_rounded, color: AppColors.textMuted, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  trainer.experience,
                                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    trainer.bio,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: trainer.tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Footer (Price & Action)
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Session Cost', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(trainer.cost, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, height: 1)),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text('/hr', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Session booking with ${trainer.name} requested!')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
