import 'package:flutter_test/flutter_test.dart';
import 'package:gym_rank/core/services/challenges_service.dart';
import 'package:gym_rank/core/models/workout_session.dart';
import 'package:gym_rank/core/models/logged_exercise.dart';
import 'package:gym_rank/core/models/exercise_set.dart';

void main() {
  group('ChallengesService Tests', () {
    final challengesService = ChallengesService.instance;

    test('Daily quests track sessions from today', () {
      final now = DateTime.now();
      final todaySession = WorkoutSession(
        id: 'today',
        date: now,
        name: 'Morning Pull',
        durationSeconds: 3600,
        exercises: [
          LoggedExercise(
            name: 'Pullups',
            muscleGroup: 'back',
            sets: [ExerciseSet(reps: 10, weightKg: 0, isBodyweight: true)],
          ),
        ],
      );

      final yesterdaySession = WorkoutSession(
        id: 'yesterday',
        date: now.subtract(const Duration(days: 1)),
        name: 'Evening Push',
        durationSeconds: 3600,
        exercises: [
          LoggedExercise(
            name: 'Pushups',
            muscleGroup: 'chest',
            sets: [ExerciseSet(reps: 10, weightKg: 0, isBodyweight: true)],
          ),
        ],
      );

      final quests = challengesService.compute([todaySession, yesterdaySession]);
      
      // Daily sets quest (index 0: 'daily_sets_15')
      final setsQuest = quests.firstWhere((q) => q.id == 'daily_sets_15');
      expect(setsQuest.current, 1); // Only today's 1 set counts
    });

    test('Weekly quests track sessions from current week', () {
      final now = DateTime.now();
      // Week start is Monday in ChallengesService logic
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonday = DateTime(monday.year, monday.month, monday.day);
      
      final weekSessions = [
        WorkoutSession(
          id: 'w1',
          date: startOfMonday.add(const Duration(hours: 10)),
          name: 'Mon',
          durationSeconds: 0,
          exercises: [],
        ),
        WorkoutSession(
          id: 'w2',
          date: startOfMonday.add(const Duration(days: 1, hours: 10)),
          name: 'Tue',
          durationSeconds: 0,
          exercises: [],
        ),
      ];

      final oldSession = WorkoutSession(
        id: 'old',
        date: startOfMonday.subtract(const Duration(days: 1)), // Sunday
        name: 'Old',
        durationSeconds: 0,
        exercises: [],
      );

      final quests = challengesService.compute([...weekSessions, oldSession]);
      
      final weekDaysQuest = quests.firstWhere((q) => q.id == 'week_days_4');
      expect(weekDaysQuest.current, 2); // Mon and Tue count
    });

    test('Muscle-specific quests count correctly', () {
      final now = DateTime.now();
      final sessions = [
        WorkoutSession(
          id: 's1',
          date: now,
          name: 'Push',
          durationSeconds: 3600,
          exercises: [
            LoggedExercise(
              name: 'Bench Press',
              muscleGroup: 'chest',
              sets: [
                ExerciseSet(reps: 10, weightKg: 100),
                ExerciseSet(reps: 10, weightKg: 100),
              ],
            ),
            LoggedExercise(
              name: 'Squat',
              muscleGroup: 'quads',
              sets: [
                ExerciseSet(reps: 5, weightKg: 140),
              ],
            ),
          ],
        ),
      ];

      final quests = challengesService.compute(sessions);
      
      final chestQuest = quests.firstWhere((q) => q.id == 'daily_chest');
      final legQuest = quests.firstWhere((q) => q.id == 'daily_legs');
      
      expect(chestQuest.current, 2); // 2 sets of bench
      expect(legQuest.current, 1);   // 1 set of squats
    });
  });
}
