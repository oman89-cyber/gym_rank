import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/workout_session.dart';
import '../models/logged_exercise.dart';
import '../models/exercise_set.dart';
import '../repositories/workout_repository.dart';
import 'repository_providers.dart';
import '../services/elo_service.dart';
import 'profile_provider.dart';

/// Returns the most recent workout session containing a specific exercise.
final lastExercisePerformanceProvider = Provider.family<LoggedExercise?, String>((ref, exerciseName) {
  final sessions = ref.watch(sessionsProvider);
  for (final session in sessions.reversed) {
    for (final ex in session.exercises) {
      if (ex.name == exerciseName) return ex;
    }
  }
  return null;
});

/// Returns the personal best (highest volume set) for a specific exercise.
final exercisePersonalBestProvider = Provider.family<double, String>((ref, exerciseName) {
  final sessions = ref.watch(sessionsProvider);
  double maxVolume = 0;
  for (final session in sessions) {
    for (final ex in session.exercises) {
      if (ex.name == exerciseName) {
        for (final set in ex.sets) {
          final vol = set.weightKg * set.reps;
          if (vol > maxVolume) maxVolume = vol;
        }
      }
    }
  }
  return maxVolume;
});

// ── Saved sessions (history) ───────────────────────────────────────────────
final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, List<WorkoutSession>>((ref) {
  final notifier = SessionsNotifier(ref.watch(workoutRepositoryProvider));
  final sub = ref.watch(authServiceProvider).onDataRestored.listen((_) {
    notifier.refresh();
  });
  ref.onDispose(() => sub.cancel());
  return notifier;
});

class SessionsNotifier extends StateNotifier<List<WorkoutSession>> {
  final WorkoutRepository _repo;
  SessionsNotifier(this._repo) : super(_repo.getSessions());

  void refresh() => state = _repo.getSessions();

  Future<void> add(WorkoutSession session) async {
    await _repo.saveSession(session);
    state = _repo.getSessions();
  }

  Future<void> remove(String id) async {
    await _repo.deleteSession(id);
    state = _repo.getSessions();
  }
}

// ── Saved routines (templates) ─────────────────────────────────────────────
final routinesProvider =
    StateNotifierProvider<RoutinesNotifier, List<WorkoutSession>>((ref) {
  final notifier = RoutinesNotifier(ref.watch(workoutRepositoryProvider));
  final sub = ref.watch(authServiceProvider).onDataRestored.listen((_) {
    notifier.refresh();
  });
  ref.onDispose(() => sub.cancel());
  return notifier;
});

class RoutinesNotifier extends StateNotifier<List<WorkoutSession>> {
  final WorkoutRepository _repo;
  RoutinesNotifier(this._repo) : super(_repo.getRoutines());

  void refresh() => state = _repo.getRoutines();

  Future<void> save(WorkoutSession routine) async {
    await _repo.saveRoutine(routine);
    state = _repo.getRoutines();
  }

  Future<void> remove(String id) async {
    await _repo.deleteRoutine(id);
    state = _repo.getRoutines();
  }
}

// ── Rest Timer ───────────────────────────────────────────────────────────────
final restTimerProvider = StateNotifierProvider<RestTimerNotifier, int?>((ref) {
  return RestTimerNotifier();
});

class RestTimerNotifier extends StateNotifier<int?> {
  Timer? _timer;

  RestTimerNotifier() : super(null);

  void start([int seconds = 90]) {
    _timer?.cancel();
    state = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state != null && state! > 0) {
        state = state! - 1;
      } else {
        stop();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    state = null;
  }

  void addTime(int seconds) {
    if (state != null) {
      state = state! + seconds;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Workout Editor (for modifying past sessions/routines) ────────────────
final workoutEditorProvider =
    StateNotifierProvider<WorkoutEditorNotifier, WorkoutSession?>((ref) {
  return WorkoutEditorNotifier(ref);
});

class WorkoutEditorNotifier extends StateNotifier<WorkoutSession?> {
  final Ref _ref;
  bool _isRoutine = false;

  WorkoutEditorNotifier(this._ref) : super(null);

  void init(WorkoutSession session, bool isRoutine) {
    state = session;
    _isRoutine = isRoutine;
  }

  void addExercise(LoggedExercise exercise) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: [...state!.exercises, exercise],
    );
  }

  void removeExercise(int index) {
    if (state == null) return;
    final updated = [...state!.exercises]..removeAt(index);
    state = state!.copyWith(exercises: updated);
  }

  void addSet(int exerciseIndex, ExerciseSet set) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final ex = exercises[exerciseIndex];
    exercises[exerciseIndex] = LoggedExercise(
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: [...ex.sets, set],
    );
    state = state!.copyWith(exercises: exercises);
  }

  void updateSet(int exerciseIndex, int setIndex, ExerciseSet set) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final ex = exercises[exerciseIndex];
    final sets = [...ex.sets];
    sets[setIndex] = set;
    exercises[exerciseIndex] = LoggedExercise(
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: sets,
    );
    state = state!.copyWith(exercises: exercises);
  }

  void toggleSetComplete(int exerciseIndex, int setIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final ex = exercises[exerciseIndex];
    final sets = [...ex.sets];
    final currentSet = sets[setIndex];
    sets[setIndex] = currentSet.copyWith(isCompleted: !currentSet.isCompleted);
    exercises[exerciseIndex] = LoggedExercise(
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: sets,
    );
    state = state!.copyWith(exercises: exercises);
    
    if (sets[setIndex].isCompleted) {
       _ref.read(restTimerProvider.notifier).start();
    }
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (state == null) return;
    final exercises = [...state!.exercises];
    final ex = exercises[exerciseIndex];
    final sets = [...ex.sets]..removeAt(setIndex);
    exercises[exerciseIndex] = LoggedExercise(
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: sets,
    );
    state = state!.copyWith(exercises: exercises);
  }

  void updateName(String name) {
    if (state == null) return;
    state = state!.copyWith(name: name);
  }

  Future<void> save() async {
    final session = state;
    if (session == null) return;

    if (_isRoutine) {
      await _ref.read(routinesProvider.notifier).save(session);
    } else {
      await _ref.read(sessionsProvider.notifier).add(session);
      // Recalculate ELO since history changed
      final allSessions = _ref.read(workoutRepositoryProvider).getSessions();
      final baseElo = _ref.read(profileProvider).baseElo;
      final newElo = EloService.instance.calculate(allSessions, baseElo: baseElo);
      await _ref.read(profileProvider.notifier).updateElo(newElo);
    }
    state = null;
  }

  void discard() => state = null;
}

// ── Active workout session (in-progress) ──────────────────────────────────
final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState?>((ref) {
  return ActiveWorkoutNotifier(ref);
});

class ActiveWorkoutState {
  final String name;
  final List<LoggedExercise> exercises;
  final DateTime startTime;
  final bool isStarted;

  const ActiveWorkoutState({
    required this.name,
    required this.exercises,
    required this.startTime,
    this.isStarted = false,
  });

  ActiveWorkoutState copyWith({
    String? name,
    List<LoggedExercise>? exercises,
    DateTime? startTime,
    bool? isStarted,
  }) => ActiveWorkoutState(
    name: name ?? this.name,
    exercises: exercises ?? this.exercises,
    startTime: startTime ?? this.startTime,
    isStarted: isStarted ?? this.isStarted,
  );

  double get totalVolume =>
      exercises.fold(0.0, (sum, ex) => sum + ex.totalVolume);
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState?> {
  final Ref _ref;
  ActiveWorkoutNotifier(this._ref) : super(null);

  void start(String name) {
    state = ActiveWorkoutState(
      name: name,
      exercises: [],
      startTime: DateTime.now(),
      isStarted: false,
    );
  }

  void startWorkout() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      isStarted: true,
      startTime: DateTime.now(), // Reset start time to when they actually hit 'Start'
    );
  }

  void startFromRoutine(WorkoutSession routine) {
    final templateExercises = routine.exercises.map((e) => LoggedExercise(
      name: e.name,
      muscleGroup: e.muscleGroup,
      rawMuscles: [...e.rawMuscles],
      sets: e.sets.map((s) => s.copyWith(
        id: const Uuid().v4(), // New IDs for a new session
        isCompleted: false,     // Reset completion status
      )).toList(),
    )).toList();

    state = ActiveWorkoutState(
      name: routine.name,
      exercises: templateExercises,
      startTime: DateTime.now(),
      isStarted: false,
    );
  }

  void addExercise(LoggedExercise exercise) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      exercises: [...current.exercises, exercise],
    );
  }

  void removeExercise(int index) {
    final current = state;
    if (current == null) return;
    final updated = [...current.exercises]..removeAt(index);
    state = current.copyWith(exercises: updated);
  }

  void addSet(int exerciseIndex, ExerciseSet set) {
    final current = state;
    if (current == null) return;
    final exercises = [...current.exercises];
    final ex = exercises[exerciseIndex];
    exercises[exerciseIndex] = LoggedExercise(
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: [...ex.sets, set],
    );
    state = current.copyWith(exercises: exercises);
  }

  void updateSet(int exerciseIndex, int setIndex, ExerciseSet set) {
    final current = state;
    if (current == null) return;
    final exercises = [...current.exercises];
    final ex = exercises[exerciseIndex];
    final sets = [...ex.sets];
    sets[setIndex] = set;
    exercises[exerciseIndex] = LoggedExercise(
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: sets,
    );
    state = current.copyWith(exercises: exercises);
  }

  void toggleSetComplete(int exerciseIndex, int setIndex) {
    final current = state;
    if (current == null) return;
    final exercises = [...current.exercises];
    final ex = exercises[exerciseIndex];
    final sets = [...ex.sets];
    final currentSet = sets[setIndex];
    sets[setIndex] = currentSet.copyWith(isCompleted: !currentSet.isCompleted);
    exercises[exerciseIndex] = LoggedExercise(
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: sets,
    );
    state = current.copyWith(exercises: exercises);

    if (sets[setIndex].isCompleted) {
      _ref.read(restTimerProvider.notifier).start();
    }
  }

  void removeSet(int exerciseIndex, int setIndex) {
    final current = state;
    if (current == null) return;
    final exercises = [...current.exercises];
    final ex = exercises[exerciseIndex];
    final sets = [...ex.sets]..removeAt(setIndex);
    exercises[exerciseIndex] = LoggedExercise(
      name: ex.name,
      muscleGroup: ex.muscleGroup,
      sets: sets,
    );
    state = current.copyWith(exercises: exercises);
  }

  /// Finishes the workout: saves to Hive, recalculates ELO, posts to feed.
  Future<WorkoutSession?> finish(String id) async {
    final current = state;
    if (current == null) return null;

    final duration = DateTime.now().difference(current.startTime).inSeconds;

    final session = WorkoutSession(
      id: id,
      date: current.startTime,
      name: current.name,
      exercises: current.exercises,
      durationSeconds: duration,
    );

    // Persist session
    await _ref.read(sessionsProvider.notifier).add(session);

    // Recalculate ELO
    final allSessions = _ref.read(workoutRepositoryProvider).getSessions();
    final baseElo = _ref.read(profileProvider).baseElo;
    final newElo = EloService.instance.calculate(allSessions, baseElo: baseElo);
    await _ref.read(profileProvider.notifier).updateElo(newElo);
    await _ref.read(profileProvider.notifier).incrementSessions();

    state = null; // clear active session
    _ref.read(restTimerProvider.notifier).stop(); // Stop any running timer
    return session;
  }

  void discard() {
    state = null;
    _ref.read(restTimerProvider.notifier).stop();
  }
}
