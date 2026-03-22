import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import 'chat_screen.dart';
import 'appointment_request_screen.dart';

class LawyerDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> lawyer;

  const LawyerDetailsScreen({super.key, required this.lawyer});

  @override
  ConsumerState<LawyerDetailsScreen> createState() => _LawyerDetailsScreenState();
}

class _LawyerDetailsScreenState extends ConsumerState<LawyerDetailsScreen> {
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;
  double _averageRating = 0.0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchReviewData();
  }

  Future<void> _fetchReviewData() async {
    final lawyerId = widget.lawyer['id'];
    setState(() => _isLoadingReviews = true);
    
    final results = await Future.wait<dynamic>([
      ReviewService.getLawyerReviews(lawyerId),
      ReviewService.getLawyerRating(lawyerId),
    ]);

    if (mounted) {
      setState(() {
        _reviews = results[0] as List<ReviewModel>;
        _averageRating = ReviewService.calculateAverage(_reviews);
        _reviewCount = _reviews.length;
        _isLoadingReviews = false;
      });
    }
  }

  void _showReviewDialog() {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24, left: 24, right: 24,
          ),
          decoration: const BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('Rate your experience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('How was your interaction with this lawyer?', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppConstants.secondaryColor,
                    size: 40,
                  ),
                  onPressed: () => setModalState(() => selectedRating = index + 1),
                )),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: commentController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Share your thoughts...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = ref.read(authProvider);
                    if (user == null) return;

                    await ReviewService.submitReview(
                      clientId: user.id,
                      lawyerId: widget.lawyer['id'],
                      rating: selectedRating,
                      comment: commentController.text,
                    );
                    
                    Navigator.pop(context);
                    _fetchReviewData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.lawyer['full_name'] ?? 'Unknown Lawyer';
    final rawProfs = widget.lawyer['lawyer_profiles'];
    final prof = (rawProfs is List && rawProfs.isNotEmpty) ? rawProfs[0] : (rawProfs is Map ? rawProfs : null);
    final specialization = prof?['specialization'] ?? 'Legal Consultant';
    final bio = prof?['bio'] ?? 'Dedicated legal professional committed to excellence.';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppConstants.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConstants.primaryColor, AppConstants.backgroundColor],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppConstants.secondaryColor.withOpacity(0.1),
                    child: Text(name[0], style: const TextStyle(fontSize: 40, color: AppConstants.secondaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(specialization, style: const TextStyle(color: AppConstants.secondaryColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppConstants.secondaryColor, size: 24),
                              const SizedBox(width: 4),
                              Text(_averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          Text('$_reviewCount reviews', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(bio, style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUserId: widget.lawyer['id'], otherUserName: name))),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentRequestScreen(lawyer: widget.lawyer))),
                          icon: const Icon(Icons.calendar_today_rounded),
                          label: const Text('Book'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.secondaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      TextButton.icon(onPressed: _showReviewDialog, icon: const Icon(Icons.add_comment_rounded, size: 18), label: const Text('Write Review'), style: TextButton.styleFrom(foregroundColor: AppConstants.secondaryColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(children: [const Icon(Icons.rate_review_outlined, size: 48, color: Colors.white10), const SizedBox(height: 16), const Text('No reviews yet. Be the first!', style: TextStyle(color: Colors.white24)) ])))
                  else
                    ..._reviews.map((r) => _buildReviewCard(r)).toList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final user = ref.read(authProvider);
    final isOwnReview = user?.id == review.clientId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.clientName ?? 'Verified Client', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Row(
                children: [
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppConstants.secondaryColor,
                      size: 14,
                    )),
                  ),
                  if (isOwnReview) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppConstants.primaryColor,
                            title: const Text('Delete Review?', style: TextStyle(color: Colors.white)),
                            content: const Text('Are you sure you want to remove your feedback?', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ReviewService.deleteReview(review.id);
                          _fetchReviewData();
                        }
                      },
                      child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.7), size: 18),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(review.formattedDate, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          Text(review.comment, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
