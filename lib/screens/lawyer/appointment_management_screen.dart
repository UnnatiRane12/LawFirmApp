import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
// import '../../utils/constants.dart';
import '../../services/supabase_service.dart';

class AppointmentManagementScreen extends ConsumerStatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  ConsumerState<AppointmentManagementScreen> createState() => _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState extends ConsumerState<AppointmentManagementScreen> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('appointments')
          .select('*, client:profiles!client_id(*)')
          .eq('lawyer_id', user.id)
          .order('scheduled_at', ascending: true);
      
      setState(() {
        _appointments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _supabase.from('appointments').update({'status': status}).eq('id', id);
      _fetchAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(child: Text('No appointment requests found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) => _buildAppointmentListItem(_appointments[index]),
                ),
    );
  }

  Widget _buildAppointmentListItem(Map<String, dynamic> appointment) {
    final clientName = appointment['client']?['full_name'] ?? 'Unknown Client';
    final date = DateTime.parse(appointment['scheduled_at']).toLocal();
    final status = appointment['status'] ?? 'pending';
    final notes = appointment['notes'] ?? 'No notes provided.';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _buildStatusBadge(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(DateFormat('MMM dd, yyyy - hh:mm a').format(date)),
            const Divider(height: 24),
            Text('Notes: $notes', style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 16),
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(appointment['id'], 'rejected'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(appointment['id'], 'accepted'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Accept', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'accepted') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
