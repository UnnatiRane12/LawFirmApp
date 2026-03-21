import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';

class CaseTrackingScreen extends ConsumerStatefulWidget {
  const CaseTrackingScreen({super.key});

  @override
  ConsumerState<CaseTrackingScreen> createState() => _CaseTrackingScreenState();
}

class _CaseTrackingScreenState extends ConsumerState<CaseTrackingScreen> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  Future<void> _fetchCases() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('cases')
          .select('*, lawyer:profiles!lawyer_id(full_name)')
          .eq('client_id', user.id);
      
      setState(() {
        _cases = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cases')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
              ? const Center(child: Text('No active cases found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cases.length,
                  itemBuilder: (context, index) => _buildCaseItem(_cases[index]),
                ),
    );
  }

  Widget _buildCaseItem(Map<String, dynamic> caseData) {
    final title = caseData['title'] ?? 'Legal Matter';
    final lawyerName = caseData['lawyer']?['full_name'] ?? 'Assigned Lawyer';
    final status = caseData['status'] ?? 'Open';
    final timeline = caseData['timeline'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Lawyer: $lawyerName | Status: $status'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Case Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (timeline.isEmpty)
                  const Text('No updates yet.')
                else
                  ...timeline.map((item) => _buildTimelineStep(item as Map<String, dynamic>)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(Map<String, dynamic> item) {
    return Row(
      children: [
        Column(
          children: [
            const Icon(Icons.check_circle, color: AppConstants.accentColor, size: 20),
            Container(width: 2, height: 30, color: Colors.white24),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['title'] ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(item['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.white54)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
