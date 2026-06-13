import 'package:flutter_test/flutter_test.dart';
import 'package:gym_rank/core/services/elo_service.dart';
import 'package:gym_rank/core/models/workout_session.dart';
import 'package:gym_rank/core/models/logged_exercise.dart';
import 'package:gym_rank/core/models/exercise_set.dart';

void main() {
  group('EloService Tests', () {
    final eloService = EloService.instance;

    test('Empty sessions return 0 ELO', () {
      expect(eloService.calculate([]), 0.0);
    });

    test('Logarithmic scaling prevents ELO inflation', () {
      // Creating a "Heavy" session (10k kg volume)
      final session1 = WorkoutSession(
        id: '1',
        date: DateTime.now(),
        name: 'Heavy',
        durationSeconds: 3600,
        exercises: [
          LoggedExercise(
            name: 'Bench Press',
            muscleGroup: 'chest',
            sets: [
              ExerciseSet(reps: 10, weightKg: 1000), 
            ],
          ),
        ],
      );

      final score1 = eloService.calculate([session1]);
      
      // Creating an "Impossible" session (25x the volume of session 1)
      final session2 = session1.copyWith(
        id: '2',
        exercises: [
          LoggedExercise(
            name: 'Monster Lift',
            muscleGroup: 'chest',
            sets: [
              ExerciseSet(reps: 250, weightKg: 1000), 
            ],
          ),
        ],
      );
      
      final score2 = eloService.calculate([session2]);
      
      // Score should increase
      expect(score2, greaterThan(score1));
      // With 25x raw volume, ELO should NOT be 25x higher (compression check)
      // Math: raw1=130 (elo~25), raw2=3250 (elo~393). 393/25 = 15.7x. 
      // 15.7 is significantly less than 25.
      expect(score2, lessThan(score1 * 18)); 
    });

    test('Muscle group multipliers are correctly applied', () {
      final chestSession = WorkoutSession(
        id: 'chest',
        date: DateTime.now(),
        name: 'Chest',
        durationSeconds: 1800,
        exercises: [
          LoggedExercise(
            name: 'Press',
            muscleGroup: 'chest', // 1.3 mult
            sets: [ExerciseSet(reps: 10, weightKg: 100)],
          ),
        ],
      );

      final calfSession = WorkoutSession(
        id: 'calves',
        date: DateTime.now(),
        name: 'Calves',
        durationSeconds: 1800,
        exercises: [
          LoggedExercise(
            name: 'Raise',
            muscleGroup: 'calves', // 0.7 mult
            sets: [ExerciseSet(reps: 10, weightKg: 100)],
          ),
        ],
      );

      final chestElo = eloService.calculate([chestSession]);
      final calfElo = eloService.calculate([calfSession]);

      expect(chestElo, greaterThan(calfElo));
    });

    test('Bodyweight exercises are rewarded correctly', () {
      final bwSession = WorkoutSession(
        id: 'bw',
        date: DateTime.now(),
        name: 'Pullups',
        durationSeconds: 600,
        exercises: [
          LoggedExercise(
            name: 'Pullup',
            muscleGroup: 'back',
            sets: [
              ExerciseSet(reps: 10, weightKg: 0, isBodyweight: true),
              ExerciseSet(reps: 10, weightKg: 0, isBodyweight: true),
            ],
          ),
        ],
      );

      final elo = eloService.calculate([bwSession]);
      expect(elo, greaterThan(0));
    });

    test('Radar scores are normalized 0-100', () {
      final sessions = [
        WorkoutSession(
          id: '1',
          date: DateTime.now(),
          name: 'Main',
          durationSeconds: 1800,
          exercises: [
            LoggedExercise(
              name: 'Bench',
              muscleGroup: 'chest',
              sets: [ExerciseSet(reps: 10, weightKg: 100)],
            ),
            LoggedExercise(
              name: 'Bicep Curl',
              muscleGroup: 'biceps',
              sets: [ExerciseSet(reps: 10, weightKg: 10)],
            ),
          ],
        ),
      ];

      final scores = eloService.radarScores(sessions);
      
      expect(scores['chest'], 100.0); // Chest has highest volume
      expect(scores['biceps'], lessThan(100.0));
      expect(scores['biceps'], greaterThan(0.0));
      expect(scores['back'], 0.0); // No back work
    });
  });
}
