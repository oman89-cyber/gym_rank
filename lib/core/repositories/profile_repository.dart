import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

/// Orchestrates data flow for the user profile.
/// Reads locally. Writes locally instantly, then syncs remotely async.
class ProfileRepository {
  final SyncService _syncService;

  ProfileRepository(this._syncService);

  UserProfile getProfile() {
    return StorageService.instance.getProfile();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await StorageService.instance.saveProfile(profile);
    _syncService.enqueueTask('saveProfile', profile.toMap());
  }

  Future<UserProfile?> syncRemoteProfile() async {
    final remoteMap = await _syncService.remote.fetchProfile();
    if (remoteMap != null) {
      final profile = UserProfile.fromMap(remoteMap);
      await StorageService.instance.saveProfile(profile);
      return profile;
    }
    return null;
  }
}
