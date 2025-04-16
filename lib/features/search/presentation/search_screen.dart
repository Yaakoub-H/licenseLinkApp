import 'package:flutter/material.dart';
import 'package:license_link/features/search/data/search_service.dart';
import 'package:license_link/features/search/presentation/premimum_search_log_screen.dart';
import 'package:license_link/firebase_notiifcation.dart';
import 'package:provider/provider.dart';
import 'package:license_link/features/search/provider/search_provider.dart';
import 'package:license_link/features/chat/presentation/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _fullName;
  bool _isLoadingUser = true;
  String? _currentUserId; // Store the user's ID from the database

  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _fetchLoggedUser();
  }

  Future<void> _fetchLoggedUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user is logged in');
      }

      final response =
          await _supabase
              .from('users')
              .select('id,full_name, is_premium')
              .eq('email', user.email!)
              .single();

      if (response == null || response['full_name'] == null) {
        throw Exception('User data not found');
      }

      setState(() {
        _fullName = response['full_name'];
        _currentUserId = response['id'].toString();
        _isPremium = response['is_premium'] ?? false;
        _isLoadingUser = false;
      });
    } catch (e) {
      print('Error fetching logged user: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _enablePremium() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user is logged in');
      }

      await _supabase
          .from('users')
          .update({'is_premium': true})
          .eq('email', user.email!);

      setState(() {
        _isPremium = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now a premium user!')),
      );
    } catch (e) {
      print('Error enabling premium: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error enabling premium: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = Provider.of<SearchProvider>(context);
    final TextEditingController plateNumberController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F39),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5CFF),
        title:
            _isLoadingUser
                ? const Text(
                  'Loading...',
                  style: TextStyle(color: Colors.white),
                )
                : Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Welcome, ${_fullName ?? 'User'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoadingUser
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Plate Number',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: plateNumberController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'e.g., ABC-1234',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.directions_car_filled,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final plate = plateNumberController.text.trim();
                              if (plate.isNotEmpty) {
                                searchProvider.searchByPlateNumber(plate);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a plate number.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.search),
                            label: const Text('Search'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3D5CFF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (searchProvider.searchResult != null)
                          const SizedBox(width: 12),
                        if (searchProvider.searchResult != null)
                          ElevatedButton.icon(
                            onPressed: () {
                              searchProvider.clearSearch();
                              plateNumberController.clear();
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (searchProvider.isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    if (!searchProvider.isLoading &&
                        searchProvider.searchResult != null) ...[
                      _buildSearchResult(context, searchProvider.searchResult!),
                      const SizedBox(height: 30),
                    ],

                    if (_isPremium)
                      Column(
                        children: [
                          const Center(
                            child: Text(
                              'You are a premium user!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PremiumSearchLogsScreen(
                                          premiumUserId:
                                              _currentUserId.toString()!,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.history),
                              label: const Text('View Search Logs'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3D5CFF),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
    );
  }

  Future<void> _logSearchForPremiumUser(
    String premiumUserId,
    String premiumUserDeviceToken,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user is logged in');
      }

      print('Device Token: $premiumUserDeviceToken');

      // Log the search in the database
      await _supabase.from('premium_user_search_logs').insert({
        'searcher_id': _currentUserId,
        'premium_user_id': premiumUserId,
        'searched_at': DateTime.now().toIso8601String(),
      });

      print('Search logged successfully for premium user: $premiumUserId');

      // Validate the token before sending the notification
      if (premiumUserDeviceToken.isEmpty) {
        throw Exception('Invalid device token: $premiumUserDeviceToken');
      }

      final responseU =
          await _supabase
              .from('users')
              .select('id,full_name')
              .eq('id', premiumUserId)
              .single();

      // Send a notification to the premium user
      await MyFireBaseCloudMessaging.sendNotificationToUser(
        premiumUserDeviceToken, // Device token of the premium user
        premiumUserId.toString(), // UID of the premium user
        context,
        'Profile Viewed',
        '${responseU['full_name']} has searched for your car plate!',
        'search_notification_${DateTime.now().millisecondsSinceEpoch}', // Unique notification ID
      );
    } catch (e) {
      print('Error logging search or sending notification: $e');
    }
  }

  Widget _buildSearchResult(BuildContext context, Map<String, dynamic> result) {
    if (result.containsKey('error')) {
      return Center(
        child: Text(
          result['error'],
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    final searchData = SearchData.fromJson(result);

    if (result['is_premium'] ?? false) {
      _supabase
          .from('device_tokens')
          .select('token')
          .eq('user_id', result['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .single()
          .then(
            (response) =>
                _logSearchForPremiumUser(result['id'], response['token']),
          )
          .catchError((error) => print('Error fetching device token: $error'));
    }

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatScreen(
                    participantName: searchData.fullName,
                    participantId: result['id'].toString(),
                  ),
            ),
          ),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Color.fromARGB(255, 39, 135, 176)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  searchData.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isPremium)
                  Text(
                    'Phone: ${result['phone']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellowAccent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
