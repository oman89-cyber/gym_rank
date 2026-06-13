import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background Ambient Glow ──────────────────────────────────────────
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.05),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 5.seconds),
          ),

          CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 32),
                  child: Column(
                    children: [
                      Row(
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
                              child: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('GYM RANK PRO', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('Unleash Your Potential', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text('Join thousands of serious athletes leveling up their game with advanced AI and global rankings.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                    ],
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                ),
              ),

              // ── Features List ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const _FeatureItem(icon: Icons.auto_awesome_rounded, title: 'Unlimited AI Coach', subtitle: 'Personalized advice with zero chat limits'),
                      const SizedBox(height: 16),
                      const _FeatureItem(icon: Icons.analytics_rounded, title: 'Advanced Radar Metrics', subtitle: 'Deep dive into muscle supercompensation models'),
                      const SizedBox(height: 16),
                      const _FeatureItem(icon: Icons.workspace_premium_rounded, title: 'Elite Rank Badges', subtitle: 'Exclusive visual styles for your profile & feed'),
                      const SizedBox(height: 16),
                      const _FeatureItem(icon: Icons.public_rounded, title: 'Global Leaderboard Access', subtitle: 'Compete in regional tiers beyond your home gym'),
                    ].animate(interval: 100.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),

              // ── Pricing Cards ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const _PricingCard(
                        title: '1 Month',
                        price: '₹299',
                        subtitle: '/month',
                        benefit: 'Basic Access',
                      ),
                      const SizedBox(width: 14),
                      const _PricingCard(
                        title: '6 Months',
                        price: '₹1499',
                        subtitle: '₹249/mo',
                        benefit: 'Most Popular',
                        isHighlighted: true,
                        tag: 'SAVE 16%',
                      ),
                      const SizedBox(width: 14),
                      const _PricingCard(
                        title: '1 Year',
                        price: '₹2699',
                        subtitle: '₹224/mo',
                        benefit: 'Best Value',
                        tag: 'SAVE 25%',
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2),
                ),
              ),

              // ── Footer ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text('Secure payments via Razorpay & Stripe', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 6),
                      Text('Cancel anytime. Terms & Conditions apply.', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(subtitle, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String benefit;
  final bool isHighlighted;
  final String? tag;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.benefit,
    this.isHighlighted = false,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.gold.withValues(alpha: 0.12) : AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted ? AppColors.gold : AppColors.border,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted ? [const BoxShadow(color: Color.fromRGBO(255, 215, 0, 0.15), blurRadius: 30, spreadRadius: -10)] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tag != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(6)),
              child: Text(tag!, style: GoogleFonts.inter(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 12),
          ],
          Text(title, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(price, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w900)),
          Text(subtitle, style: GoogleFonts.inter(color: isHighlighted ? AppColors.gold : AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          Text(benefit, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Showcase Only: Checkout session for $price'),
                    backgroundColor: AppColors.gold,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighlighted ? AppColors.gold : AppColors.background,
                foregroundColor: isHighlighted ? Colors.black : Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isHighlighted ? Colors.transparent : AppColors.border)),
              ),
              child: Text('SELECT', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}
