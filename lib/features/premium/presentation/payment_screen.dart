import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  final String userId;

  const PaymentScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isPremium = false;
  bool _isLoading = true;
  String? _stripeCustomerId;
  int _cashBalance = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response =
          await _supabase
              .from('users')
              .select('is_premium, stripe_customer_id')
              .eq('id', widget.userId)
              .maybeSingle();

      if (response != null) {
        setState(() {
          _isPremium = response['is_premium'] ?? false;
          _stripeCustomerId = response['stripe_customer_id'];
        });

        if (_stripeCustomerId != null) {
          await _fetchCashBalance(_stripeCustomerId!);
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCashBalance(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.stripe.com/v1/customers/$customerId/cash_balance',
        ),
        headers: {
          'Authorization':
              'Bearer sk_test_51RFHWPCDM8fzj1LXAmda8CwdBE0rSMrJQAiCS71u7vhBXoroiDabwTVyGHUFDeJ78K1UWw7N3avPzCxVxxn8Plyu004cMlQmu2',
        },
      );

      final data = jsonDecode(response.body);
      setState(() {
        _cashBalance = data['available']['usd'] ?? 0;
      });
    } catch (e) {
      print('Error fetching Stripe cash balance: $e');
    }
  }

  Future<void> _createStripeCustomer() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization':
              'Bearer sk_test_51RFHWPCDM8fzj1LXAmda8CwdBE0rSMrJQAiCS71u7vhBXoroiDabwTVyGHUFDeJ78K1UWw7N3avPzCxVxxn8Plyu004cMlQmu2',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'email': user.email},
      );

      final data = jsonDecode(response.body);
      if (data['error'] != null) throw Exception(data['error']['message']);

      final newCustomerId = data['id'];

      await _supabase
          .from('users')
          .update({'stripe_customer_id': newCustomerId})
          .eq('id', widget.userId);

      setState(() {
        _stripeCustomerId = newCustomerId;
      });

      await _fetchCashBalance(newCustomerId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stripe customer created successfully.')),
      );
    } catch (e) {
      print('Error creating Stripe customer: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating customer: $e')));
    }
  }

  Future<void> _submitPayment() async {
    const int premiumCostCents = 12000; // $120 = 12000 cents

    try {
      if (_stripeCustomerId == null) {
        throw Exception('Stripe customer ID not found.');
      }

      // Call Supabase Edge Function to charge the customer
      final response = await http.post(
        Uri.parse(
          'https://butdwieaxeiilizxbapr.supabase.co/functions/v1/create-payment-intent',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customerId': _stripeCustomerId,
          'amount': premiumCostCents, // amount in cents
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          data['error'] ?? 'Unknown error from payment function.',
        );
      }

      // If payment is successful, update premium status
      await _supabase
          .from('users')
          .update({'is_premium': true})
          .eq('id', widget.userId);

      setState(() {
        _isPremium = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are now a premium user!')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      print('Error upgrading to premium: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error upgrading to premium: $e')));
    }
  }

  Future<void> _cancelSubscription() async {
    try {
      await _supabase
          .from('users')
          .update({'is_premium': false})
          .eq('id', widget.userId);

      setState(() => _isPremium = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subscription cancelled.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling subscription: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D5CFF),
        title: const Text(
          'Manage Subscription',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F39),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPremium
                            ? '🎉 You are a premium user!'
                            : '👤 You are not a premium user.',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_stripeCustomerId == null) ...[
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _createStripeCustomer,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Create Stripe Customer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrangeAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_stripeCustomerId != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A4D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.greenAccent,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Wallet Balance:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\$${(_cashBalance / 100).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      if (!_isPremium)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _submitPayment,
                            icon: const Icon(Icons.star),
                            label: const Text('Upgrade to Premium'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3D5CFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      if (_isPremium)
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _cancelSubscription,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel Subscription'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}
