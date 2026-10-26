import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final bool phoneVerified;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;
  final String? provider;

  // Backend Metadata
  final String? householdId;
  final int credits;
  final double cqsScore;
  final String? role;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.phoneVerified = false,
    this.photoUrl,
    this.createdAt,
    this.lastLogin,
    this.provider,
    this.householdId,
    this.credits = 0,
    this.cqsScore = 0.0,
    this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'phoneVerified': phoneVerified,
      'photoUrl': photoUrl,
      'createdAt': createdAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'provider': provider,
      'household_id': householdId,
      'credits': credits,
      'cqs_score': cqsScore,
      'role': role,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      phoneVerified: json['phoneVerified'] ?? false,
      photoUrl: json['photoUrl'],
      createdAt: _parseDate(json['createdAt']),
      lastLogin: _parseDate(json['lastLogin'] ?? json['lastLoginAt']),
      provider: json['provider'],
      householdId: json['household_id'],
      credits: json['credits'] ?? 0,
      cqsScore: (json['cqs_score'] ?? 0.0).toDouble(),
      role: json['role'],
    );
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    bool? phoneVerified,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? provider,
    String? householdId,
    int? credits,
    double? cqsScore,
    String? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      provider: provider ?? this.provider,
      householdId: householdId ?? this.householdId,
      credits: credits ?? this.credits,
      cqsScore: cqsScore ?? this.cqsScore,
      role: role ?? this.role,
    );
  }
}