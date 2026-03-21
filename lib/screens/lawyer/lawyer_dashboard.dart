import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'case_management_screen.dart';
import 'calendar_screen.dart';
import 'appointment_management_screen.dart';
import 'lawyer_profile_screen.dart';
import '../common/chat_list_screen.dart';

class LawyerDashboard extends ConsumerStatefulWidget {
  const LawyerDashboard({super.key});

  @override
  ConsumerState<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends ConsumerState<LawyerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const LawyerHomeScreen(),
    const CaseManagementScreen(),
    const CalendarScreen(),
    const ChatListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercury Legal - Lawyer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Cases'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
        ],
        selectedItemColor: AppConstants.accentColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppConstants.primaryColor,
      ),
    );
  }
}

class LawyerHomeScreen extends StatelessWidget {
  const LawyerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfileHeader(context),
        const SizedBox(height: 24),
        const Text('Daily Overview', style: AppConstants.headingStyle),
        const SizedBox(height: 16),
        _buildStatRow(),
        const SizedBox(height: 24),
        const Text('Quick Actions', style: AppConstants.subHeadingStyle),
        const SizedBox(height: 16),
        _buildActionList(context),
      ],
    );
  }

  Widget _buildStatRow() {
    return Row(
      children: [
        _buildStatCard('Active Cases', '8', Icons.folder),
        const SizedBox(width: 16),
        _buildStatCard('Appointments', '3', Icons.calendar_today),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppConstants.accentColor),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionList(BuildContext context) {
    return Column(
      children: [
        _buildActionItem(context, 'Appointment Requests', Icons.notifications_active, const AppointmentManagementScreen()),
        _buildActionItem(context, 'Legal Templates', Icons.description, null),
        _buildActionItem(context, 'My Profile', Icons.person_pin, const LawyerProfileScreen()),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String title, IconData icon, Widget? target) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.accentColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: target != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)) : null,
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(authProvider);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConstants.secondaryColor, AppConstants.primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                child: Text(
                  user?.userMetadata?['full_name']?[0]?.toUpperCase() ?? 'L',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, Counsel',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      user?.userMetadata?['full_name'] ?? 'Lawyer',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerProfileScreen())),
              ),
            ],
          ),
        );
      },
    );
  }
}
