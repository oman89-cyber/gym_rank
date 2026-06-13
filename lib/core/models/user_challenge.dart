import 'package:cloud_firestore/cloud_firestore.dart';

class UserChallenge {
  final String challengeId;
  final DateTime joinDate;
  final int currentValue;
  final bool isCompleted;
  final bool isExpired;

  UserChallenge({
    required this.challengeId,
    required this.joinDate,
    this.currentValue = 0,
    this.isCompleted = false,
    this.isExpired = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'joinDate': Timestamp.fromDate(joinDate),
      'currentValue': currentValue,
      'isCompleted': isCompleted,
      'isExpired': isExpired,
    };
  }

  factory UserChallenge.fromMap(Map<String, dynamic> map) {
    return UserChallenge(
      challengeId: map['challengeId'] ?? '',
      joinDate: (map['joinDate'] as Timestamp).toDate(),
      currentValue: map['currentValue'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      isExpired: map['isExpired'] ?? false,
    );
  }

  UserChallenge copyWith({
    int? currentValue,
    bool? isCompleted,
    bool? isExpired,
  }) {
    return UserChallenge(
      challengeId: challengeId,
      joinDate: joinDate,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
      isExpired: isExpired ?? this.isExpired,
    );
  }
}
