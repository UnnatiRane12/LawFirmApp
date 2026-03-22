import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import 'legal_awareness_screen.dart';
import 'lawyer_directory_screen.dart';
import 'appointment_status_screen.dart';
import 'client_profile_screen.dart';
import '../common/chat_list_screen.dart';
import '../../providers/navigation_provider.dart';
import 'case_tracking_screen.dart';
class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
  // Navigation is now handled by clientNavigationProvider in navigation_provider.dart

  final List<Widget> _pages = [
    const ClientHomeScreen(),
    const LawyerDirectoryScreen(),
    const LegalAwarenessScreen(),
    const AppointmentStatusScreen(),
    const CaseTrackingScreen(),
    const ChatListScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(clientNavigationProvider);

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
              icon: const Icon(Icons.logout_rounded, size: 22),
              onPressed: () => _showSignOutConfirmation(context),
            ),
          ),
        ],
      ),
      body: _pages[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => ref.read(clientNavigationProvider.notifier).state = index,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.gavel_rounded), label: 'Lawyers'),
            BottomNavigationBarItem(icon: Icon(Icons.local_library_rounded), label: 'Awareness'),
            BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Appts'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_shared_rounded), label: 'Cases'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Chat'),
          ],
          selectedItemColor: AppConstants.accentColor,
          unselectedItemColor: AppConstants.textSecondaryColor.withOpacity(0.5),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppConstants.primaryColor,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  final _supabase = SupabaseService.client;
  bool _isLoading = true;
  Map<String, dynamic>? _upcomingAppointment;
  List<Map<String, dynamic>> _activeCases = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    try {
      // Fetch upcoming appointment
      final apptResponse = await _supabase
          .from('appointments')
          .select('*, lawyer:profiles!lawyer_id(*)')
          .eq('client_id', user.id)
          .gte('scheduled_at', DateTime.now().toIso8601String())
          .order('scheduled_at', ascending: true)
          .limit(1);

      if (apptResponse.isNotEmpty) {
        _upcomingAppointment = apptResponse.first;
      }

      // Fetch active cases with timeline for latest updates
      final casesResponse = await _supabase
          .from('cases')
          .select('id, title, status, timeline')
          .eq('client_id', user.id)
          .eq('status', 'Active')
          .order('created_at', ascending: false)
          .limit(2);

      _activeCases = List<Map<String, dynamic>>.from(casesResponse);
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      color: AppConstants.accentColor,
      backgroundColor: AppConstants.primaryColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          const _ClientProfileHeader(),
          const SizedBox(height: 40),
          _buildUpcomingStuff(),
          const SizedBox(height: 44),
          _buildSuccessHighlights(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }



  Widget _buildUpcomingStuff() {
    if (_isLoading) {
      return const Column(
        children: [
          SizedBox(height: 40),
          Center(child: CircularProgressIndicator(color: AppConstants.secondaryColor)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Priority Updates',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {}, // Could link to all notifications
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppConstants.accentColor.withOpacity(0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_upcomingAppointment == null && _activeCases.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(child: Text('No upcoming appointments or active cases.', style: TextStyle(color: Colors.white54))),
          ),
        if (_upcomingAppointment != null) _buildAppointmentCard(),
        if (_upcomingAppointment != null && _activeCases.isNotEmpty) const SizedBox(height: 16),
        if (_activeCases.isNotEmpty) ...[
          for (var i = 0; i < _activeCases.length; i++) ...[
            _buildCaseUpdateCard(_activeCases[i]),
            if (i < _activeCases.length - 1) const SizedBox(height: 16),
          ]
        ],
      ],
    );
  }

  Widget _buildAppointmentCard() {
    final date = DateTime.parse(_upcomingAppointment!['scheduled_at']).toLocal();
    final lawyerName = _upcomingAppointment!['lawyer']?['full_name'] ?? 'Lawyer';

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(clientNavigationProvider.notifier).state = 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.event_available_rounded, color: Color(0xFFF59E0B), size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPCOMING APPOINTMENT',
                        style: TextStyle(
                          color: const Color(0xFFF59E0B).withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lawyerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppConstants.textSecondaryColor),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, MMM dd').format(date),
                            style: TextStyle(color: AppConstants.textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time_rounded, size: 14, color: AppConstants.textSecondaryColor),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('hh:mm a').format(date),
                            style: TextStyle(color: AppConstants.textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaseUpdateCard(Map<String, dynamic> caseData) {
    final title = caseData['title'] ?? 'Legal Case';
    final timeline = caseData['timeline'] as List<dynamic>? ?? [];

    String latestUpdate = 'No recent updates.';
    if (timeline.isNotEmpty) {
      final lastEvent = timeline.last as Map<String, dynamic>;
      latestUpdate = lastEvent['title'] ?? 'Review required';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(clientNavigationProvider.notifier).state = 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConstants.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CASE UPDATE',
                        style: TextStyle(
                          color: const Color(0xFF10B981).withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        latestUpdate,
                        style: TextStyle(
                          color: AppConstants.textSecondaryColor,
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHighlights() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppConstants.secondaryColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.secondaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.stars_rounded, color: AppConstants.secondaryColor, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mercury Excellence',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('98%', 'Success Rate'),
              _buildStatItem('500+', 'Cases Won'),
              _buildStatItem('Expert', 'Council'),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Committed to world-class legal representation and absolute client success.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppConstants.textSecondaryColor,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppConstants.secondaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppConstants.textSecondaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ClientProfileHeader extends ConsumerStatefulWidget {
  const _ClientProfileHeader({super.key});

  @override
  ConsumerState<_ClientProfileHeader> createState() => _ClientProfileHeaderState();
}

class _ClientProfileHeaderState extends ConsumerState<_ClientProfileHeader> {
  final _supabase = SupabaseService.client;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    try {
      final response = await _supabase.from('profiles').select('full_name').eq('id', user.id).single();
      if (mounted) {
        setState(() => _userName = response['full_name']);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.person_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Management',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  _userName ?? 'Valued Client',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientProfileScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

void _showSignOutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Consumer(
      builder: (context, ref, _) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

// Helper extension for easier tapping on containers
extension ViewHelper on Widget {
  Widget onTap(VoidCallback callback) {
    return GestureDetector(
      onTap: callback,
      child: this,
    );
  }
}
