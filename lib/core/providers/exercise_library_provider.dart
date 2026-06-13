import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ExerciseItem {
  final String name;
  final String primaryMuscle;
  final bool isBodyweight;
  final List<String> rawMuscles;

  const ExerciseItem({
    required this.name,
    required this.primaryMuscle,
    required this.isBodyweight,
    required this.rawMuscles,
  });
}

final exerciseLibraryProvider = FutureProvider<List<ExerciseItem>>((ref) async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/exercises.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList.map((item) {
      final primaryList = item['primaryMuscles'] as List<dynamic>? ?? [];
      final secondaryList = item['secondaryMuscles'] as List<dynamic>? ?? [];
      final allMuscles = [...primaryList, ...secondaryList].map((e) => e.toString()).toList();

      return ExerciseItem(
        name: item['name'] as String? ?? 'Unknown',
        primaryMuscle: primaryList.isNotEmpty ? primaryList.first.toString() : 'other',
        isBodyweight: item['equipment'] == 'body only',
        rawMuscles: allMuscles,
      );
    }).toList();
  } catch (e) {
    return []; // Return empty on fail (e.g. file not found in tests)
  }
});
