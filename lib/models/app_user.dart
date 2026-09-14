import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Represents a document in the `users` Firestore collection.
/// Every person who signs up - whether a client booking appointments or a
/// salon owner managing a salon - gets one of these.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String phone;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.createdAt,
  });

  /// Converts this object into a Map so it can be written to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': userRoleToString(role),
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Builds an AppUser from a Firestore document snapshot.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: userRoleFromString(map['role'] ?? 'client'),
      phone: map['phone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
