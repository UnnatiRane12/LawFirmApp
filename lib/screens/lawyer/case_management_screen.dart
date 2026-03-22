import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import '../../utils/security_utils.dart';
import 'document_upload_screen.dart';


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
          .select('*, client:profiles!client_id(full_name, email)')
          .eq('lawyer_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _cases = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching cases: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Managed Cases'),
        backgroundColor: AppConstants.primaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCases),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreateCaseDialog(context)),
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
                      Text('No cases yet. Tap + to create one.', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchCases,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cases.length,
                    itemBuilder: (ctx, i) => _buildCaseCard(ctx, _cases[i]),
                  ),
                ),
    );
  }

  Widget _buildCaseCard(BuildContext context, Map<String, dynamic> caseData) {
    final title = caseData['title'] ?? 'Case';
    final clientName = caseData['client']?['full_name'] ?? 'Client';
    final status = caseData['status'] ?? 'Active';
    final timeline = (caseData['timeline'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppConstants.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppConstants.secondaryColor.withOpacity(0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppConstants.secondaryColor,
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : 'C',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Client: $clientName', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            Text('Status: $status  •  ${timeline.length} timeline events', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppConstants.accentColor),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CaseDetailScreen(caseData: caseData, onUpdated: _fetchCases)),
        ),
      ),
    );
  }

  void _showCreateCaseDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final clientEmailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.primaryColor,
        title: const Text('Open New Case'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Case Title', prefixIcon: Icon(Icons.title)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: clientEmailCtrl,
              decoration: const InputDecoration(labelText: 'Client Email', prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.secondaryColor),
            onPressed: () async {
              try {
                final email = clientEmailCtrl.text.trim();
                final clientRes = await _supabase
                    .from('profiles')
                    .select('id')
                    .eq('email', email)
                    .maybeSingle();

                if (clientRes == null) throw 'No client found with email: $email';

                final lawyerId = ref.read(authProvider)!.id;

                await _supabase.from('cases').insert({
                  'title': titleCtrl.text.trim(),
                  'client_id': clientRes['id'],
                  'lawyer_id': lawyerId,
                  'status': 'Active',
                  'timeline': [
                    {
                      'title': 'Case Initiated',
                      'description': 'Your case has been officially opened.',
                      'date': DateTime.now().toIso8601String(),
                    }
                  ],
                });

                if (ctx.mounted) Navigator.pop(ctx);
                _fetchCases();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CASE DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CaseDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> caseData;
  final VoidCallback onUpdated;

  const CaseDetailScreen({super.key, required this.caseData, required this.onUpdated});

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService.client;
  late TabController _tabController;
  late Map<String, dynamic> _caseData;
  List<Map<String, dynamic>> _documents = [];
  bool _loadingDocs = true;

  @override
  void initState() {
    super.initState();
    _caseData = Map<String, dynamic>.from(widget.caseData);
    _tabController = TabController(length: 2, vsync: this);
    _fetchDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDocuments() async {
    setState(() => _loadingDocs = true);
    try {
      final res = await _supabase
          .from('documents')
          .select()
          .eq('case_id', _caseData['id'])
          .order('created_at', ascending: false);
      setState(() {
        _documents = List<Map<String, dynamic>>.from(res);
        _loadingDocs = false;
      });
    } catch (e) {
      debugPrint('Doc fetch error: $e');
      setState(() => _loadingDocs = false);
    }
  }

  Future<void> _refreshCase() async {
    try {
      final res = await _supabase
          .from('cases')
          .select('*, client:profiles!client_id(full_name, email)')
          .eq('id', _caseData['id'])
          .single();
      setState(() => _caseData = Map<String, dynamic>.from(res));
      widget.onUpdated();
    } catch (e) {
      debugPrint('Case refresh error: $e');
    }
  }

  Future<void> _updateStatus(String newStatus, {bool? isWon}) async {
    try {
      final updates = {
        'status': newStatus,
        if (isWon != null) 'is_won': isWon,
        if (newStatus == 'Closed') 'closed_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase.from('cases').update(updates).eq('id', _caseData['id']);
      
      if (newStatus == 'Closed') {
        final resultText = isWon == true ? 'Case Won! 🏆' : 'Case Closed.';
        await _addTimelineEvent('Case Resolution', 'The case has been marked as $newStatus. Result: $resultText');
      } else {
        await _refreshCase();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addTimelineEvent(String title, String description) async {
    final existing = List<dynamic>.from(_caseData['timeline'] ?? []);
    existing.add({
      'title': title,
      'description': description,
      'date': DateTime.now().toIso8601String(),
    });
    try {
      await _supabase.from('cases').update({'timeline': existing}).eq('id', _caseData['id']);
      await _refreshCase();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddTimelineDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.primaryColor,
        title: const Text('Add Timeline Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Event Title', prefixIcon: Icon(Icons.bookmark)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes)),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.secondaryColor),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await _addTimelineEvent(titleCtrl.text.trim(), descCtrl.text.trim());
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _caseData['title'] ?? 'Case';
    final clientName = _caseData['client']?['full_name'] ?? 'Client';
    final status = _caseData['status'] ?? 'Active';
    final timeline = List<dynamic>.from(_caseData['timeline'] ?? []);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppConstants.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
            Tab(icon: Icon(Icons.folder), text: 'Documents'),
          ],
          indicatorColor: AppConstants.accentColor,
          labelColor: AppConstants.accentColor,
          unselectedLabelColor: Colors.white54,
        ),
      ),
      body: Column(
        children: [
          // Case header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppConstants.primaryColor.withOpacity(0.5),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Client: $clientName', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Status: ', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          DropdownButton<String>(
                            value: status,
                            dropdownColor: AppConstants.primaryColor,
                            underline: const SizedBox(),
                            style: const TextStyle(color: AppConstants.accentColor, fontWeight: FontWeight.bold),
                            items: ['Active', 'Pending', 'Closed']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) async {
                              if (v == null) return;
                              if (v == 'Closed') {
                                final won = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppConstants.primaryColor,
                                    title: const Text('Close Case'),
                                    content: const Text('Was this case won? This will update your performance record.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Lost', style: TextStyle(color: Colors.redAccent))),
                                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Won')),
                                    ],
                                  ),
                                );
                                await _updateStatus(v, isWon: won);
                              } else {
                                await _updateStatus(v);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── TIMELINE TAB ──
                Stack(
                  children: [
                    timeline.isEmpty
                        ? Center(child: Text('No timeline events yet.', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: timeline.length,
                            itemBuilder: (ctx, i) {
                              final item = timeline[i] as Map;
                              final isLast = i == timeline.length - 1;
                              return _buildTimelineItem(item, isLast);
                            },
                          ),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: FloatingActionButton.extended(
                        backgroundColor: AppConstants.secondaryColor,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Add Event', style: TextStyle(color: Colors.white)),
                        onPressed: _showAddTimelineDialog,
                      ),
                    ),
                  ],
                ),
                // ── DOCUMENTS TAB ──
                Stack(
                  children: [
                    _loadingDocs
                        ? const Center(child: CircularProgressIndicator())
                        : _documents.isEmpty
                            ? Center(child: Text('No documents uploaded yet.', style: TextStyle(color: Colors.white54)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _documents.length,
                                itemBuilder: (ctx, i) => _buildDocumentCard(_documents[i]),
                              ),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: FloatingActionButton.extended(
                        backgroundColor: AppConstants.secondaryColor,
                        icon: const Icon(Icons.upload_file, color: Colors.white),
                        label: const Text('Upload', style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DocumentUploadScreen(caseId: _caseData['id'])),
                          );
                          _fetchDocuments();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map item, bool isLast) {
    String dateStr = '';
    try {
      final date = DateTime.parse(item['date'] ?? '');
      dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(date);
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
                width: 14, height: 14,
                decoration: const BoxDecoration(color: AppConstants.accentColor, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppConstants.secondaryColor.withOpacity(0.4))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.secondaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? 'Event', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                    if ((item['description'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(item['description'], style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                    ],
                    const SizedBox(height: 6),
                    Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final name = doc['file_name'] ?? 'Document';
    final isProtected = doc['password_hash'] != null;
    final filePath = doc['file_path'] ?? '';
    final uploadedAt = DateFormat('MMM dd, yyyy').format(
      DateTime.tryParse(doc['created_at'] ?? '') ?? DateTime.now(),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppConstants.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppConstants.secondaryColor.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: const Icon(Icons.description, color: AppConstants.accentColor),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$uploadedAt${isProtected ? ' • 🔒 Protected' : ' • 🔓 Open Access'}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, color: AppConstants.accentColor),
          tooltip: 'Open Document',
          onPressed: () => _openDocument(doc, filePath, isProtected),
        ),
      ),
    );
  }

  Future<void> _openDocument(
    Map<String, dynamic> doc,
    String filePath,
    bool isProtected,
  ) async {
    if (isProtected) {
      // Show password prompt before opening
      final passwordCtrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppConstants.primaryColor,
          title: const Text('🔒 Protected Document'),
          content: TextField(
            controller: passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter Document Password',
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.secondaryColor),
              onPressed: () {
                final hash = DocumentSecuritySync.hashPassword(passwordCtrl.text);
                if (hash == doc['password_hash']) {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Incorrect password.')),
                  );
                }
              },
              child: const Text('Open', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      // Generate a signed URL valid for 1 hour
      final signedUrl = await _supabase.storage
          .from('legal_docs')
          .createSignedUrl(filePath, 3600);

      final uri = Uri.parse(signedUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the document.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }
}

