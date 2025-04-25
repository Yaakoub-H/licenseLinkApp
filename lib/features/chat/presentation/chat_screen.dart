import 'package:flutter/material.dart';
import 'package:license_link/firebase_notiifcation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final String participantName; // Name of the chat participant
  final String participantId; // ID of the chat participant

  const ChatScreen({
    super.key,
    required this.participantName,
    required this.participantId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late final RealtimeChannel _channel;
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId; // ID of the current logged-in user
  String? _currentUserName; // Name of the current logged-in user
  bool? _isPremium;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId().then((_) => _fetchMessages());
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserId() async {
    try {
      final currentUserEmail = _supabase.auth.currentUser!.email;

      if (currentUserEmail == null) {
        throw Exception('User email is null');
      }

      final response =
          await _supabase
              .from('users')
              .select('id, full_name, is_premium')
              .eq('email', currentUserEmail)
              .single();

      if (response == null || response['id'] == null) {
        throw Exception('User ID not found for email: $currentUserEmail');
      }

      setState(() {
        _currentUserId = response['id'].toString();
        _currentUserName = response['full_name'];
        _isPremium = response['is_premium'];
      });
      print('Curren response: $response');

      print('Current User ID: $_currentUserId');
      print('Current User Name: $_currentUserName');
      print(' _isPremium: $_isPremium');
    } catch (e) {
      print('Error fetching current user ID: $e');
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .or(
            'and(sender_id.eq.$_currentUserId,recipient_id.eq.${widget.participantId}),and(sender_id.eq.${widget.participantId},recipient_id.eq.$_currentUserId)',
          )
          .order('created_at', ascending: true);

      setState(() {
        _messages.clear();
        _messages.addAll(List<Map<String, dynamic>>.from(response));
        _isLoading = false;
      });

      print('Fetched messages: $_messages');
      _scrollToBottom(); // Scroll to the bottom after fetching messages
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _subscribeToMessages() {
    print('Subscribing to messages channel...');

    _channel =
        _supabase
            .channel('messages_channel')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'messages',
              callback: (payload) {
                print('Received payload: $payload');

                final newMessage = payload.newRecord;
                if (newMessage == null) {
                  print('No new message found in payload.');
                  return;
                }

                print('New message: $newMessage');
                print('Current user ID: $_currentUserId');
                print('Participant ID: ${widget.participantId}');

                if ((newMessage['sender_id'].toString() ==
                            widget.participantId &&
                        newMessage['recipient_id'].toString() ==
                            _currentUserId) ||
                    (newMessage['sender_id'].toString() == _currentUserId &&
                        newMessage['recipient_id'].toString() ==
                            widget.participantId)) {
                  print('New message matches current chat context.');

                  if (mounted) {
                    final isDuplicate = _messages.any(
                      (message) => message['id'] == newMessage['id'],
                    );
                    if (isDuplicate) {
                      print('Duplicate message detected. Skipping addition.');
                      return;
                    }

                    setState(() {
                      _messages.add(newMessage);
                    });
                    _scrollToBottom();
                  }
                } else {
                  print('New message does not match current chat context.');
                }
              },
            )
            .subscribe();

    print('Subscribed to messages channel.');
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _currentUserId == null) return;

    try {
      final newMessage = {
        'sender_id': _currentUserId.toString(),
        'recipient_id': widget.participantId.toString(),
        'content': messageText,
        'created_at': DateTime.now().toIso8601String(),
      };

      _scrollToBottom();

      // Insert message into the database
      await _supabase.from('messages').insert(newMessage);

      // Clear the message input after sending
      _messageController.clear();

      final deviceTokenResponse =
          await _supabase
              .from('device_tokens')
              .select('token')
              .eq('user_id', widget.participantId)
              .order('created_at', ascending: false)
              .limit(1)
              .single();

      final deviceToken = deviceTokenResponse['token'];

      if (deviceToken != null) {
        await MyFireBaseCloudMessaging.sendNotificationToUser(
          deviceToken.toString(),
          widget.participantId,
          context,
          'New Message from ${_currentUserName}',
          messageText,
          'message_notification_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<Map<String, dynamic>?> _fetchParticipantDetails() async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('is_premium, phone')
              .eq('id', widget.participantId)
              .single();

      if (response == null) {
        throw Exception('Participant details not found');
      }

      return response;
    } catch (e) {
      print('Error fetching participant details: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F39),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5CFF),
        actions: [
          if (_isPremium == true)
            FutureBuilder<Map<String, dynamic>?>(
              future: _fetchParticipantDetails(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final phoneNumber = snapshot.data!['phone'];
                  return IconButton(
                    icon: const Icon(Icons.call, color: Colors.white),
                    onPressed: () async {
                      final uri = Uri.parse('tel:$phoneNumber');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch phone dialer'),
                          ),
                        );
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],

        title: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchParticipantDetails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Loading...',
                style: TextStyle(color: Colors.white),
              );
            } else if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return Text(
                'Chat with ${widget.participantName}',
                style: const TextStyle(color: Colors.white),
              );
            } else {
              final phoneNumber = snapshot.data!['phone'] ?? 'N/A';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat with ${widget.participantName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_isPremium == true)
                    Text(
                      phoneNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                ],
              );
            }
          },
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : _messages.isEmpty
                    ? const Center(
                      child: Text(
                        'No messages yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final senderId = message['sender_id'].toString();
                        final content = message['content'];
                        final createdAt = DateTime.parse(message['created_at']);
                        final isMe = senderId == _currentUserId;

                        return ChatMessageCard(
                          message: content,
                          senderName:
                              isMe ? _currentUserName! : widget.participantName,
                          isMe: isMe,
                          timestamp: createdAt,
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Type a message...',
                      prefixIcon: const Icon(Icons.message, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D5CFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessageCard extends StatelessWidget {
  final String message;
  final String senderName;
  final bool isMe;
  final DateTime timestamp;

  const ChatMessageCard({
    super.key,
    required this.message,
    required this.senderName,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF3D5CFF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : const Color(0xFF3D5CFF),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
