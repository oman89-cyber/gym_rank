import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/remote_service.dart';
import '../services/firebase_remote_service.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../repositories/workout_repository.dart';
import '../repositories/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final remoteServiceProvider = Provider<RemoteService>((ref) {
  return FirebaseRemoteService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final remote = ref.watch(remoteServiceProvider);
  final service = SyncService(remote);
  // Auto-process queue when initialized
  service.processQueue();
  return service;
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(syncServiceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(syncServiceProvider));
});

