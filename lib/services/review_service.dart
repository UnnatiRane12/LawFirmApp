import '../models/review_model.dart';
import 'supabase_service.dart';

class ReviewService {
  static final _supabase = SupabaseService.client;

  static Future<List<ReviewModel>> getLawyerReviews(String lawyerId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, client:profiles!client_id(full_name)')
          .eq('lawyer_id', lawyerId)
          .order('created_at', ascending: false);

      final List<ReviewModel> reviews = (response as List).map((json) => ReviewModel.fromJson(json)).toList();
      return reviews;
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  static double calculateAverage(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return 5.0;
    final total = reviews.fold<int>(0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }

  static Future<void> submitReview({
    required String clientId,
    required String lawyerId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _supabase.from('reviews').upsert({
        'client_id': clientId,
        'lawyer_id': lawyerId,
        'rating': rating,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error submitting review: $e');
      rethrow;
    }
  }

  static Future<void> deleteReview(String reviewId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getLawyerRating(String lawyerId) async {
    try {
      final response = await _supabase
          .from('lawyer_profiles')
          .select('average_rating, review_count')
          .eq('id', lawyerId)
          .single();
      
      return response;
    } catch (e) {
      print('Error fetching lawyer rating: $e');
      return {'average_rating': 0.0, 'review_count': 0};
    }
  }

  static Future<Map<String, double>> getRatingsSummary() async {
    try {
      final response = await _supabase.from('reviews').select('lawyer_id, rating');
      
      final Map<String, List<int>> lawyerRatings = {};
      for (final item in (response as List)) {
        final id = item['lawyer_id'] as String;
        final rating = item['rating'] as int;
        lawyerRatings.putIfAbsent(id, () => []).add(rating);
      }
      
      final Map<String, double> summary = {};
      lawyerRatings.forEach((id, ratings) {
        summary[id] = ratings.fold<int>(0, (a, b) => a + b) / ratings.length;
      });
      
      return summary;
    } catch (e) {
      print('Error fetching ratings summary: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getLawyerCaseStats(String lawyerId) async {
    try {
      final response = await _supabase
          .from('cases')
          .select('id, status, is_won')
          .eq('lawyer_id', lawyerId);
      
      final List<Map<String, dynamic>> cases = List<Map<String, dynamic>>.from(response);
      final total = cases.length;
      final closed = cases.where((c) => (c['status'] as String).toLowerCase() == 'closed').length;
      final won = cases.where((c) => c['is_won'] == true).length;
      
      return {
        'total_cases': total,
        'handled_cases': closed,
        'won_cases': won,
        'win_rate': total > 0 ? (won / total) * 100 : 0.0,
      };
    } catch (e) {
      print('Error fetching case stats: $e');
      return {'total_cases': 0, 'handled_cases': 0, 'won_cases': 0, 'win_rate': 0.0};
    }
  }
}
