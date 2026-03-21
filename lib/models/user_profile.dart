// import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { client, lawyer, admin }

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.avatarUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      email: map['email'],
      fullName: map['full_name'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.client,
      ),
      avatarUrl: map['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.toString().split('.').last,
      'avatar_url': avatarUrl,
    };
  }
}
