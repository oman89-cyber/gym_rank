/// All hardcoded mock data for the UI-only build of Gym Rank.
library mock_data;

// ── User Profile ──────────────────────────────────────────────────────────────
class MockUser {
  static const String name        = 'Gym Rank CEO';
  static const String username    = '@Gym Rank CEO';
  static const String rank        = 'A';
  static const String rankLabel   = 'A-Rank';
  static const String rankSub     = 'Master';
  static const double eloScore    = 301;
  static const double bodyweight  = 82.5; // kg
  static const String topPercent  = 'TOP 30%';
  static const String level       = 'LVL 4B';
  static const double scoreToNext = 0.72; // 72% to S-Rank
  static const String region      = 'Global';
  static const String unitPref    = 'kg';
}

// ── Radar Chart Raw Data (used by RankScreen via RadarPoint from custom_painters) ──
// Values 0–100 represent strength level per muscle group.
// The RankScreen will construct RadarPoint objects from this list.
class _RawRadar {
  final String label;
  final double value;
  final String rank;
  const _RawRadar(this.label, this.value, this.rank);
}

const List<_RawRadar> _radarRaw = [
  _RawRadar('Chest',     75, 'A-'),
  _RawRadar('Shoulders', 80, 'A+'),
  _RawRadar('Back',      72, 'A-'),
  _RawRadar('Cardio',    18, 'E'),
  _RawRadar('Forearms',  22, 'E+'),
];

/// Returns radar data as plain records for the RankScreen.
List<(String label, double value, String rank)> get mockRadarData =>
    _radarRaw.map((r) => (r.label, r.value, r.rank)).toList();


// ── Muscle Activation (for body visualization) ────────────────────────────────
// Values 0.0 – 1.0 represent activation level this week
const Map<String, double> mockMuscleActivation = {
  'chest':      0.9,
  'shoulders':  0.85,
  'back':       0.8,
  'biceps':     0.6,
  'triceps':    0.5,
  'forearms':   0.3,
  'quads':      0.4,
  'hamstrings': 0.3,
  'glutes':     0.35,
  'calves':     0.2,
  'abs':        0.7,
};

// ── Leaderboard ───────────────────────────────────────────────────────────────
class LeaderboardUser {
  final int position;
  final String? userId; // Added for identifying current user
  final String name;
  final String rank;
  final double score;
  final String gym;
  final String avatarInitials;
  const LeaderboardUser({
    required this.position,
    this.userId,
    required this.name,
    required this.rank,
    required this.score,
    required this.gym,
    required this.avatarInitials,
  });
}

const List<LeaderboardUser> mockGlobalBoard = [
  LeaderboardUser(position: 8, name: 'pullupking',   rank: 'B',  score: 215, gym: 'Tokyo Lift',  avatarInitials: 'PK'),
];

const List<String> mockRegions = [
  'Global', 'India', 'United States', 'Germany', 'United Kingdom',
  'Australia', 'Canada', 'France', 'Japan', 'Brazil',
];

// ── Exercise Library ──────────────────────────────────────────────────────────
class ExerciseItem {
  final String id;
  final String name;
  final String muscle;
  final String category; // 'compound' or 'isolation'
  final String equipment;
  final String difficulty;
  const ExerciseItem({
    required this.id,
    required this.name,
    required this.muscle,
    required this.category,
    required this.equipment,
    required this.difficulty,
  });
}

const List<ExerciseItem> mockExercises = [
  ExerciseItem(id: '1',  name: 'Barbell Squat',       muscle: 'Quads',     category: 'compound',  equipment: 'Barbell',    difficulty: 'Intermediate'),
  ExerciseItem(id: '2',  name: 'Bench Press',          muscle: 'Chest',     category: 'compound',  equipment: 'Barbell',    difficulty: 'Intermediate'),
  ExerciseItem(id: '3',  name: 'Deadlift',             muscle: 'Back',      category: 'compound',  equipment: 'Barbell',    difficulty: 'Advanced'),
  ExerciseItem(id: '4',  name: 'Overhead Press',       muscle: 'Shoulders', category: 'compound',  equipment: 'Barbell',    difficulty: 'Intermediate'),
  ExerciseItem(id: '5',  name: 'Pull-Up',              muscle: 'Back',      category: 'compound',  equipment: 'Bodyweight', difficulty: 'Intermediate'),
  ExerciseItem(id: '6',  name: 'Barbell Row',          muscle: 'Back',      category: 'compound',  equipment: 'Barbell',    difficulty: 'Intermediate'),
  ExerciseItem(id: '7',  name: 'Bicep Curl',           muscle: 'Biceps',    category: 'isolation', equipment: 'Dumbbell',   difficulty: 'Beginner'),
  ExerciseItem(id: '8',  name: 'Tricep Pushdown',      muscle: 'Triceps',   category: 'isolation', equipment: 'Cable',      difficulty: 'Beginner'),
  ExerciseItem(id: '9',  name: 'Leg Press',            muscle: 'Quads',     category: 'compound',  equipment: 'Machine',    difficulty: 'Beginner'),
  ExerciseItem(id: '10', name: 'Romanian Deadlift',    muscle: 'Hamstrings',category: 'compound',  equipment: 'Barbell',    difficulty: 'Intermediate'),
  ExerciseItem(id: '11', name: 'Lateral Raise',        muscle: 'Shoulders', category: 'isolation', equipment: 'Dumbbell',   difficulty: 'Beginner'),
  ExerciseItem(id: '12', name: 'Cable Fly',            muscle: 'Chest',     category: 'isolation', equipment: 'Cable',      difficulty: 'Beginner'),
];

const List<String> muscleGroups = [
  'All', 'Chest', 'Back', 'Shoulders', 'Quads', 'Hamstrings', 'Biceps', 'Triceps',
];

// ── Programs (Explore) ────────────────────────────────────────────────────────
class ProgramItem {
  final String name;
  final String description;
  final String tag;
  final String level;
  final String duration;
  final int daysPerWeek;
  final bool isSaved;
  const ProgramItem({
    required this.name,
    required this.description,
    required this.tag,
    required this.level,
    required this.duration,
    required this.daysPerWeek,
    this.isSaved = false,
  });
}

const List<ProgramItem> mockOfficialPrograms = [
  ProgramItem(
    name: 'Mag-Ort Deadlift Program',
    description: 'Build an elite deadlift',
    tag: 'Strength',
    level: 'Advanced',
    duration: '12-week program',
    daysPerWeek: 3,
  ),
  ProgramItem(
    name: 'PPL',
    description: 'A classic Push Pull Legs split designed to be run 3 times per week. Train push muscles (chest, shoulders, triceps), pull muscles (back, biceps), and legs on separate days.',
    tag: 'Strength',
    level: 'Intermediate',
    duration: '12-week program',
    daysPerWeek: 6,
  ),
  ProgramItem(
    name: 'GZCLP',
    description: 'Linear progression for beginners and intermediates',
    tag: 'Strength',
    level: 'Beginner',
    duration: '8-week program',
    daysPerWeek: 3,
  ),
  ProgramItem(
    name: '5/3/1 BBB',
    description: 'Jim Wendler\'s classic program for building strength and size',
    tag: 'Powerlifting',
    level: 'Intermediate',
    duration: '16-week program',
    daysPerWeek: 4,
  ),
  ProgramItem(
    name: 'nSuns 5/3/1',
    description: 'High volume LP program with great carry-over to all main lifts',
    tag: 'Powerlifting',
    level: 'Intermediate',
    duration: '12-week program',
    daysPerWeek: 5,
  ),
  ProgramItem(
    name: 'Smolov Jr.',
    description: 'Intense 3-week squat or bench specialization cycle',
    tag: 'Strength',
    level: 'Advanced',
    duration: '3-week program',
    daysPerWeek: 4,
  ),
];

const List<ProgramItem> mockCommunityPrograms = [
  ProgramItem(
    name: 'Bro Split Reloaded',
    description: 'Classic bodybuilding split with modern twists',
    tag: 'Hypertrophy',
    level: 'Beginner',
    duration: '8-week program',
    daysPerWeek: 5,
  ),
  ProgramItem(
    name: 'Greyskull LP',
    description: 'Linear progression variant with AMRAP sets for extended progress',
    tag: 'Strength',
    level: 'Beginner',
    duration: '12-week program',
    daysPerWeek: 3,
  ),
];

// ── My Routines ───────────────────────────────────────────────────────────────
class RoutineItem {
  final String name;
  final int completedWorkouts;
  final int totalWorkouts;
  final String weekProgress;
  final int daysPerWeek;
  const RoutineItem({
    required this.name,
    required this.completedWorkouts,
    required this.totalWorkouts,
    required this.weekProgress,
    required this.daysPerWeek,
  });
}

const List<RoutineItem> mockRoutines = [
  RoutineItem(name: 'Push Pull Legs',        completedWorkouts: 6, totalWorkouts: 7, weekProgress: '1/3', daysPerWeek: 6),
  RoutineItem(name: 'Smolov Jr. Bench Press', completedWorkouts: 1, totalWorkouts: 3, weekProgress: '1/3', daysPerWeek: 4),
];

// ── Daily Quests ──────────────────────────────────────────────────────────────
class QuestItem {
  final String title;
  final String description;
  final int xpReward;
  final double progress; // 0.0 – 1.0
  final String icon;
  const QuestItem({
    required this.title,
    required this.description,
    required this.xpReward,
    required this.progress,
    required this.icon,
  });
}

const List<QuestItem> mockDailyQuests = [
  QuestItem(title: 'Iron Beginner',   description: 'Complete 3 sets of any compound lift', xpReward: 50,  progress: 1.0,  icon: '🏋️'),
  QuestItem(title: 'Volume King',     description: 'Log 10,000 kg total volume',            xpReward: 100, progress: 0.73, icon: '📦'),
  QuestItem(title: 'Consistency Pro', description: 'Work out 5 days this week',             xpReward: 75,  progress: 0.6,  icon: '🔥'),
];

// ── Workout Calendar ──────────────────────────────────────────────────────────
// Days in Jan-Feb 2026 that had workouts logged
const List<int> workoutDays = [3, 5, 7, 10, 12, 14, 17, 19, 21, 24];

// ── Muscle Recovery ───────────────────────────────────────────────────────────
class RecoveryItem {
  final String muscle;
  final int percent;
  const RecoveryItem(this.muscle, this.percent);
}

const List<RecoveryItem> mockRecovery = [
  RecoveryItem('Abductors', 100),
  RecoveryItem('Abs',       100),
  RecoveryItem('Chest',     72),
  RecoveryItem('Back',      68),
];
