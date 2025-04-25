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
  String? _userPlateNumber; // To store the logged-in user's plate number
  int _searchCountToday = 0;

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
              .select('id,full_name, plate_number, is_premium')
              .eq('email', user.email!)
              .single();

      if (response == null || response['full_name'] == null) {
        throw Exception('User data not found');
      }

      setState(() {
        _fullName = response['full_name'];
        _currentUserId = response['id'].toString();
        _userPlateNumber = response['plate_number'];
        print('User Plate Number: $_userPlateNumber');

        _isPremium = response['is_premium'] ?? false;
        _isLoadingUser = false;
      });
      if (!_isPremium) {
        // If non-premium user, check today's search limit
        await _checkNonPremiumSearchLimit();
      }
    } catch (e) {
      print('Error fetching logged user: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _checkNonPremiumSearchLimit() async {
    try {
      final response =
          await _supabase
              .from('non_premium_search_logs')
              .select('count')
              .eq('user_id', _currentUserId!)
              .gte(
                'search_date',
                DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
              )
              .single();

      setState(() {
        _searchCountToday = response['count'] ?? 0;
      });
    } catch (e) {
      print('Error checking search limit: $e');
    }
  }

  Future<void> _logNonPremiumSearch() async {
    try {
      await _supabase.from('non_premium_search_logs').insert({
        'user_id': _currentUserId,
        'search_date': DateTime.now().toIso8601String(),
      });
      // After logging the search, refresh the count
      await _checkNonPremiumSearchLimit();
    } catch (e) {
      print('Error logging search for non-premium user: $e');
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
                    TextFormField(
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
                        labelText: 'Enter Plate Number',
                        labelStyle: const TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Check if the plate searched is the user's plate
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (!_isPremium && _searchCountToday >= 3) {
                                showSearchLimitDialog(context);
                                return;
                              }

                              final plate = plateNumberController.text.trim();
                              if (plate.isNotEmpty) {
                                print('User Plate Number: $_userPlateNumber');
                                print(
                                  'Entered Plate Number: ${plateNumberController.text.trim()}',
                                );
                                searchProvider.searchByPlateNumber(plate);

                                if (!_isPremium) {
                                  _logNonPremiumSearch();
                                }
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

                    const SizedBox(height: 20),
                    if (!searchProvider.isLoading &&
                        searchProvider.searchResult != null) ...[
                      // Check if there's a message indicating the plate is the user's own
                      if (searchProvider.searchResult!.containsKey(
                        'message',
                      )) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.greenAccent, Colors.green],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              searchProvider.searchResult!['message'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Normal search result
                        _buildSearchResult(
                          context,
                          searchProvider.searchResult!,
                        ),
                      ],
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

  void showSearchLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(
            0xFF2A2A2A,
          ), // Dark background for a modern look
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners
          ),
          title: Text(
            'Daily Search Limit Reached',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You have reached your daily search limit.',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.blueAccent, // Accent color for the button
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
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
      final response =
          await _supabase
              .from('users')
              .select('full_name')
              .eq('email', user.email.toString())
              .single();

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

      await MyFireBaseCloudMessaging.sendNotificationToUser(
        premiumUserDeviceToken.toString(),
        premiumUserId.toString(),
        context,
        'Profile Viewed',
        '${response['full_name']} has searched for your car plate!',
        'search_notification_${DateTime.now().millisecondsSinceEpoch}',
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
            (response) => _logSearchForPremiumUser(
              result['id'].toString(),
              response['token'].toString(),
            ),
          )
          .catchError((error) => print('Error fetching device token: $error'));
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.symmetric(vertical: 10),
        width:
            MediaQuery.of(context).size.width *
            0.9, // Make it take most of the width
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(
            0.4,
          ), // Transparent background with blue
          borderRadius: BorderRadius.circular(25), // Rounded edges
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 8, // Added more blur for a modern effect
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the row content
          children: [
            // Icon for visual appeal
            Icon(Icons.directions_car_filled, color: Colors.white, size: 40),
            const SizedBox(width: 16), // Spacing between icon and text
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center the text horizontally
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the content vertically
                children: [
                  Text(
                    searchData.fullName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (_isPremium)
                    Text(
                      'Phone: ${result['phone']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.yellowAccent,
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Button styled text
                  GestureDetector(
                    onTap: () {
                      // Navigate to chat screen or any action you want here
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatScreen(
                                participantName: searchData.fullName,
                                participantId: result['id'].toString(),
                              ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.3,
                        ), // Transparent background
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Click to Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
