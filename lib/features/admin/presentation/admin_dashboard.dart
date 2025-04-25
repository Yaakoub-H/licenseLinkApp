import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:license_link/features/admin/presentation/all_users_screen.dart';
import 'package:license_link/features/auth/presentation/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<dynamic> _pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  Future<void> _fetchPendingUsers() async {
    try {
      final response = await _supabase.from('pending_users').select();
      if (response != null) {
        setState(() {
          _pendingUsers = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching pending users: $e')),
      );
    }
  }

  Future<void> _approveUser(int userId) async {
    try {
      final currentUserEmail = _supabase.auth.currentUser?.email;
      if (currentUserEmail == null) throw Exception('No authenticated user.');

      final user = _pendingUsers.firstWhere((u) => u['id'] == userId);

      final String email = user['email'];
      final String password = user['password'] ?? 'defaultpass123'; // fallback
      final String fullName = user['full_name'] ?? '';
      final String phone = user['phone'] ?? '';
      final String plate = user['plate_number'] ?? '';
      final String? cardUrl = user['vehicle_registration_card_url'];

      // Step 1: Create Supabase Auth user
      // final authResponse = await _supabase.auth.signUp(
      //   email: email,
      //   password: password,
      // );

      // if (authResponse.user == null) {
      //   throw Exception('Failed to add user to authentication.');
      // }

      await _supabase.from('users').insert({
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'plate_number': plate,
        'vehicle_registration_card_url': cardUrl,
        'password': password, // optional if you want to store it
      });

      // Step 3: Delete from pending_users
      await _supabase.from('pending_users').delete().eq('id', userId);

      setState(() {
        _pendingUsers.removeWhere((u) => u['id'] == userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving user: $e')));
    }
  }

  Future<void> _rejectUser(int userId) async {
    try {
      final currentUserEmail = _supabase.auth.currentUser?.email;

      final adminCheck =
          await _supabase
              .from('admins')
              .select()
              .eq('email', currentUserEmail!)
              .single();

      if (adminCheck == null) {
        throw Exception('You are not authorized to reject users.');
      }

      await _supabase.from('pending_users').delete().eq('id', userId);

      setState(() {
        _pendingUsers.removeWhere((u) => u['id'] == userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User rejected successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting user: $e')));
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C54),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5CFF),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F39),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5CFF),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'View All Users',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllUsersScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : _pendingUsers.isEmpty
              ? Center(
                child: Text(
                  'No pending users.',
                  style: TextStyle(fontSize: 18.sp, color: Colors.white70),
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                itemCount: _pendingUsers.length,
                itemBuilder: (context, index) {
                  final user = _pendingUsers[index];
                  return Card(
                    color: const Color(0xFF2C2C54),
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.5.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['full_name'] ?? 'No Name',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            '📧 ${user['email']}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '📞 ${user['phone']}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            '🚗 ${user['plate_number']}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _approveUser(user['id']),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              SizedBox(width: 3.w),
                              ElevatedButton.icon(
                                onPressed: () => _rejectUser(user['id']),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
