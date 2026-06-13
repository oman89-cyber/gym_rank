class WorkoutSession {
  final int totalSets;
  final int repsPerSet;
  final Duration restTime;
  
  int currentSet = 1;
  bool isResting = false;
  DateTime? lastStepTime;

  WorkoutSession({
    this.totalSets = 3,
    this.repsPerSet = 10,
    this.restTime = const Duration(seconds: 30),
  });

  bool get isComplete => currentSet > totalSets;

  void nextSet() {
    currentSet++;
    isResting = false;
  }

  void startRest() {
    isResting = true;
    lastStepTime = DateTime.now();
  }
}
