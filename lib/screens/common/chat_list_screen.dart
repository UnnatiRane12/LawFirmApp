import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import '../client/chat_screen.dart'; // We can use the same ChatScreen for everyone

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _supabase = SupabaseService.client;
  List<Map<String, dynamic>> _chatPartners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatPartners();
  }

  Future<void> _fetchChatPartners() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // Find all unique users the current user has messaged
      final response = await _supabase
          .from('messages')
          .select('sender_id, receiver_id')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}');
      
      final Set<String> partnerIds = {};
      for (var msg in (response as List)) {
        if (msg['sender_id'] != user.id) partnerIds.add(msg['sender_id']);
        if (msg['receiver_id'] != user.id) partnerIds.add(msg['receiver_id']);
      }

      if (partnerIds.isEmpty) {
        setState(() {
          _chatPartners = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch profile details for these partners
      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', partnerIds.toList());
      
      setState(() {
        _chatPartners = List<Map<String, dynamic>>.from(profilesResponse);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching chat partners: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Conversations'),
        actions: [
          IconButton(onPressed: _fetchChatPartners, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatPartners.isEmpty
              ? const Center(child: Text('No messages yet. Start a conversation!'))
              : ListView.builder(
                  itemCount: _chatPartners.length,
                  itemBuilder: (context, index) {
                    final partner = _chatPartners[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppConstants.accentColor,
                        child: Text(partner['full_name']?[0]?.toUpperCase() ?? '?'),
                      ),
                      title: Text(partner['full_name'] ?? 'Unknown'),
                      subtitle: Text(partner['role'] ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: partner['id'],
                              otherUserName: partner['full_name'] ?? 'Chat',
                            ),
                          ),
                        );
                        _fetchChatPartners(); // Refresh when coming back
                      },
                    );
                  },
                ),
    );
  }
}
