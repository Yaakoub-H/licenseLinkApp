import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SessionRedirector extends ChangeNotifier {
  String? _redirect;

  String? get redirect => _redirect;

  Future<void> evaluateRedirect() async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      _redirect = '/';
      notifyListeners();
      return;
    }

    final email = client.auth.currentUser?.email;

    if (email == null) {
      _redirect = '/';
      notifyListeners();
      return;
    }

    try {
      final admin =
          await client
              .from('admins')
              .select('id')
              .eq('email', email)
              .maybeSingle();

      _redirect = admin != null ? '/admin' : '/home';
    } catch (_) {
      _redirect = '/home'; // fallback
    }

    notifyListeners();
  }

  void clearRedirect() {
    _redirect = null;
    notifyListeners();
  }
}
