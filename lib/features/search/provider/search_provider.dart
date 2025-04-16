import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  Map<String, dynamic>? _searchResult;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get searchResult => _searchResult;

  void clearSearch() {
    _searchResult = null;
    notifyListeners();
  }

  Future<void> searchByPlateNumber(String plateNumber) async {
    _isLoading = true;
    _searchResult = null;
    notifyListeners();

    try {
      final response =
          await _supabase
              .from('users')
              .select()
              .eq('plate_number', plateNumber)
              .maybeSingle();

      if (response != null) {
        _searchResult = response;
      } else {
        _searchResult = {'error': 'No user found with this plate number.'};
      }
    } catch (e) {
      _searchResult = {'error': 'Error searching for user: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
