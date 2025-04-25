import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:license_link/features/auth/presentation/login_screen.dart';
import 'package:license_link/features/auth/presentation/welcome_screen.dart';
import 'package:license_link/features/auth/provider/auth_provider.dart';
import 'package:license_link/features/admin/presentation/admin_dashboard.dart';
import 'package:license_link/features/search/presentation/home_screen.dart';
import 'package:license_link/features/search/provider/search_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://butdwieaxeiilizxbapr.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1dGR3aWVheGVpaWxpenhiYXByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM1MDQwMTgsImV4cCI6MjA1OTA4MDAxOH0.Abvi8CdAxt5yWRJnPXI83wMdE7-g0-Q31SQ9aR8WH0o',
  );
  Stripe.publishableKey =
      'pk_test_51RFHWPCDM8fzj1LXYCBb7mOOZUNeSmhbbaAoond1dEBBZG1W18TP5DEzHuUykrT1Cju1xlrnxCzKsWv55KOtuxSq00zpDSqs2h';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Widget>? _initialScreen;

  @override
  void initState() {
    super.initState();
    _initialScreen = _checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
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
          home: FutureBuilder(
            future: _initialScreen,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const LoginScreen();
              } else {
                return snapshot.data as Widget;
              }
            },
          ),
        );
      },
    );
  }

  Future<Widget> _checkSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      final email = session.user?.email;
      if (email != null) {
        final isAdmin = await authProvider.isEmailInAdminsTable(email);
        if (isAdmin) {
          return const AdminDashboardScreen();
        } else {
          return const HomeScreen();
        }
      }
    }
    return const WelcomePageOne();
  }
}
