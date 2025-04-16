import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:license_link/features/search/provider/search_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'core/navigation/app_router.dart';
import 'features/auth/provider/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://butdwieaxeiilizxbapr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1dGR3aWVheGVpaWxpenhiYXByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM1MDQwMTgsImV4cCI6MjA1OTA4MDAxOH0.Abvi8CdAxt5yWRJnPXI83wMdE7-g0-Q31SQ9aR8WH0o',
  );
  // Periodically check for expired calls
  // Timer.periodic(const Duration(seconds: 30), (timer) {
  //   final authProvider = AuthProvider();
  //   authProvider.checkForExpiredInvites();
  // });
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          title: 'LicenseLink',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1F1F39),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          routerConfig: appRouter,
        );
      },
    );
  }
}
