import 'dart:io';
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:license_link/features/auth/presentation/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart'; // For file picking
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase integration
import '../provider/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _vehicleRegistrationCardPath; // Path to the uploaded file
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _plateNumberController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickVehicleRegistrationCard() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'], // Allow images and PDFs
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _vehicleRegistrationCardPath = result.files.single.path;
      });
    }
  }

  Future<String?> _uploadVehicleRegistrationCard(String email) async {
    if (_vehicleRegistrationCardPath == null) return null;

    try {
      final file = File(_vehicleRegistrationCardPath!);
      final fileName =
          'vehicle_registration_${email}_${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';

      // Upload the file to the Supabase storage bucket
      await Supabase.instance.client.storage
          .from('vehicle-registration-cards') // Bucket name
          .upload(fileName, file);

      // Get the public URL of the uploaded file
      final publicUrl = Supabase.instance.client.storage
          .from('vehicle-registration-cards')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
      return null;
    }
  }

  Future<void> _addToPendingUsers(
    String email,
    String phone,
    String fullName,
    String plateNumber,
    String fileUrl,
    String password, // Add password parameter
  ) async {
    try {
      final response =
          await Supabase.instance.client.from('pending_users').insert({
            'email': email,
            'phone': phone,
            'full_name': fullName,
            'plate_number': plateNumber,
            'vehicle_registration_card_url': fileUrl,
            'password': password, // Store the password
          }).select();

      // Log the response for debugging
      print('Insert Response: $response');

      if (response == null || response.isEmpty) {
        throw Exception('Failed to add user to pending list.');
      }
    } catch (e) {
      print('Error adding to pending users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to pending users: $e')),
      );
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _plateNumberController.text.isEmpty ||
        _vehicleRegistrationCardPath == null ||
        _passwordController.text != _confirmPasswordController.text ||
        !_phoneController.text.startsWith('+961')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all fields, ensure passwords match, and phone number starts with +961.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload the vehicle registration card
      final publicUrl = await _uploadVehicleRegistrationCard(
        _emailController.text,
      );

      if (publicUrl == null) {
        throw Exception('Failed to upload vehicle registration card.');
      }

      final hashedPassword = BCrypt.hashpw(
        _passwordController.text,
        BCrypt.gensalt(),
      );

      await _addToPendingUsers(
        _emailController.text,
        _phoneController.text,
        _fullNameController.text,
        _plateNumberController.text,
        publicUrl,
        hashedPassword, // Store this hashed password
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account is pending admin approval.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              // App Logo
              CircleAvatar(
                radius: 8.h,
                backgroundColor: const Color(0xFF3D5CFF),
                child: Icon(Icons.car_rental, size: 8.h, color: Colors.white),
              ),
              SizedBox(height: 4.h),

              // Welcome Text
              Text(
                'Create an Account',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Sign up to get started',
                style: TextStyle(fontSize: 16.sp, color: Colors.white70),
              ),
              SizedBox(height: 4.h),

              // Full Name Input Field
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person, color: Colors.white),
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.blueAccent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter your full name',
                ),
              ),
              SizedBox(height: 2.h),

              // Email Input Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: Colors.white),
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.blueAccent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter your email',
                ),
              ),
              SizedBox(height: 2.h),

              // Phone Number Input Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone, color: Colors.white),
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.blueAccent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: '+961XXXXXXXXX',
                ),
              ),
              SizedBox(height: 2.h),

              // Plate Number Input Field
              TextField(
                controller: _plateNumberController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.directions_car, color: Colors.white),
                  labelText: 'Plate Number',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.blueAccent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter your plate number',
                ),
              ),
              SizedBox(height: 2.h),

              // Password Input Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.white),
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.blueAccent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Enter your password',
                ),
              ),
              SizedBox(height: 2.h),

              // Confirm Password Input Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: Colors.white),
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.blueAccent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'Confirm your password',
                ),
              ),
              SizedBox(height: 2.h),

              // Vehicle Registration Card Upload
              GestureDetector(
                onTap: _pickVehicleRegistrationCard,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, color: Colors.white),
                      SizedBox(width: 2.w),
                      Text(
                        _vehicleRegistrationCardPath == null
                            ? 'Upload Vehicle Registration Card'
                            : 'File Selected',
                        style: TextStyle(fontSize: 16.sp, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              if (_vehicleRegistrationCardPath != null)
                Padding(
                  padding: EdgeInsets.only(top: 1.h),
                  child: Text(
                    'File: ${_vehicleRegistrationCardPath!.split('/').last}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 4.h),

              // Sign Up Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _signUp,
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
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              SizedBox(height: 2.h),

              // Admin Review Note
              Text(
                'Your account will be reviewed by an admin before activation.',
                style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),

              // Login Redirect
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(
                  'Already have an account? Login',
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
