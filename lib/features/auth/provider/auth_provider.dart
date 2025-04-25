import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isAuthenticated = false;
  bool _isAdmin = false;
  String? _userId;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  String? get userId => _userId;

  Future<bool> isEmailInAdminsTable(String email) async {
    final response =
        await _supabase
            .from('admins')
            .select('id')
            .eq('email', email)
            .maybeSingle();
    return response != null;
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
        await FirebaseFunctions.instance
            .httpsCallable('sendPushNotification')
            .call({'token': token, 'title': title, 'body': body});
      }
    } catch (e) {
      print('Error sending push notification: $e');
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
      final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
      String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        await _supabase.from('device_tokens').upsert({
          'user_id': userId,
          'token': token,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  Future<void> loginAdmin(String email, String password) async {
    try {
      final adminCheck =
          await _supabase
              .from('admins')
              .select()
              .eq('email', email)
              .maybeSingle();
      if (adminCheck == null)
        throw Exception('You are not authorized to log in as admin.');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session == null)
        throw Exception('Login failed: Invalid credentials.');

      _isAuthenticated = true;
      _isAdmin = true;
      _userId = response.user?.id;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() => notifyListeners());
      });
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

      if (userRecord == null) throw Exception('Invalid email or password.');

      final int userId = userRecord['id'];
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
      if (loginResponse.session == null)
        throw Exception('Authentication failed.');

      _isAuthenticated = true;
      _isAdmin = false;
      _userId = userId.toString();

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await saveDeviceToken(userId);
        notifyListeners();
      });

      return "user";
    } catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _isAdmin = false;
    _userId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> signupAdmin(String email, String password) async {
    try {
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (authResponse.user == null)
        throw Exception('Failed to create admin in authentication.');

      await _supabase.from('admins').insert({
        'email': email,
        'full_name': 'Admin User',
      });

      final userResponse =
          await _supabase
              .from('users')
              .select('id')
              .eq('email', email)
              .single();
      if (userResponse != null && userResponse['id'] != null) {
        _userId = userResponse['id'];
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await saveDeviceToken(_userId! as int);
        });
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
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (authResponse.user == null)
        throw Exception('Failed to create user in authentication.');

      await _supabase.from('users').insert({
        'email': email,
        'full_name': fullName,
      });

      final userResponse =
          await _supabase
              .from('users')
              .select('id')
              .eq('email', email)
              .single();
      if (userResponse != null && userResponse['id'] != null) {
        _userId = userResponse['id'];
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await saveDeviceToken(_userId! as int);
        });
      } else {
        throw Exception('User UUID not found in users table.');
      }
    } catch (e) {
      throw Exception('User Signup Failed: $e');
    }
  }
}
