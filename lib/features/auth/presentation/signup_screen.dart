import 'dart:io';

import 'package:flutter/material.dart';
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
  String? _vehicleRegistrationCardPath; // Path to the uploaded file
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _plateNumberController.dispose();
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
        _vehicleRegistrationCardPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all fields and upload the vehicle registration card.',
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

      // Add the user's details to the pending_users table
      await _addToPendingUsers(
        _emailController.text,
        _phoneController.text,
        _fullNameController.text,
        _plateNumberController.text,
        publicUrl,
        _passwordController.text, // Pass the password
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account is pending admin approval.'),
        ),
      );

      context.go('/'); // Navigate to the login screen
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
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[400]),
              ),
              SizedBox(height: 4.h),

              // Full Name Input Field
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.person, color: Colors.grey),
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              // Email Input Field
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

              // Phone Number Input Field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.phone, color: Colors.grey),
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              // Plate Number Input Field
              TextField(
                controller: _plateNumberController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.directions_car, color: Colors.grey),
                  labelText: 'Plate Number',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              // Password Input Field
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
              SizedBox(height: 2.h),

              // Vehicle Registration Card Upload
              GestureDetector(
                onTap: _pickVehicleRegistrationCard,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D5CFF),
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
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
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
                    child: const Text('Sign Up'),
                  ),
              SizedBox(height: 2.h),

              // Admin Review Note
              Text(
                'Your account will be reviewed by an admin before activation.',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),

              // Login Redirect
              TextButton(
                onPressed: () {
                  context.go('/'); // Navigate to the login screen
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
