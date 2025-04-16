import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:stream_video/stream_video.dart' as stream_video;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isAuthenticated = false;
  bool _isAdmin = false;
  String? _userId; // Store the user's UUID

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  String? get userId => _userId;
  late final stream_video.StreamVideo _streamClient;

  Future<void> connectStreamUser(String userId, String name) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createStreamUserAndGetToken',
      );
      final result = await callable.call();
      final streamUserToken = result.data['token'];

      _streamClient = stream_video.StreamVideo(
        's8evxwarwh7p', // your Stream API key
        user: stream_video.User.regular(userId: userId, name: name),
        userToken: streamUserToken,
      );

      print('Connected to Stream Video as $userId');
    } catch (e) {
      print('Error connecting to Stream: $e');
      rethrow;
    }
  }

  Future<bool> isEmailInAdminsTable(String email) async {
    print('email = $email');
    final response =
        await Supabase.instance.client
            .from('admins')
            .select('id')
            .eq('email', email)
            .maybeSingle();

    return response != null;
  }

  Future<void> createCallInvite({
    required String callId,
    required String callerId,
    required String receiverId,
  }) async {
    try {
      await _supabase.from('call_invites').insert({
        'call_id': callId,
        'caller_id': callerId,
        'receiver_id': receiverId,
        'status': 'pending',
      });
    } catch (e) {
      print('Error creating call invite: $e');
    }
  }

  Future<void> sendPushNotification({
    required String receiverId,
    required String title,
    required String body,
  }) async {
    try {
      final response =
          await _supabase
              .from('device_tokens')
              .select('token')
              .eq('user_id', receiverId)
              .single();

      if (response != null && response['token'] != null) {
        final token = response['token'];

        // Use Firebase Cloud Messaging to send the notification
        await FirebaseFunctions.instance
            .httpsCallable('sendPushNotification')
            .call({'token': token, 'title': title, 'body': body});
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  Future<void> updateCallStatus({
    required String inviteId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('call_invites')
          .update({
            'status': status,
            if (status == 'accepted')
              'accepted_at': DateTime.now().toUtc().toIso8601String(),
            if (status == 'rejected')
              'rejected_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', inviteId);
    } catch (e) {
      print('Error updating call status: $e');
    }
  }

  Future<void> checkForExpiredInvites() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase
          .from('call_invites')
          .update({'status': 'expired'})
          .lt('expires_at', now)
          .eq('status', 'pending');
    } catch (e) {
      print('Error checking for expired invites: $e');
    }
  }

  Future<void> saveDeviceToken(int userId) async {
    try {
      // Get the FCM token
      final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        await _supabase.from('device_tokens').upsert({
          'user_id': userId,
          'token': token,
          'created_at': DateTime.now().toIso8601String(),
        });

        print('Device token saved successfully: $token');
      } else {
        print('Failed to retrieve FCM token');
      }
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  Future<void> loginAdmin(String email, String password) async {
    try {
      // Step 1: Only allow login if email exists in `admins` table
      final adminCheck =
          await _supabase
              .from('admins')
              .select()
              .eq('email', email)
              .maybeSingle();

      if (adminCheck == null) {
        throw Exception('You are not authorized to log in as admin.');
      }

      // Step 2: Perform Supabase Auth login
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception('Login failed: Invalid credentials.');
      }

      _isAuthenticated = true;
      _isAdmin = true;
      _userId = response.user?.id; // Optional: store UUID from Supabase auth

      // Step 3: Save FCM token for push notifications
      if (_userId != null) {
        await saveDeviceToken(_userId! as int);
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Admin Login Failed: $e');
    }
  }

  Future<String> loginUser(String email, String password) async {
    try {
      final userRecord =
          await _supabase
              .from('users')
              .select('id, full_name')
              .eq('email', email)
              .eq('password', password)
              .maybeSingle();

      if (userRecord == null) {
        throw Exception('Invalid email or password.');
      }

      final int userId = userRecord['id'];
      print('userId = $userId');
      final String fullName = userRecord['full_name'] ?? 'User';

      try {
        await _supabase.auth.signUp(email: email, password: password);
      } catch (e) {
        if (!e.toString().contains('User already registered')) {
          rethrow;
        }
      }

      final loginResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (loginResponse.session == null) {
        throw Exception('Authentication failed.');
      }

      _isAuthenticated = true;
      _isAdmin = false;
      _userId = userId.toString();

      await saveDeviceToken(userId);
      notifyListeners();

      return "user";
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _isAdmin = false;
    _userId = null; // Clear the stored UUID
    notifyListeners();
  }

  Future<void> signupAdmin(String email, String password) async {
    try {
      // Create the admin user in Supabase authentication
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create admin in authentication.');
      }

      // Add the admin to the `admins` table
      final response = await _supabase.from('admins').insert({
        'email': email,
        'full_name': 'Admin User',
      });

      if (response.error != null) {
        throw Exception(
          'Failed to add admin to the database: ${response.error!.message}',
        );
      }

      // Fetch and store the admin's UUID
      final userResponse =
          await _supabase
              .from('users')
              .select('id')
              .eq('email', email)
              .single();

      if (userResponse != null && userResponse['id'] != null) {
        _userId = userResponse['id']; // Store the UUID

        // Save the device token
        await saveDeviceToken(_userId! as int);
      } else {
        throw Exception('Admin UUID not found in users table.');
      }
    } catch (e) {
      throw Exception('Admin Signup Failed: $e');
    }
  }

  Future<void> signupUser(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      // Create the regular user in Supabase authentication
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user in authentication.');
      }

      // Add the user to the `users` table
      final response = await _supabase.from('users').insert({
        'email': email,
        'full_name': fullName,
      });

      if (response.error != null) {
        throw Exception(
          'Failed to add user to the database: ${response.error!.message}',
        );
      }

      // Fetch and store the user's UUID
      final userResponse =
          await _supabase
              .from('users')
              .select('id')
              .eq('email', email)
              .single();

      if (userResponse != null && userResponse['id'] != null) {
        _userId = userResponse['id']; // Store the UUID

        // Save the device token
        await saveDeviceToken(_userId! as int);
      } else {
        throw Exception('User UUID not found in users table.');
      }
    } catch (e) {
      throw Exception('User Signup Failed: $e');
    }
  }
}
