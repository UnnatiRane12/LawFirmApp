import 'package:intl/intl.dart';

class ReviewModel {
  final String id;
  final String clientId;
  final String lawyerId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? clientName; // Joined from profiles

  ReviewModel({
    required this.id,
    required this.clientId,
    required this.lawyerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.clientName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      clientId: json['client_id'],
      lawyerId: json['lawyer_id'],
      rating: json['rating'],
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      clientName: json['client']?['full_name'],
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(createdAt);
}
