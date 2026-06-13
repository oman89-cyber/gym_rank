import '../services/remote_service.dart';

class GymRepository {
  final RemoteService _remote;

  GymRepository(this._remote);

  Future<List<String>> fetchGyms() => _remote.fetchGyms();
  Future<void> addGym(String name) => _remote.addGym(name);
  Future<void> deleteGym(String name) => _remote.deleteGym(name);
}
