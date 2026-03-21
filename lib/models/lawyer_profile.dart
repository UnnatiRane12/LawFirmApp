import 'user_profile.dart';

class LawyerProfile {
  final String id;
  final String? bio;
  final String? specialization;
  final int experienceYears;
  final double rating;
  final int reviewsCount;
  final bool isActive;
  final UserProfile? profile; // Linked base profile

  LawyerProfile({
    required this.id,
    this.bio,
    this.specialization,
    this.experienceYears = 0,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.isActive = true,
    this.profile,
  });

  factory LawyerProfile.fromMap(Map<String, dynamic> map, {UserProfile? profile}) {
    return LawyerProfile(
      id: map['id'],
      bio: map['bio'],
      specialization: map['specialization'],
      experienceYears: map['experience_years'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewsCount: map['reviews_count'] ?? 0,
      isActive: map['is_active'] ?? true,
      profile: profile,
    );
  }
}

class LegalContent {
  final String id;
  final String category;
  final String title;
  final String content;

  LegalContent({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
  });

  factory LegalContent.fromMap(Map<String, dynamic> map) {
    return LegalContent(
      id: map['id'],
      category: map['category'],
      title: map['title'],
      content: map['content'],
    );
  }
}
