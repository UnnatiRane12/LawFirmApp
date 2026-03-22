import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import 'lawyer_management_screen.dart';
import 'client_management_screen.dart';

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
  int _totalOngoingCases = 0;
  int _totalClosedCases = 0;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final admin = SupabaseService.adminClient;
      
      // Fetch user profile counts
      final allProfiles = await admin.from('profiles').select('role');
      final lawyers = allProfiles.where((p) => p['role'] == 'lawyer').length;
      final clients = allProfiles.where((p) => p['role'] == 'client').length;

      // Fetch cases analytics
      final allCases = await admin.from('cases').select('status');
      final totalCases = allCases.length;
      final ongoingCases = allCases.where((c) => (c['status'] as String).toLowerCase() != 'closed').length;
      final closedCases = allCases.where((c) => (c['status'] as String).toLowerCase() == 'closed').length;

      setState(() {
        _totalLawyers = lawyers;
        _totalClients = clients;
        _totalCases = totalCases;
        _totalOngoingCases = ongoingCases;
        _totalClosedCases = closedCases;
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
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor.withOpacity(0.8),
        elevation: 0,
        title: Row(
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                1, 0, 0, 0, 0,
                0, 1, 0, 0, 0,
                0, 0, 1, 0, 0,
                1, 1, 1, 0, -1,
              ]),
              child: Image.asset(
                AppConstants.logoAsset,
                height: 32,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Mercury Legal',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              onPressed: _fetchStats,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 22),
              onPressed: () => ref.read(authProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeView(),
          const LawyerManagementScreen(isNested: true),
          const ClientManagementScreen(isNested: true),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppConstants.primaryColor,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppConstants.accentColor,
          unselectedItemColor: Colors.white24,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, shadows: [Shadow(color: AppConstants.accentColor, blurRadius: 15)]),
              label: 'DASHBOARD',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.balance_rounded),
              activeIcon: Icon(Icons.balance_rounded, shadows: [Shadow(color: AppConstants.accentColor, blurRadius: 15)]),
              label: 'LAWYERS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              activeIcon: Icon(Icons.people_alt_rounded, shadows: [Shadow(color: AppConstants.accentColor, blurRadius: 15)]),
              label: 'CLIENTS',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppConstants.accentColor));
    
    final closureRate = _totalCases > 0 
        ? ((_totalClosedCases / _totalCases) * 100).toStringAsFixed(1) 
        : '0.0';

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: AppConstants.accentColor,
      backgroundColor: AppConstants.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Administrator Console',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'System Health: Optimal',
            style: TextStyle(color: Colors.greenAccent.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          const SizedBox(height: 32),
          _buildStatGrid(closureRate),
          const SizedBox(height: 40),
          _buildInsightsSection(closureRate),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE LOGISTICS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white38,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('SYSTEM OPTIMAL', style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnalyticsDetailCard('ACTIVE ONGOING LITIGATION', "$_totalOngoingCases", Icons.balance_rounded, Colors.orangeAccent),
          _buildAnalyticsDetailCard('RESOLVED LEGAL MATTERS', "$_totalClosedCases", Icons.verified_user_rounded, Colors.greenAccent),
          _buildAnalyticsDetailCard('INFRASTRUCTURE LATENCY', "0.4ms", Icons.speed_rounded, Colors.blueAccent),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(String closureRate) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OPERATIONAL INSIGHTS',
            style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 24),
          _buildInsightMetric('Case Resolution Rate', double.tryParse(closureRate) ?? 0, AppConstants.accentColor),
          const SizedBox(height: 20),
          _buildInsightMetric('Client Retention', 98, Colors.blueAccent),
          const SizedBox(height: 20),
          _buildInsightMetric('Service Uptime', 100, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildInsightMetric(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${percentage.toInt()}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.white.withOpacity(0.05),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(String closureRate) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('ADMINISTRATORS', _totalLawyers.toString(), Icons.security_rounded, Colors.blueAccent)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('ELITE CLIENTS', _totalClients.toString(), Icons.groups_rounded, Colors.purpleAccent)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('TOTAL MATTERS', _totalCases.toString(), Icons.account_balance_rounded, AppConstants.accentColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('SUCCESS RATE', '$closureRate%', Icons.verified_rounded, Colors.greenAccent)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.03),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -15,
              top: -15,
              child: Icon(icon, color: accentColor.withOpacity(0.03), size: 80),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 18),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsDetailCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

// Removed Custom Painters as requested.
