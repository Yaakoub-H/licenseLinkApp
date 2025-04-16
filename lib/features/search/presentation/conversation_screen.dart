import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:license_link/features/chat/presentation/chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId; // ID of the current logged-in user
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    await _fetchCurrentUserId();
    if (_currentUserId != null) {
      await _fetchConversations();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F39),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5CFF),
        title: const Text(
          'Conversations',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : _conversations.isEmpty
              ? const Center(
                child: Text(
                  'No conversations found',
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: _conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = _conversations[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatScreen(
                                participantName: user['full_name'],
                                participantId: user['id'],
                              ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D5CFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, color: Color(0xFF3D5CFF)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            user['full_name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Future<void> _fetchCurrentUserId() async {
    try {
      final currentUserEmail = _supabase.auth.currentUser?.email;

      if (currentUserEmail == null) {
        throw Exception('User email is null');
      }

      final response =
          await _supabase
              .from('users')
              .select('id, full_name')
              .eq('email', currentUserEmail)
              .single();

      if (response == null || response['id'] == null) {
        throw Exception('User ID not found for email: $currentUserEmail');
      }

      setState(() {
        _currentUserId = response['id'].toString(); // Ensure ID is a String
        _currentUserName = response['full_name'];
      });

      print('Current User ID: $_currentUserId');
      print('Current User Name: $_currentUserName');
    } catch (e) {
      print('Error fetching current user ID: $e');
    }
  }

  Future<void> _fetchConversations() async {
    try {
      if (_currentUserId == null) {
        throw Exception('Current user ID is null');
      }

      // Fetch messages involving the current user
      final response = await _supabase
          .from('messages')
          .select('sender_id, recipient_id')
          .or(
            'sender_id.eq.${_currentUserId},recipient_id.eq.${_currentUserId}',
          );

      if (response.isEmpty) {
        setState(() {
          _conversations = [];
        });
        return;
      }

      final data = response as List<dynamic>;

      // Extract unique participant IDs
      final participantIds = <String>{};
      for (var message in data) {
        final senderId = message['sender_id'].toString(); // Convert to String
        final recipientId =
            message['recipient_id'].toString(); // Convert to String
        final participantId =
            senderId == _currentUserId ? recipientId : senderId;
        participantIds.add(participantId);
      }

      // Fetch participant details from the users table
      final participantsData = <Map<String, dynamic>>[];
      for (var participantId in participantIds) {
        final participantResponse =
            await _supabase
                .from('users')
                .select('id, full_name')
                .eq(
                  'id',
                  int.tryParse(participantId) as Object,
                ) // Convert back to int for query
                .single();

        if (participantResponse != null) {
          participantsData.add({
            'id': participantResponse['id'].toString(), // Ensure ID is a String
            'full_name': participantResponse['full_name'],
          });
        }
      }

      setState(() {
        _conversations = participantsData;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching conversations: $e')),
      );
    }
  }
}
