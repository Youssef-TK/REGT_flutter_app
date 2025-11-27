
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferredWelcomeScreen extends StatefulWidget {
  final String referrerCode;
  final String referrerEmail;

  const ReferredWelcomeScreen({
    super.key,
    required this.referrerCode,
    required this.referrerEmail,
  });

  @override
  State<ReferredWelcomeScreen> createState() => _ReferredWelcomeScreenState();
}

class _ReferredWelcomeScreenState extends State<ReferredWelcomeScreen> {
  String _referralLink = '';
  final TextEditingController _referralCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateReferralLink();

    // Edge-to-edge + transparent system navigation bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  void _generateReferralLink() {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final referralCode = 'REGT${userId.toUpperCase()}';
    // _referralLink = 'https://regtai.com/join?ref=$referralCode';
    _referralLink = referralCode;
  }

  Future<void> _submitReferralCode() async {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty || !code.startsWith('REGT')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid referral code')));
      return;
    }

    final referrerId = code.substring(4).toLowerCase();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('referrals').insert({
        'referrer_id': referrerId,
        'referred_id': userId,
        'active_status': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral code added successfully!')),
      );
      _referralCodeController.clear();
      _continueToApp();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _continueToApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('referred_welcome_seen', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // background goes behind navigation bar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Referral Gift',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false, // AppBar already handles top
        bottom: true, // ensures content isn't hidden behind navigation bar
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            24,
          ), // extra bottom padding for safety
          child: Column(
            children: [
              // Header - "You're Invited!" card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff1a1a1a), Color(0xff2a2a2a)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xffFFD700).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 80,
                      color: Color(0xffFFD700),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Earn With Friends!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // const SizedBox(height: 12),
                    // const Text("Add An Invite Code", style: TextStyle(fontSize: 18, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      "Add An Invite Code",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffFFD700),
                      ),
                    ),
                    // Text(
                    //   "Code: ${widget.referrerCode}",
                    //   style: const TextStyle(fontSize: 18, color: Colors.white70),
                    // ),
                    const SizedBox(height: 16),
                    const Text(
                      "You both get bonus coins when you start earning!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white60),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Your Referral Code card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff1a1a1a), Color(0xff2a2a2a)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xffFFD700).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.share, color: Color(0xffFFD700), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Your Referral Code',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xff0a0a0a),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _referralLink,
                        style: const TextStyle(
                          color: Color(0xffFFD700),
                          fontFamily: 'Courier',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: _referralLink),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffFFD700),
                            ),
                            child: const Text(
                              'Copy',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Share.share(_referralLink),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffFFD700),
                            ),
                            child: const Text(
                              'Share',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Optional extra referral code input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff1a1a1a), Color(0xff2a2a2a)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xffFFD700).withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add, color: Color(0xffFFD700), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Referral Code (Optional)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _referralCodeController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Enter code (e.g. REGTXXXX)',
                        hintStyle: const TextStyle(color: Colors.grey),
                        fillColor: const Color(0xff0a0a0a),
                        filled: true,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitReferralCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFFD700),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Submit Code',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Continue button - now safely above navigation bar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continueToApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFFD700),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to App →',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              // Extra bottom padding so scroll doesn't stop too early
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
