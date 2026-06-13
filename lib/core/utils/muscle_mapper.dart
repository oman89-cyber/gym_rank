import 'package:flutter_body_atlas/flutter_body_atlas.dart';

/// Translates muscle strings from the JSON database into the specific Muscle enums
/// used by flutter_body_atlas for highlighting the 3D/2D model.
List<MuscleInfo> mapDbMusclesToAtlas(List<dynamic> dbMuscles) {
  List<MuscleInfo> targetMuscles = [];

  for (var muscleName in dbMuscles) {
    switch (muscleName.toString().toLowerCase()) {
      case 'abdominals':
        targetMuscles.addAll(MuscleCatalog.core);
        break;
      case 'hamstrings':
        targetMuscles.addAll(MuscleCatalog.hamstrings);
        break;
      case 'calves':
      case 'quadriceps':
        targetMuscles.addAll(MuscleCatalog.legs);
        break;
      case 'chest':
        targetMuscles.addAll(MuscleCatalog.chest);
        break;
      case 'lower back':
      case 'middle back':
      case 'lats':
      case 'traps':
        targetMuscles.addAll(MuscleCatalog.back);
        break;
      case 'shoulders':
        targetMuscles.addAll(MuscleCatalog.shoulders);
        break;
      case 'biceps':
      case 'triceps':
      case 'forearms':
        targetMuscles.addAll(MuscleCatalog.arms);
        break;
      case 'glutes':
        targetMuscles.addAll(MuscleCatalog.glutes);
        break;
      case 'neck':
        targetMuscles.addAll(MuscleCatalog.neck);
        break;
      case 'adductors':
        targetMuscles.addAll(MuscleCatalog.adductors);
        break;
      default:
        // Try to match based on substrings if exact match fails
        final String name = muscleName.toString().toLowerCase();
        if (name.contains('chest')) targetMuscles.addAll(MuscleCatalog.chest);
        if (name.contains('back')) targetMuscles.addAll(MuscleCatalog.back);
        if (name.contains('leg') || name.contains('quad') || name.contains('calf')) targetMuscles.addAll(MuscleCatalog.legs);
        if (name.contains('shoulder') || name.contains('delt')) targetMuscles.addAll(MuscleCatalog.shoulders);
        if (name.contains('arm') || name.contains('bicep') || name.contains('tricep') || name.contains('forearm')) targetMuscles.addAll(MuscleCatalog.arms);
        if (name.contains('ham')) targetMuscles.addAll(MuscleCatalog.hamstrings);
        if (name.contains('glute')) targetMuscles.addAll(MuscleCatalog.glutes);
        if (name.contains('core') || name.contains('ab')) targetMuscles.addAll(MuscleCatalog.core);
    }
  }

  // Deduplicate before returning
  return targetMuscles.toSet().toList();
}
