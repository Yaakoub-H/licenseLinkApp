import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:license_link/features/premium/presentation/payment_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoadingUser = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        throw Exception('No user is logged in');
      }

      final response =
          await _supabase
              .from('users')
              .select('id, full_name, email, is_premium')
              .eq('email', currentUser.email!)
              .single();

      if (response == null) {
        throw Exception('User data not found');
      }

      setState(() {
        _userData = response as Map<String, dynamic>;
        _isLoadingUser = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _enablePremium(BuildContext context, String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'is_premium': true})
          .eq('id', userId);

      setState(() {
        _userData?['is_premium'] = true;
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

  Future<void> _updateFullName(
    BuildContext context,
    String userId,
    String currentFullName,
  ) async {
    final TextEditingController fullNameController = TextEditingController(
      text: currentFullName,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Full Name'),
          content: TextField(
            controller: fullNameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newFullName = fullNameController.text.trim();
                if (newFullName.isNotEmpty && newFullName != currentFullName) {
                  await _supabase
                      .from('users')
                      .update({'full_name': newFullName})
                      .eq('id', userId);

                  setState(() {
                    _userData?['full_name'] = newFullName;
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Full name updated successfully'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _supabase.auth.signOut();

      if (context.mounted) {
        context.go('/'); // Correct way with GoRouter
      }
    } catch (e) {
      print('Error logging out: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F39),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5CFF),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoadingUser
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : _userData == null
              ? const Center(
                child: Text(
                  'No user data found',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF3D5CFF),
                      child: Text(
                        _userData!['full_name']
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join(),
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoCard(
                      icon: Icons.person,
                      title: 'Full Name',
                      value: _userData!['full_name'],
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF3D5CFF)),
                        onPressed:
                            () => _updateFullName(
                              context,
                              _userData!['id'].toString(),
                              _userData!['full_name'],
                            ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.email,
                      title: 'Email',
                      value: _userData!['email'],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.perm_identity,
                      title: 'User ID',
                      value: _userData!['id'].toString(),
                    ),
                    const SizedBox(height: 20),
                    if (!(_userData!['is_premium'] ?? false))
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => PaymentScreen(
                                    userId: _userData!['id'].toString(),
                                  ),
                            ),
                          );
                          if (result == true) {
                            setState(() {
                              _userData?['is_premium'] = true;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                        ),
                        label: const Text('Become Premium'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D5CFF),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (_userData!['is_premium'] ?? false)
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 10.0, bottom: 4),
                            child: Text(
                              'You are a premium user!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => PaymentScreen(
                                          userId: _userData!['id'].toString(),
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.manage_accounts,
                                color: Colors.white,
                              ),
                              label: const Text('Manage Premium'),
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

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light card background
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF3D5CFF).withOpacity(0.15),
          child: Icon(icon, color: const Color(0xFF3D5CFF)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        trailing: trailing,
      ),
    );
  }
}
