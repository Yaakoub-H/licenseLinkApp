import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:license_link/features/admin/presentation/admin_dashboard.dart';
import 'package:license_link/features/auth/presentation/signup_screen.dart';
import 'package:license_link/features/search/presentation/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../provider/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final client = Supabase.instance.client;

      // ✅ 1. Check if user is an admin
      final admin =
          await client
              .from('admins')
              .select('id')
              .eq('email', email)
              .maybeSingle();

      if (admin != null) {
        final response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.session == null) {
          throw Exception('Invalid admin credentials.');
        }

        // ✅ Save device token for admin
        // final adminId = admin['id'];
        // await Provider.of<AuthProvider>(context, listen: false)
        //     .saveDeviceToken(adminId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        return;
      }

      // ✅ 2. Check if user exists
      final user =
          await client
              .from('users')
              .select('id, password')
              .eq('email', email)
              .maybeSingle();

      if (user != null) {
        final storedHashed = user['password'];
        final isValid = BCrypt.checkpw(password, storedHashed);

        if (!isValid) {
          throw Exception('Incorrect password.');
        }

        try {
          await client.auth.signUp(email: email, password: password);
        } catch (e) {
          if (!e.toString().contains("User already registered")) {
            rethrow;
          }
        }

        // ✅ Now login via Supabase Auth
        final response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.session == null) {
          throw Exception('Authentication failed.');
        }

        final userId = user['id'];
        await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).saveDeviceToken(userId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }

      throw Exception('No account found for this email.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F39),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 8.h,
                backgroundColor: const Color(0xFF3D5CFF),
                child: Icon(Icons.car_rental, size: 8.h, color: Colors.white),
              ),
              SizedBox(height: 4.h),
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Login to continue',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[400]),
              ),
              SizedBox(height: 4.h),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.grey),
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.grey),
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5CFF),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: TextStyle(fontSize: 18.sp),
                    ),
                    child: const Text('Login'),
                  ),
              SizedBox(height: 2.h),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
                child: Text(
                  'Don’t have an account? Sign Up',
                  style: TextStyle(fontSize: 16.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
