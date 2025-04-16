import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumSearchLogsScreen extends StatefulWidget {
  final String premiumUserId;

  const PremiumSearchLogsScreen({Key? key, required this.premiumUserId})
    : super(key: key);

  @override
  _PremiumSearchLogsScreenState createState() =>
      _PremiumSearchLogsScreenState();
}

class _PremiumSearchLogsScreenState extends State<PremiumSearchLogsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _searchLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSearchLogs();
  }

  Future<void> _fetchSearchLogs() async {
    try {
      final response = await _supabase
          .from('premium_user_search_logs')
          .select('searcher_id, searched_at')
          .eq('premium_user_id', widget.premiumUserId)
          .order('searched_at', ascending: false);

      final logs = List<Map<String, dynamic>>.from(response);

      for (var log in logs) {
        final userResponse =
            await _supabase
                .from('users')
                .select('full_name, phone')
                .eq('id', log['searcher_id'])
                .single();

        log['full_name'] = userResponse['full_name'];
        log['phone'] = userResponse['phone'];
      }

      setState(() {
        _searchLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching search logs: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String date) {
    final parsed = DateTime.parse(date).toLocal();
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToDetails(String fullName, String phone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                SearcherDetailsScreen(fullName: fullName, phone: phone),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F39),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5CFF),
        title: const Text('Search Logs', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : _searchLogs.isEmpty
              ? const Center(
                child: Text(
                  'No search logs found',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
              : ListView.builder(
                itemCount: _searchLogs.length,
                itemBuilder: (context, index) {
                  final log = _searchLogs[index];
                  final fullName = log['full_name'] ?? 'Unknown';
                  final phone = log['phone'] ?? 'Unknown';
                  final date = _formatDate(log['searched_at']);

                  return Card(
                    color: const Color(0xFF2A2A4D),
                    margin: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF3D5CFF),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          const Text(
                            'Searched your plate',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _navigateToDetails(fullName, phone),
                    ),
                  );
                },
              ),
    );
  }
}

class SearcherDetailsScreen extends StatelessWidget {
  final String fullName;
  final String phone;

  const SearcherDetailsScreen({
    Key? key,
    required this.fullName,
    required this.phone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F39),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5CFF),
        title: const Text(
          'Searcher Details',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Card(
          color: const Color(0xFF3D5CFF),
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
