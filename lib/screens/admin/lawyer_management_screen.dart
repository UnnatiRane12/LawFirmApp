import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import 'package:intl/intl.dart';

class LawyerManagementScreen extends StatefulWidget {
  final bool isNested;
  const LawyerManagementScreen({super.key, this.isNested = false});

  @override
  State<LawyerManagementScreen> createState() => _LawyerManagementScreenState();
}

class _LawyerManagementScreenState extends State<LawyerManagementScreen> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _lawyers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLawyers();
  }

  Future<void> _fetchLawyers() async {
    setState(() => _isLoading = true);
    try {
      // Use Admin Client if available to bypass RLS and see new users immediately
      final client = SupabaseService.adminClient;
      final response = await client
          .from('profiles')
          .select('*, lawyer_profiles(*)')
          .eq('role', 'lawyer');
      
      setState(() {
        _lawyers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching lawyers: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isNested ? Colors.transparent : AppConstants.backgroundColor,
      appBar: widget.isNested ? null : AppBar(
        title: const Text('Manage Lawyers'),
        backgroundColor: AppConstants.primaryColor,
        actions: [
          IconButton(onPressed: _fetchLawyers, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCreateLawyerButton(context),
              const SizedBox(height: 24),
              const Text('Registered Lawyers', style: AppConstants.subHeadingStyle),
              const SizedBox(height: 16),
              if (_lawyers.isEmpty) 
                const Center(child: Text('No lawyers found. Add your first lawyer below.'))
              else
                ..._lawyers.map((l) => _buildLawyerItem(l)),
            ],
          ),
    );
  }

  Widget _buildCreateLawyerButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showCreateLawyerDialog(context),
      icon: const Icon(Icons.person_add, color: Colors.white),
      label: const Text('Create Lawyer Account', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.accentColor,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: AppConstants.accentColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildLawyerItem(Map<String, dynamic> lawyer) {
    final name = lawyer['full_name'] ?? 'No Name';
    final email = lawyer['email'] ?? 'No Email';
    
    // Safety check for the related lawyer_profiles data
    final profs = lawyer['lawyer_profiles'];
    final prof = (profs is List && profs.isNotEmpty) ? profs[0] : (profs is Map ? profs : null);
    
    final spec = prof?['specialization'] ?? 'General Practice';
    final edu = prof?['education'] ?? 'N/A';
    final exp = prof?['experience_years']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showPerformanceDialog(context, lawyer),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          onPressed: () => _deleteLawyer(lawyer['id']),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.white12),
                  ),
                  _buildDetailRow(Icons.work_outline_rounded, 'Specialization', spec),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.school_outlined, 'Education', edu),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.history_toggle_off_rounded, 'Experience', '$exp Years'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppConstants.accentColor.withOpacity(0.7)),
        const SizedBox(width: 14),
        Text(
          '$label: '.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteLawyer(String id) async {
    try {
      // In a real app, you'd also delete from auth.users via Edge Function
      await _supabase.from('profiles').delete().eq('id', id);
      _fetchLawyers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _showPerformanceDialog(BuildContext context, Map<String, dynamic> lawyer) {
    final lawyerId = lawyer['id'];
    final name = lawyer['full_name'] ?? 'Lawyer';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppConstants.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppConstants.accentColor.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.analytics_rounded, color: AppConstants.accentColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name - Performance',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                        ),
                        const Text('Review history and ratings summary', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white38),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<dynamic>(
                future: Future.wait([
                  ReviewService.getLawyerReviews(lawyerId),
                  ReviewService.getLawyerCaseStats(lawyerId),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppConstants.accentColor));
                  }
                  
                  final reviews = (snapshot.data?[0] as List<ReviewModel>?) ?? [];
                  final caseStats = (snapshot.data?[1] as Map<String, dynamic>?) ?? {};
                  
                  // Calculate rating live for accuracy
                  final count = reviews.length;
                  final rating = count > 0 
                      ? reviews.fold<int>(0, (sum, r) => sum + r.rating) / count 
                      : 0.0;

                  final totalCases = caseStats['total_cases'] ?? 0;
                  final wonCases = caseStats['won_cases'] ?? 0;
                  final handledCases = caseStats['handled_cases'] ?? 0;
                  final winRate = caseStats['win_rate'] ?? 0.0;

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppConstants.accentColor),
                                ),
                                Row(
                                  children: List.generate(5, (i) => Icon(
                                    i < rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: AppConstants.accentColor,
                                    size: 14,
                                  )),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 40, color: Colors.white12),
                            Column(
                              children: [
                                Text(
                                  count.toString(),
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                                const Text('REVIEWS', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'CASE PERFORMANCE',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn('TOTAL', totalCases.toString(), Colors.white),
                            _buildStatColumn('HANDLED', handledCases.toString(), Colors.white70),
                            _buildStatColumn('WON', wonCases.toString(), Colors.greenAccent),
                            _buildStatColumn('WIN RATE', '${winRate.toStringAsFixed(0)}%', AppConstants.accentColor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'CLIENT FEEDBACK',
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      if (reviews.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.rate_review_outlined, color: Colors.white12, size: 48),
                                SizedBox(height: 12),
                                Text('No reviews yet', style: TextStyle(color: Colors.white24)),
                              ],
                            ),
                          ),
                        )
                      else
                        ...reviews.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: List.generate(5, (i) => Icon(
                                      i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: AppConstants.accentColor,
                                      size: 12,
                                    )),
                                  ),
                                  Text(
                                    DateFormat('MMM d, y').format(r.createdAt),
                                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(r.comment, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                            ],
                          ),
                        )),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: valueColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ],
    );
  }

  void _showCreateLawyerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final eduCtrl = TextEditingController();
    final expCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.backgroundColor,
        title: const Text('New Lawyer Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl, 
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: emailCtrl, 
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: pwdCtrl, 
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.white54)), 
                obscureText: true,
              ),
              TextField(
                controller: specCtrl, 
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Specialization', labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: eduCtrl, 
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Education', labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: expCtrl, 
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Years of Experience', labelStyle: TextStyle(color: Colors.white54)), 
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              try {
                // 1. Create the Auth User
                final res = await SupabaseService.adminClient.auth.admin.createUser(
                  AdminUserAttributes(
                    email: emailCtrl.text.trim(),
                    password: pwdCtrl.text.trim(),
                    userMetadata: {'role': 'lawyer', 'full_name': nameCtrl.text.trim()},
                    emailConfirm: true,
                  ),
                );
                
                if (res.user != null) {
                  // 2. Profile record
                  await SupabaseService.adminClient.from('profiles').insert({
                    'id': res.user!.id,
                    'email': emailCtrl.text.trim(),
                    'full_name': nameCtrl.text.trim(),
                    'role': 'lawyer',
                  });

                  // 3. Lawyer Profile
                  await SupabaseService.adminClient.from('lawyer_profiles').insert({
                    'id': res.user!.id,
                    'specialization': specCtrl.text.trim(),
                    'education': eduCtrl.text.trim(),
                    'experience_years': int.tryParse(expCtrl.text) ?? 0,
                  });
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _fetchLawyers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lawyer account created successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            }, 
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
