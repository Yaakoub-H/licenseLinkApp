import 'package:flutter/material.dart';
import 'package:license_link/features/auth/presentation/login_screen.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class WelcomePageTwo extends StatelessWidget {
  const WelcomePageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 100.w,
        height: 100.h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(
                0xFF3D5CFF,
              ), // Adjust as needed for your app's gradient color
              Color(0xFF0F1A2E), // Darker blue for a smooth gradient effect
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo or Icon
              Icon(
                Icons.directions_car, // Use car-related icon
                size: 20.h,
                color: Colors.white,
              ),
              SizedBox(height: 4.h),

              // Title
              Text(
                'Welcome to Mar2ne - Your Car Service App!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4.h),

              // Info rows (stacked vertically, centered)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_filled,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Car Plate Lookup Made Easy',
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  ),
                ],
              ),

              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, color: Colors.white, size: 20.sp),
                  SizedBox(width: 2.w),
                  Text(
                    'Affordable Service Rates',
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.yellow, size: 20.sp),
                  SizedBox(width: 2.w),
                  Text(
                    '1000+ Satisfied Customers',
                    style: TextStyle(fontSize: 16.sp, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 6.h),

              // Get Started Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3D5CFF), // Same as app gradient
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(80.w, 6.h),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
