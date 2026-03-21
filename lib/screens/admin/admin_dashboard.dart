import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import 'lawyer_management_screen.dart';
import 'analytics_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final _supabase = SupabaseService.client;
  int _totalLawyers = 0;
  int _totalClients = 0;
  int _totalCases = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      // Use adminClient to bypass RLS and get accurate total counts
      final admin = SupabaseService.adminClient;
      final lawyers = await admin.from('profiles').select('id').eq('role', 'lawyer');
      final clients = await admin.from('profiles').select('id').eq('role', 'client');
      final cases = await admin.from('cases').select('id');

      setState(() {
        _totalLawyers = (lawyers as List).length;
        _totalClients = (clients as List).length;
        _totalCases = (cases as List).length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Stats fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercury Legal - Admin'),
        actions: [
          IconButton(onPressed: _fetchStats, icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchStats,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Quick Stats', style: AppConstants.headingStyle),
                const SizedBox(height: 16),
                _buildStatGrid(),
                const SizedBox(height: 32),
                const Text('Management Console', style: AppConstants.headingStyle),
                const SizedBox(height: 24),
                _buildAdminActionCard(
                  context,
                  'Manage Lawyers',
                  'Register new lawyers and view list.',
                  Icons.balance,
                  const LawyerManagementScreen(),
                ),
                _buildAdminActionCard(
                  context,
                  'System Analytics',
                  'Detailed performance and monitoring.',
                  Icons.analytics,
                  const AnalyticsScreen(),
                ),
                _buildAdminActionCard(
                  context,
                  'View Clients',
                  'Monitor registered client accounts.',
                  Icons.people,
                  const ClientManagementScreenSkeleton(),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Lawyers', _totalLawyers.toString(), Colors.blue),
        _buildStatCard('Clients', _totalClients.toString(), Colors.purple),
        _buildStatCard('Total Cases', _totalCases.toString(), Colors.orange),
        _buildStatCard('Success Rate', '94%', Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildAdminActionCard(BuildContext context, String title, String subtitle, IconData icon, Widget? target) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppConstants.primaryColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(icon, size: 40, color: AppConstants.accentColor),
        title: Text(title, style: AppConstants.subHeadingStyle),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
        trailing: const Icon(Icons.chevron_right),
        onTap: target != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)) : null,
      ),
    );
  }
}

class ClientManagementScreenSkeleton extends StatelessWidget {
  const ClientManagementScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Database')),
      body: const Center(child: Text('Client database logic coming soon!')),
    );
  }
}
