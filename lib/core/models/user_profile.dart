import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Persisted user profile and preferences.
class UserProfile {
  final String username;
  final String? uid;
  final String? email;
  final DateTime? joinDate;
  final String subscriptionStatus; // 'free', 'pro', 'trial'
  final bool isBanned;
  final bool isAdmin;
  final bool isGymOwner;
  final bool isGymTrainer;
  final bool useKg;        // true = kg, false = lbs
  final double eloScore;
  final double baseElo;
  final int totalSessions;
  final bool isOnboarded;
  final double? bodyWeight;
  final double? height;
  final String? goal;
  final String? gym;
  final String? managedGym;
  final List<String> friends; // list of friend UIDs

  const UserProfile({
    required this.username,
    this.uid,
    this.email,
    this.joinDate,
    this.subscriptionStatus = 'free',
    this.isBanned = false,
    this.useKg = true,
    this.eloScore = 0,
    this.baseElo = 0,
    this.totalSessions = 0,
    this.isOnboarded = false,
    this.isAdmin = false,
    this.isGymOwner = false,
    this.isGymTrainer = false,
    this.bodyWeight,
    this.height,
    this.goal,
    this.gym,
    this.managedGym,
    this.friends = const [],
  });

  String get rank {
    if (eloScore >= 2000) return 'SS';
    if (eloScore >= 1200) return 'S';
    if (eloScore >= 800)  return 'A';
    if (eloScore >= 500)  return 'B';
    if (eloScore >= 300)  return 'C';
    if (eloScore >= 150)  return 'D';
    if (eloScore >= 50)   return 'E';
    return 'F';
  }

  String get rankLabel {
    final r = rank;
    switch (r) {
      case 'SS': return 'Ascended';
      case 'S':  return 'Titan';
      case 'A':  return 'Elite';
      case 'B':  return 'Adept';
      case 'C':  return 'Warrior';
      case 'D':  return 'Strongman';
      case 'E':  return 'Recruit';
      default:   return 'Newbie';
    }
  }

  double get nextRankThreshold {
    if (eloScore >= 2000) return 3000; // Final goal
    if (eloScore >= 1200) return 2000;
    if (eloScore >= 800)  return 1200;
    if (eloScore >= 500)  return 800;
    if (eloScore >= 300)  return 500;
    if (eloScore >= 150)  return 300;
    if (eloScore >= 50)   return 150;
    return 50;
  }

  double get progressToNextRank {
    final current = eloScore;
    final target = nextRankThreshold;
    final previous = _getPreviousThreshold(current);
    
    if (target == previous) return 1.0;
    return ((current - previous) / (target - previous)).clamp(0.0, 1.0);
  }

  double _getPreviousThreshold(double score) {
    if (score >= 2000) return 2000;
    if (score >= 1200) return 1200;
    if (score >= 800)  return 800;
    if (score >= 500)  return 500;
    if (score >= 300)  return 300;
    if (score >= 150)  return 150;
    if (score >= 50)   return 50;
    return 0;
  }

  String get topPercent {
    if (eloScore >= 2000) return 'Top 0.1%';
    if (eloScore >= 1200) return 'Top 1%';
    if (eloScore >= 800)  return 'Top 5%';
    if (eloScore >= 500)  return 'Top 15%';
    if (eloScore >= 300)  return 'Top 30%';
    if (eloScore >= 150)  return 'Top 50%';
    return 'Top 80%';
  }

  bool get isProfileComplete =>
      isOnboarded &&
      username.isNotEmpty &&
      bodyWeight != null &&
      height != null &&
      goal != null &&
      goal!.isNotEmpty &&
      gym != null &&
      gym!.isNotEmpty;

  UserProfile copyWith({
    String? username,
    String? uid,
    String? email,
    DateTime? joinDate,
    String? subscriptionStatus,
    bool? isBanned,
    bool? useKg,
    double? eloScore,
    double? baseElo,
    int? totalSessions,
    bool? isOnboarded,
    bool? isAdmin,
    bool? isGymOwner,
    bool? isGymTrainer,
    double? bodyWeight,
    double? height,
    String? goal,
    String? gym,
    String? managedGym,
    List<String>? friends,
  }) => UserProfile(
    username: username ?? this.username,
    uid: uid ?? this.uid,
    email: email ?? this.email,
    joinDate: joinDate ?? this.joinDate,
    subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
    isBanned: isBanned ?? this.isBanned,
    useKg: useKg ?? this.useKg,
    eloScore: eloScore ?? this.eloScore,
    baseElo: baseElo ?? this.baseElo,
    totalSessions: totalSessions ?? this.totalSessions,
    isOnboarded: isOnboarded ?? this.isOnboarded,
    isAdmin: isAdmin ?? this.isAdmin,
    isGymOwner: isGymOwner ?? this.isGymOwner,
    isGymTrainer: isGymTrainer ?? this.isGymTrainer,
    bodyWeight: bodyWeight ?? this.bodyWeight,
    height: height ?? this.height,
    goal: goal ?? this.goal,
    gym: gym ?? this.gym,
    managedGym: managedGym ?? this.managedGym,
    friends: friends ?? this.friends,
  );

  Map<String, dynamic> toMap() => {
    'username': username,
    'uid': uid,
    'email': email,
    'joinDate': joinDate?.toIso8601String(),
    'subscriptionStatus': subscriptionStatus,
    'isBanned': isBanned,
    'useKg': useKg,
    'eloScore': eloScore,
    'baseElo': baseElo,
    'totalSessions': totalSessions,
    'isOnboarded': isOnboarded,
    'isAdmin': isAdmin,
    'isGymOwner': isGymOwner,
    'isGymTrainer': isGymTrainer,
    'bodyWeight': bodyWeight,
    'height': height,
    'goal': goal,
    'gym': gym,
    'managedGym': managedGym,
    'friends': friends,
  };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    DateTime? parsedDate;
    if (map['joinDate'] is Timestamp) {
      parsedDate = (map['joinDate'] as Timestamp).toDate();
    } else if (map['joinDate'] is String) {
      parsedDate = DateTime.tryParse(map['joinDate'] as String);
    }

    return UserProfile(
      username: map['username'] as String? ?? 'Lifter',
      uid: map['uid'] as String?,
      email: map['email'] as String?,
      joinDate: parsedDate,
      subscriptionStatus: map['subscriptionStatus'] as String? ?? 'free',
      isBanned: map['isBanned'] as bool? ?? false,
      useKg: map['useKg'] as bool? ?? true,
      eloScore: (map['eloScore'] as num?)?.toDouble() ?? 0,
      baseElo: (map['baseElo'] as num?)?.toDouble() ?? 0,
      totalSessions: (map['totalSessions'] as num?)?.toInt() ?? 0,
      isOnboarded: map['isOnboarded'] as bool? ?? false,
      isAdmin: map['isAdmin'] as bool? ?? false,
      isGymOwner: map['isGymOwner'] as bool? ?? false,
      isGymTrainer: map['isGymTrainer'] as bool? ?? false,
      bodyWeight: (map['bodyWeight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      goal: map['goal'] as String?,
      gym: map['gym'] as String?,
      managedGym: map['managedGym'] as String?,
      friends: (map['friends'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  factory UserProfile.initial() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(' ').first ?? 'Lifter';
    return UserProfile(
      username: name, 
      isOnboarded: false,
      uid: user?.uid,
      email: user?.email,
      joinDate: DateTime.now(),
    );
  }
}
