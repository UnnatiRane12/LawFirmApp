import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';

class ClientManagementScreen extends StatefulWidget {
  final bool isNested;
  const ClientManagementScreen({super.key, this.isNested = false});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final _adminClient = SupabaseService.adminClient;
  bool _isLoading = true;
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    try {
      // Query profiles where role is 'client'
      final response = await _adminClient
          .from('profiles')
          .select('*')
          .eq('role', 'client')
          .order('created_at', ascending: false);

      setState(() {
        _clients = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load clients: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clients: $e'), backgroundColor: AppConstants.errorColor),
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
        title: const Text('Client Database'),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchClients();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? _buildEmptyState()
              : _buildClientList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('No clients found', style: AppConstants.subHeadingStyle),
        ],
      ),
    );
  }

  Widget _buildClientList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        final name = client['full_name'] ?? 'Unknown Client';
        final email = client['email'] ?? 'No email provided';
        final createdAtRaw = client['created_at'] != null ? DateTime.tryParse(client['created_at']) : null;
        
        String joinedStr = 'Unknown date';
        if (createdAtRaw != null) {
          joinedStr = "Joined ${createdAtRaw.day}/${createdAtRaw.month}/${createdAtRaw.year}";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ListTile(
              onTap: () => _showClientDetails(client),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppConstants.accentColor, size: 24),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, color: Colors.white38, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: AppConstants.accentColor.withOpacity(0.5), size: 10),
                      const SizedBox(width: 6),
                      Text(
                        joinedStr.toUpperCase(),
                        style: TextStyle(
                          color: AppConstants.accentColor.withOpacity(0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClientDetails(Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClientDetailModal(
        client: client,
        adminClient: _adminClient,
      ),
    );
  }
}

class _ClientDetailModal extends StatefulWidget {
  final Map<String, dynamic> client;
  final dynamic adminClient;

  const _ClientDetailModal({required this.client, required this.adminClient});

  @override
  State<_ClientDetailModal> createState() => _ClientDetailModalState();
}

class _ClientDetailModalState extends State<_ClientDetailModal> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cases = [];

  @override
  void initState() {
    super.initState();
    _fetchClientCases();
  }

  Future<void> _fetchClientCases() async {
    try {
      final response = await widget.adminClient
          .from('cases')
          .select('*, lawyer:profiles!cases_lawyer_id_fkey(full_name)')
          .eq('client_id', widget.client['id'])
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _cases = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching client cases: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.client['full_name'] ?? 'Unknown Client';
    final email = widget.client['email'] ?? 'No email provided';
    final createdAtRaw = widget.client['created_at'] != null ? DateTime.tryParse(widget.client['created_at']) : null;
    
    String joinedStr = 'ACCOUNT ACTIVE SINCE UNKNOWN';
    if (createdAtRaw != null) {
      joinedStr = "ACCOUNT ACTIVE SINCE ${createdAtRaw.day}/${createdAtRaw.month}/${createdAtRaw.year}";
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppConstants.accentColor.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppConstants.accentColor, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppConstants.accentColor.withOpacity(0.2)),
              ),
              child: Text(
                joinedStr,
                style: const TextStyle(color: AppConstants.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'LITIGATION PORTFOLIO',
                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.0),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppConstants.accentColor))
              : _cases.isEmpty
                ? _buildEmptyCases()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _cases.length,
                    itemBuilder: (context, index) {
                      final c = _cases[index];
                      final status = (c['status'] as String).toUpperCase();
                      final lawyerName = c['lawyer']?['full_name'] ?? 'UNASSIGNED';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.all(20),
                            childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    c['title'] ?? 'UNTITLED MATTER',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'CLOSED' ? Colors.greenAccent.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: status == 'CLOSED' ? Colors.greenAccent : Colors.orangeAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.balance_rounded, color: Colors.white24, size: 14),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ASSIGNED: $lawyerName',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            children: [
                              const Divider(color: Colors.white10),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(Icons.history_rounded, color: AppConstants.accentColor, size: 14),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'CASE TIMELINE',
                                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _CaseTimelineView(timeline: List<dynamic>.from(c['timeline'] ?? [])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCases() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 48, color: Colors.white10),
          const SizedBox(height: 16),
          const Text('NO MATTERS FOUND IN PORTFOLIO', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}

class _CaseTimelineView extends StatelessWidget {
  final List<dynamic> timeline;

  const _CaseTimelineView({required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('INITIALIZING CASE HISTORY...', style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w700)),
      );
    }

    return Column(
      children: timeline.reversed.map((u) {
        DateTime date;
        try {
          date = DateTime.parse(u['date'] ?? '');
        } catch (_) {
          date = DateTime.now();
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppConstants.accentColor, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    u['title']?.toString().toUpperCase() ?? 'STATUS UPDATE',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    "${date.day}/${date.month}/${date.year}",
                    style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                u['description'] ?? '',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
