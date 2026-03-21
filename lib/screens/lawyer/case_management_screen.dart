import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
// import '../../utils/constants.dart';
import '../../services/supabase_service.dart';

class CaseManagementScreen extends ConsumerStatefulWidget {
  const CaseManagementScreen({super.key});

  @override
  ConsumerState<CaseManagementScreen> createState() => _CaseManagementScreenState();
}

class _CaseManagementScreenState extends ConsumerState<CaseManagementScreen> {
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
          .select('*, client:profiles!client_id(full_name)')
          .eq('lawyer_id', user.id);
      
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
      appBar: AppBar(
        title: const Text('Managed Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCaseDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
              ? const Center(child: Text('You are not managing any cases yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cases.length,
                  itemBuilder: (context, index) => _buildCaseCard(_cases[index]),
                ),
    );
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final title = caseData['title'] ?? 'Title';
    final clientName = caseData['client']?['full_name'] ?? 'Client';
    final status = caseData['status'] ?? 'Open';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Client: $clientName | Status: $status'),
        trailing: const Icon(Icons.edit, size: 20),
        onTap: () {
          // Future: Edit case details / add timeline item
        },
      ),
    );
  }

  void _showCreateCaseDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final clientEmailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open New Case'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Case Title')),
            const SizedBox(height: 12),
            TextField(controller: clientEmailCtrl, decoration: const InputDecoration(labelText: 'Client Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                // 1. Find client ID by email
                final clientRes = await _supabase.from('profiles').select('id').eq('email', clientEmailCtrl.text.trim()).maybeSingle();
                if (clientRes == null) throw 'Client not found with this email.';

                // 2. Insert case
                await _supabase.from('cases').insert({
                  'title': titleCtrl.text.trim(),
                  'client_id': clientRes['id'],
                  'lawyer_id': ref.read(authProvider)!.id,
                  'status': 'Active',
                  'timeline': [
                    {'title': 'Case Initiated', 'date': DateTime.now().toIso8601String()}
                  ],
                });

                Navigator.pop(context);
                _fetchCases();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
