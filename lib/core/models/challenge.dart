import 'package:flutter/material.dart';

enum ChallengeDifficulty { easy, medium, hard, extreme }

enum ChallengeGoalType { sets, volume, sessions }

class Challenge {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final IconData? icon;
  final ChallengeDifficulty difficulty;
  final List<String> tags;
  final String duration;
  final String timePerDay;
  final int activeCount;
  final int joinedCount;
  final String creatorName;
  final String? creatorAvatar;
  final bool isTrending;

  // New fields for logic
  final int goalValue;
  final ChallengeGoalType goalType;
  final String? targetMuscle;
  final int eloReward;
  final List<String> steps;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.icon,
    required this.difficulty,
    required this.tags,
    required this.duration,
    required this.timePerDay,
    required this.activeCount,
    required this.joinedCount,
    this.creatorName = 'Gym Rank CEO',
    this.creatorAvatar,
    this.isTrending = false,
    required this.goalValue,
    required this.goalType,
    this.targetMuscle,
    this.eloReward = 50,
    this.steps = const [],
  });
}
