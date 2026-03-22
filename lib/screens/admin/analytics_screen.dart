import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _adminClient = SupabaseService.adminClient;
  bool _isLoading = true;

  int _totalOngoingCases = 0;
  int _totalClosedCases = 0;
  int _totalLawyers = 0;
  int _totalClients = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      // Fetch cases count via admin client
      final allCases = await _adminClient.from('cases').select('status');
      final ongoingCases = allCases.where((c) => (c['status'] as String).toLowerCase() != 'closed').length;
      final closedCases = allCases.where((c) => (c['status'] as String).toLowerCase() == 'closed').length;

      // Fetch user profile counts
      final allProfiles = await _adminClient.from('profiles').select('role');
      final lawyers = allProfiles.where((p) => p['role'] == 'lawyer').length;
      final clients = allProfiles.where((p) => p['role'] == 'client').length;

      setState(() {
        _totalOngoingCases = ongoingCases;
        _totalClosedCases = closedCases;
        _totalLawyers = lawyers;
        _totalClients = clients;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to fetch analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCases = _totalOngoingCases + _totalClosedCases;
    // Calculate a basic "success rate" or "closure rate"
    final closureRate = totalCases > 0 
        ? ((_totalClosedCases / totalCases) * 100).toStringAsFixed(1) 
        : '0.0';

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('System Analytics'),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchAnalytics();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Case Performance', style: AppConstants.headingStyle),
                const SizedBox(height: 24),
                _buildAnalyticsCard('Total Cases Ever Opened', "$totalCases", Icons.folder_rounded, AppConstants.accentColor),
                _buildAnalyticsCard('Case Closure Rate', "$closureRate%", Icons.trending_up_rounded, AppConstants.accentColor),
                _buildAnalyticsCard('Ongoing Cases', "$_totalOngoingCases", Icons.timelapse_rounded, AppConstants.accentColor),
                const SizedBox(height: 24),
                const Text('User Metrics', style: AppConstants.headingStyle),
                const SizedBox(height: 24),
                _buildAnalyticsCard('Total Active Clients', "$_totalClients", Icons.people_rounded, AppConstants.accentColor),
                _buildAnalyticsCard('Total Active Lawyers', "$_totalLawyers", Icons.balance_rounded, AppConstants.accentColor),
              ],
            ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: color,
                        shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 10)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
