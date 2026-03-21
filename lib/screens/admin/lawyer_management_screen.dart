import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';

class LawyerManagementScreen extends StatefulWidget {
  const LawyerManagementScreen({super.key});

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
      appBar: AppBar(
        title: const Text('Manage Lawyers'),
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
      label: const Text('Create Lawyer Account', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.secondaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
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

    return Card(
      color: AppConstants.primaryColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteLawyer(lawyer['id']),
                ),
              ],
            ),
            Text(email, style: const TextStyle(color: Colors.white70)),
            const Divider(height: 24, color: Colors.white12),
            _buildDetailRow(Icons.work, 'Specialization', spec),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.school, 'Education', edu),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.history, 'Experience', '$exp Years'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppConstants.accentColor),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white60)),
        Expanded(child: Text(value)),
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
        title: const Text('New Lawyer Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: pwdCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Specialization')),
              TextField(controller: eduCtrl, decoration: const InputDecoration(labelText: 'Education')),
              TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Years of Experience'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                  // 2. Manually create the Profile record (since we disabled the trigger)
                  await SupabaseService.adminClient.from('profiles').insert({
                    'id': res.user!.id,
                    'email': emailCtrl.text.trim(),
                    'full_name': nameCtrl.text.trim(),
                    'role': 'lawyer',
                  });

                  // 3. Create the Lawyer-specific Profile details
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
