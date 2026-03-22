import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
          .eq('client_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _cases = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return '🟢';
      case 'closed': return '🔴';
      case 'pending': return '🟡';
      default: return '🔵';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('My Cases'),
        backgroundColor: AppConstants.primaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCases),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text('No active cases found.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCases,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cases.length,
                    itemBuilder: (context, index) => _buildCaseCard(_cases[index]),
                  ),
                ),
    );
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final title = caseData['title'] ?? 'Legal Matter';
    final lawyerName = caseData['lawyer']?['full_name'] ?? 'Assigned Lawyer';
    final status = caseData['status'] ?? 'Active';
    final timeline = (caseData['timeline'] as List?) ?? [];
    final documents = (caseData['documents'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppConstants.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppConstants.secondaryColor.withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.secondaryColor.withOpacity(0.2)),
            ),
            child: const Icon(Icons.gavel_rounded, color: AppConstants.secondaryColor, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Lawyer: $lawyerName', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 2),
              Text('${_statusColor(status)} $status', style: const TextStyle(fontSize: 13)),
            ],
          ),
          iconColor: AppConstants.accentColor,
          collapsedIconColor: AppConstants.accentColor,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  _sectionHeader(Icons.timeline, 'Case Timeline'),
                  const SizedBox(height: 12),
                  if (timeline.isEmpty)
                    Text('No updates yet.', style: TextStyle(color: Colors.white54))
                  else
                    ...timeline.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value as Map;
                      final isLast = i == timeline.length - 1;
                      return _buildTimelineStep(item, isLast);
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConstants.accentColor),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.accentColor)),
      ],
    );
  }

  Widget _buildTimelineStep(Map item, bool isLast) {
    String dateStr = '';
    try {
      final date = DateTime.parse(item['date'] ?? '');
      dateStr = DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      dateStr = item['date'] ?? '';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: const BoxDecoration(
                  color: AppConstants.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppConstants.secondaryColor.withOpacity(0.5)),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  if ((item['description'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item['description'], style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                  ],
                  const SizedBox(height: 4),
                  Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
