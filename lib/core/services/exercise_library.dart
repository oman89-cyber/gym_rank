/// Static exercise library — 60+ exercises organised by muscle group.
/// Each entry: (name, primaryMuscle, isBodyweight).
class ExerciseLibrary {
  ExerciseLibrary._();

  static const List<ExerciseItem> all = [
    // ── CHEST ────────────────────────────────────────────────────────
    ExerciseItem('Barbell Bench Press',         'chest',      false),
    ExerciseItem('Dumbbell Bench Press',         'chest',      false),
    ExerciseItem('Incline Barbell Press',        'chest',      false),
    ExerciseItem('Incline Dumbbell Press',       'chest',      false),
    ExerciseItem('Cable Fly',                    'chest',      false),
    ExerciseItem('Dumbbell Fly',                 'chest',      false),
    ExerciseItem('Machine Chest Press',          'chest',      false),
    ExerciseItem('Push-Up',                      'chest',      true),
    ExerciseItem('Dip',                          'chest',      true),

    // ── BACK ─────────────────────────────────────────────────────────
    ExerciseItem('Deadlift',                     'back',       false),
    ExerciseItem('Barbell Row',                  'back',       false),
    ExerciseItem('Dumbbell Row',                 'back',       false),
    ExerciseItem('Pull-Up',                      'back',       true),
    ExerciseItem('Chin-Up',                      'back',       true),
    ExerciseItem('Lat Pulldown',                 'back',       false),
    ExerciseItem('Seated Cable Row',             'back',       false),
    ExerciseItem('T-Bar Row',                    'back',       false),
    ExerciseItem('Face Pull',                    'back',       false),

    // ── SHOULDERS ────────────────────────────────────────────────────
    ExerciseItem('Overhead Press',               'shoulders',  false),
    ExerciseItem('Dumbbell Shoulder Press',      'shoulders',  false),
    ExerciseItem('Lateral Raise',                'shoulders',  false),
    ExerciseItem('Cable Lateral Raise',          'shoulders',  false),
    ExerciseItem('Front Raise',                  'shoulders',  false),
    ExerciseItem('Arnold Press',                 'shoulders',  false),
    ExerciseItem('Rear Delt Fly',                'shoulders',  false),

    // ── BICEPS ───────────────────────────────────────────────────────
    ExerciseItem('Barbell Curl',                 'biceps',     false),
    ExerciseItem('Dumbbell Curl',                'biceps',     false),
    ExerciseItem('Hammer Curl',                  'biceps',     false),
    ExerciseItem('Preacher Curl',                'biceps',     false),
    ExerciseItem('Cable Curl',                   'biceps',     false),
    ExerciseItem('Incline Dumbbell Curl',        'biceps',     false),

    // ── TRICEPS ──────────────────────────────────────────────────────
    ExerciseItem('Tricep Pushdown',              'triceps',    false),
    ExerciseItem('Skull Crusher',                'triceps',    false),
    ExerciseItem('Overhead Tricep Extension',    'triceps',    false),
    ExerciseItem('Close-Grip Bench Press',       'triceps',    false),
    ExerciseItem('Diamond Push-Up',              'triceps',    true),

    // ── QUADS ────────────────────────────────────────────────────────
    ExerciseItem('Barbell Back Squat',           'quads',      false),
    ExerciseItem('Front Squat',                  'quads',      false),
    ExerciseItem('Leg Press',                    'quads',      false),
    ExerciseItem('Hack Squat',                   'quads',      false),
    ExerciseItem('Leg Extension',                'quads',      false),
    ExerciseItem('Bulgarian Split Squat',        'quads',      false),
    ExerciseItem('Goblet Squat',                 'quads',      false),

    // ── HAMSTRINGS ───────────────────────────────────────────────────
    ExerciseItem('Romanian Deadlift',            'hamstrings', false),
    ExerciseItem('Leg Curl',                     'hamstrings', false),
    ExerciseItem('Stiff-Leg Deadlift',           'hamstrings', false),
    ExerciseItem('Nordic Curl',                  'hamstrings', true),
    ExerciseItem('Good Morning',                 'hamstrings', false),

    // ── GLUTES ───────────────────────────────────────────────────────
    ExerciseItem('Hip Thrust',                   'glutes',     false),
    ExerciseItem('Glute Bridge',                 'glutes',     true),
    ExerciseItem('Cable Kickback',               'glutes',     false),
    ExerciseItem('Sumo Deadlift',                'glutes',     false),

    // ── CALVES ───────────────────────────────────────────────────────
    ExerciseItem('Standing Calf Raise',          'calves',     false),
    ExerciseItem('Seated Calf Raise',            'calves',     false),
    ExerciseItem('Donkey Calf Raise',            'calves',     false),

    // ── ABS / CORE ───────────────────────────────────────────────────
    ExerciseItem('Plank',                        'abs',        true),
    ExerciseItem('Crunch',                       'abs',        true),
    ExerciseItem('Hanging Leg Raise',            'abs',        true),
    ExerciseItem('Cable Crunch',                 'abs',        false),
    ExerciseItem('Ab Wheel Rollout',             'abs',        true),
    ExerciseItem('Russian Twist',                'abs',        true),
  ];

  static List<ExerciseItem> search(String query) {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((e) => e.name.toLowerCase().contains(q)).toList();
  }

  static List<ExerciseItem> byMuscle(String muscle) =>
      all.where((e) => e.primaryMuscle == muscle).toList();
}

class ExerciseItem {
  final String name;
  final String primaryMuscle;
  final bool isBodyweight;

  const ExerciseItem(this.name, this.primaryMuscle, this.isBodyweight);
}
