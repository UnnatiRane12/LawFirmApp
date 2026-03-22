import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import 'chat_screen.dart';
import 'appointment_request_screen.dart';
import 'lawyer_details_screen.dart';
import '../../services/review_service.dart';

class LawyerDirectoryScreen extends StatefulWidget {
  const LawyerDirectoryScreen({super.key});

  @override
  State<LawyerDirectoryScreen> createState() => _LawyerDirectoryScreenState();
}

class _LawyerDirectoryScreenState extends State<LawyerDirectoryScreen> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _lawyers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedSpecialization = 'All';
  Map<String, double> _ratingsSummary = {};
  final List<String> _specializations = [
    'All',
    'Criminal Law',
    'Corporate Law',
    'Family Law',
    'Civil Litigation',
    'Intellectual Property',
    'Cyber Law',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLawyers();
  }

  Future<void> _fetchLawyers() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        _supabase.from('profiles').select('*, lawyer_profiles(*)').eq('role', 'lawyer'),
        ReviewService.getRatingsSummary(),
      ]);
      
      setState(() {
        _lawyers = List<Map<String, dynamic>>.from(results[0] as List);
        _ratingsSummary = results[1] as Map<String, double>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching lawyers: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLawyers {
    return _lawyers.where((l) {
      final prof = (l['lawyer_profiles'] is List && l['lawyer_profiles'].isNotEmpty) 
          ? l['lawyer_profiles'][0] 
          : l['lawyer_profiles'];
      
      final name = (l['full_name'] ?? '').toString().toLowerCase();
      final spec = (prof?['specialization'] ?? '').toString().toLowerCase();
      
      final matchesSearch = name.contains(_searchQuery.toLowerCase()) || spec.contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedSpecialization == 'All' || spec.contains(_selectedSpecialization.toLowerCase());
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mercury Lawyers')),
      body: RefreshIndicator(
        onRefresh: _fetchLawyers,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by name or specialization...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppConstants.primaryColor.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButtonFormField<String>(
                value: _selectedSpecialization,
                decoration: InputDecoration(
                  labelText: 'Filter by Specialization',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.filter_list),
                ),
                items: _specializations.map((spec) => DropdownMenuItem(
                  value: spec,
                  child: Text(spec),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSpecialization = val);
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLawyers.isEmpty
                      ? const Center(child: Text('No lawyers found matches your search.'))
                      : ListView.builder(
                          itemCount: _filteredLawyers.length,
                          itemBuilder: (context, index) => _buildLawyerCard(_filteredLawyers[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLawyerCard(Map<String, dynamic> lawyer) {
    final name = lawyer['full_name'] ?? 'Unknown Lawyer';
    
    // Safely handle lawyer_profiles being either a List or a Map
    final rawProfs = lawyer['lawyer_profiles'];
    final prof = (rawProfs is List && rawProfs.isNotEmpty) 
        ? rawProfs[0] 
        : (rawProfs is Map ? rawProfs : null);

    final specialization = prof?['specialization'] ?? 'Legal Consultant';
    final avgRating = _ratingsSummary[lawyer['id']] ?? 5.0;
    final rating = avgRating.toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.accentColor,
          child: Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(specialization),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(rating, style: const TextStyle(fontSize: 12)),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LawyerDetailsScreen(lawyer: lawyer),
            ),
          );
          _fetchLawyers();
        },
      ),
    );
  }
}
