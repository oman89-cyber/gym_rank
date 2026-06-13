import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/gym_repository.dart';
import 'repository_providers.dart';

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return GymRepository(ref.watch(remoteServiceProvider));
});

final gymsProvider = FutureProvider<List<String>>((ref) {
  return ref.read(gymRepositoryProvider).fetchGyms();
});
