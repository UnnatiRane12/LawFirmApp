import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';

class AppointmentStatusScreen extends ConsumerStatefulWidget {
  const AppointmentStatusScreen({super.key});

  @override
  ConsumerState<AppointmentStatusScreen> createState() => _AppointmentStatusScreenState();
}

class _AppointmentStatusScreenState extends ConsumerState<AppointmentStatusScreen> {
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
          .select('*, lawyer:profiles!lawyer_id(*)')
          .eq('client_id', user.id)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(child: Text('You have no upcoming appointments.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) => _buildAppointmentCard(_appointments[index]),
                ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final lawyerName = appointment['lawyer']?['full_name'] ?? 'Unknown Lawyer';
    final date = DateTime.parse(appointment['scheduled_at']).toLocal();
    final status = appointment['status'] ?? 'pending';
    
    Color statusColor = Colors.orange;
    if (status == 'accepted') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.event, color: statusColor),
        ),
        title: Text(lawyerName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(date)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
