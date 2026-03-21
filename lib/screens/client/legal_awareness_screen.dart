import 'package:flutter/material.dart';
// import '../../utils/constants.dart';
import '../../services/supabase_service.dart';

class LegalAwarenessScreen extends StatefulWidget {
  const LegalAwarenessScreen({super.key});

  @override
  State<LegalAwarenessScreen> createState() => _LegalAwarenessScreenState();
}

class _LegalAwarenessScreenState extends State<LegalAwarenessScreen> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('legal_content').select();
      setState(() {
        _articles = List<Map<String, dynamic>>.from(response);
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
      appBar: AppBar(title: const Text('Legal Awareness')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
              ? const Center(child: Text('No legal articles available yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _articles.length,
                  itemBuilder: (context, index) => _buildArticleCard(_articles[index]),
                ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(article['title'] ?? 'Title', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(article['category'] ?? 'General'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(article['content'] ?? 'No content.', style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }
}
