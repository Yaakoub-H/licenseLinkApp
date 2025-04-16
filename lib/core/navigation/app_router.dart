import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:license_link/core/navigation/session_redirector.dart';
import 'package:license_link/features/auth/presentation/signup_screen.dart';
import 'package:license_link/features/search/presentation/home_screen.dart';
import 'package:license_link/features/search/presentation/search_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/admin/presentation/admin_dashboard.dart';
import '../../features/auth/presentation/admin_login_signup.dart';
import '../../features/auth/presentation/login_screen.dart';

final sessionRedirector = SessionRedirector();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: sessionRedirector,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final location = state.uri.toString();

    // If no session and not on auth page, go to login
    if (session == null && location != '/' && location != '/signup') {
      return '/';
    }

    // If session exists and we have a decision, redirect
    if (session != null && sessionRedirector.redirect != null) {
      final target = sessionRedirector.redirect!;
      sessionRedirector.clearRedirect(); // Clear after using
      return target;
    }

    // No redirect necessary
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        sessionRedirector.evaluateRedirect(); // Check user role
        return const LoginScreen();
      },
    ),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
  ],
);
