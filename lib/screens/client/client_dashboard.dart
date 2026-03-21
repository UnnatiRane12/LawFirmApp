import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import 'legal_awareness_screen.dart';
import 'lawyer_directory_screen.dart';
import 'appointment_status_screen.dart';
import 'client_profile_screen.dart';
import '../common/chat_list_screen.dart';
import '../../providers/navigation_provider.dart';

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
    const ChatListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(clientNavigationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercury Legal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showSignOutConfirmation(context),
          ),
        ],
      ),
      body: _pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => ref.read(clientNavigationProvider.notifier).state = index,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Lawyers'),
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

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _ClientProfileHeader(),
        const SizedBox(height: 24),
        const Text('Overview', style: AppConstants.headingStyle),
        const SizedBox(height: 16),
        _buildSuccessHighlights(),
        const SizedBox(height: 24),
        _buildActionGrid(context, ref),
      ],
    );
  }

  Widget _buildSuccessHighlights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.secondaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Firm Highlights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 8),
          Text('• Over 500 cases won this year.'),
          Text('• Ranked #1 for Corporate Litigation.'),
          Text('• 24/7 client support activated.'),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionCard(
          context, 
          'Lawyers', 
          Icons.gavel, 
          onTap: () => ref.read(clientNavigationProvider.notifier).state = 1,
        ),
        _buildActionCard(
          context, 
          'Appointments', 
          Icons.calendar_month, 
          target: const AppointmentStatusScreen(),
        ),
        _buildActionCard(
          context, 
          'Messages', 
          Icons.chat, 
          onTap: () => ref.read(clientNavigationProvider.notifier).state = 2,
        ),
        _buildActionCard(
          context, 
          'Legal Awareness', 
          Icons.book, 
          target: const LegalAwarenessScreen(),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, {Widget? target, VoidCallback? onTap}) {
    return InkWell(
      onTap: () {
        if (target != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => target));
        } else if (onTap != null) {
          onTap();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppConstants.accentColor),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.primaryColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.secondaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: AppConstants.accentColor,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
                Text(
                  _userName ?? 'Valued Client',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientProfileScreen()));
            },
          ),
        ],
      ),
    ).onTap(() {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientProfileScreen()));
    });
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
