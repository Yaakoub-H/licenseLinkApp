import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class PendingUserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const PendingUserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F39),
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: const Color(0xFF3D5CFF),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user['full_name'] ?? 'No Name',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                '📧 Email: ${user['email']}',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              Text(
                '📞 Phone: ${user['phone']}',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              Text(
                '🚗 Plate Number: ${user['plate_number']}',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              Text(
                '📎 Vehicle Registration:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              if (user['vehicle_registration_card_url'] != null)
                SizedBox(
                  height: 30.h,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        user['vehicle_registration_card_url'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ??
                                              1)
                                      : null,
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stackTrace) => const Text(
                              'Error loading image',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                      ),
                    ),
                  ),
                )
              else
                const Text(
                  'No vehicle registration uploaded',
                  style: TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
