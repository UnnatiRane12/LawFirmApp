import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';

class LawyerProfileScreen extends ConsumerStatefulWidget {
  const LawyerProfileScreen({super.key});

  @override
  ConsumerState<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends ConsumerState<LawyerProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select('*, lawyer_profiles(*)')
          .eq('id', user.id)
          .single();
      
      setState(() {
        _profileData = response;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching profile: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profileData == null) return const Scaffold(body: Center(child: Text('Profile not found')));

    final prof = _profileData!['lawyer_profiles'] is List && (_profileData!['lawyer_profiles'] as List).isNotEmpty
        ? _profileData!['lawyer_profiles'][0]
        : _profileData!['lawyer_profiles'];

    return Scaffold(
      appBar: AppBar(title: const Text('My Professional Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppConstants.secondaryColor,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _profileData!['full_name'] ?? 'No Name',
              style: AppConstants.headingStyle,
            ),
          ),
          Center(
            child: Text(
              _profileData!['email'] ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoSection('Professional Details', [
            _buildInfoTile(Icons.work, 'Specialization', prof?['specialization'] ?? 'N/A'),
            _buildInfoTile(Icons.school, 'Education', prof?['education'] ?? 'N/A'),
            _buildInfoTile(Icons.history, 'Experience', '${prof?['experience_years'] ?? 0} Years'),
            _buildInfoTile(Icons.star, 'Rating', '${prof?['rating'] ?? 0.0} / 5.0'),
          ]),
          const SizedBox(height: 24),
          _buildInfoSection('Account Info', [
            _buildInfoTile(Icons.badge, 'Role', _profileData!['role'] ?? 'lawyer'),
            _buildInfoTile(Icons.calendar_today, 'Member Since', 'March 2024'),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppConstants.subHeadingStyle),
        const SizedBox(height: 12),
        Card(
          color: AppConstants.primaryColor,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.accentColor, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.white60)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
