
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';


class ReferralStats {
  int totalReferrals;
  int activeReferrals;
  double totalCommissions;
  double thisMonthCommissions;

  ReferralStats({
    required this.totalReferrals,
    required this.activeReferrals,
    required this.totalCommissions,
    required this.thisMonthCommissions,
  });
}

class ReferralsScreen extends StatefulWidget {
  const ReferralsScreen({super.key});

  @override
  State<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends State<ReferralsScreen> {
  String _referralLink = '';
  List<Map<String, dynamic>> _team = [];
  ReferralStats _stats = ReferralStats(
    totalReferrals: 0,
    activeReferrals: 0,
    totalCommissions: 0,
    thisMonthCommissions: 0,
  );
  String? _expandedMember;
  bool _hasReferrer = false;
  final TextEditingController _referralCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateReferralLink();
    _checkIfReferred();
    _loadTeam();
  }

  void _generateReferralLink() {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final referralCode = 'REGT${userId.toUpperCase()}';
    // _referralLink = 'https://regtai.com/join?ref=$referralCode';
    _referralLink = referralCode;
  }


  String _referrerCode = '';
  String _referrerEmail = '';

  

  Future<void> _checkIfReferred() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('referrals')
          .select('referrer_id, profiles!referrer_id (email)')
          .eq('referred_id', userId)
          .maybeSingle();

      setState(() {
        if (response != null) {
          _hasReferrer = true;
          _referrerCode =
              'REGT${(response['referrer_id'] as String).toUpperCase()}';
          _referrerEmail = response['profiles']['email'] ?? 'Unknown';
        } else {
          _hasReferrer = false;
        }
      });
    } catch (e) {
      debugPrint('Error checking referral: $e');
      setState(() {
        _hasReferrer = false;
      });
    }
  }

  Future<void> _loadTeam() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await Supabase.instance.client
        .from('referrals')
        .select('*, profiles!referred_id (username, country)')
        .eq('referrer_id', userId);

    double totalComm = 0;
    double monthComm = 0;
    int active = 0;
    DateTime now = DateTime.now();

    for (var m in data) {
      bool isActive = m['active_status'] as bool? ?? false;
      if (isActive) active++;

      double comm = 0;
      if (m['commission_history'] != null) {
        List<dynamic> history = m['commission_history'];
        for (var h in history) {
          if (h['user'] == m['referred_id']) {
            comm += _safeParseDouble(h['value']);
          }
        }
      }
      m['commission'] = comm; // Store calculated commission for display

      totalComm += comm;
      if (m['created_at'] != null) {
        DateTime join = DateTime.parse(m['created_at']);
        if (join.month == now.month && join.year == now.year) {
          monthComm += comm;
        }
      }
    }

    setState(() {
      _team = data;
      _stats = ReferralStats(
        totalReferrals: data.length,
        activeReferrals: active,
        totalCommissions: totalComm,
        thisMonthCommissions: monthComm,
      );
    });
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
      setState(() {
        _hasReferrer = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral code added successfully!')),
      );
      _referralCodeController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding referral: $e')));
      }
    }
  }


  void _showShareModal() {
    Share.share(_referralLink);
  }

  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xff1a1a1a),
            border: Border(bottom: BorderSide(color: Color(0xff808080))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Referral Program',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff2a2a2a),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            _stats.totalReferrals.toString(),
                            style: const TextStyle(
                              color: Color(0xffFFD700),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total Referrals',
                            style: TextStyle(
                              color: Color(0xff808080),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff2a2a2a),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            _stats.activeReferrals.toString(),
                            style: TextStyle(
                              color: Colors.green[400],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Active Members',
                            style: TextStyle(
                              color: Color(0xff808080),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xff1a1a1a), Color(0xff2a2a2a)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xffFFD700).withValues(alpha: 0.2),
              ),
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
                      fontSize: 12,
                    ),
                    softWrap: true,
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Referral link copied to clipboard!',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffFFD700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy, color: Colors.black, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Copy Link',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showShareModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffFFD700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, color: Colors.black, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Share',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        
        if (_hasReferrer)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xff1a1a1a), Color(0xff2a2a2a)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xffFFD700).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person, color: Color(0xffFFD700), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Your Referrer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Code: $_referrerCode',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Email: $_referrerEmail',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        if (!_hasReferrer)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xff1a1a1a), Color(0xff2a2a2a)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xffFFD700).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add, color: Color(0xffFFD700), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Referral Code',
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
                      hintText: 'Enter referral code (e.g., REGTXXXX)',
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
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff1a1a1a),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xff808080)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.percent,
                          color: Color(0xffFFD700),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Commission Earnings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.trending_up, color: Colors.green[400], size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _stats.totalCommissions.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Color(0xffFFD700),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Image.asset(
                                'assets/images/coin.png',
                                width: 22,
                                height: 22,
                              ),
                            ],
                          ),
                          const Text(
                            'Total Earned',
                            style: TextStyle(
                              color: Color(0xff808080),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[600]!.withValues(alpha: 0.1),
                  Colors.purple[600]!.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(color: Colors.blue[600]!.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'How It Works',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Earn 5% commission on referral earnings',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '• Get bonus rewards for active referrals',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '• Track performance in real-time',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '• Instant payouts to your balance',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.people, color: Color(0xffFFD700), size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Team (${_team.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._team.map((member) {
          String id = member['id'].toString();
          bool isExpanded = _expandedMember == id;
          String name = member['profiles']['username'] ?? 'Unknown';
          String subtitle = member['profiles']['country'] ?? '';
          bool status = member['active_status'] as bool? ?? false;
          double commission = _safeParseDouble(member['commission']);
          double earnings = _safeParseDouble(member['earnings']);
          int level = member['level'] as int? ?? 1;
          DateTime? joinDate;
          if (member['created_at'] != null) {
            joinDate = DateTime.parse(member['created_at']);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _expandedMember = isExpanded ? null : id;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff1a1a1a),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpanded
                        ? const Color(0xffFFD700).withValues(alpha: 0.5)
                        : const Color(0xff808080),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xffFFD700),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  name
                                      .split(' ')
                                      .map((n) => n[0])
                                      .join()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w100,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: status
                                            ? Colors.green[400]
                                            : Colors.red[400],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status ? 'active' : 'inactive',
                                      style: TextStyle(
                                        color: status
                                            ? Colors.green[400]
                                            : Colors.red[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+${commission.toStringAsFixed(2)} REGT',
                              style: const TextStyle(
                                color: Color(0xffFFD700),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Commission',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (isExpanded && joinDate != null)
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Joined:',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(joinDate),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Level:',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    level.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Their Earnings:',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${earnings.toStringAsFixed(2)} REGT',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Commission:',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        commission.toStringAsFixed(2),
                                        style: TextStyle(
                                          color: Colors.green[400],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Image.asset(
                                        'assets/images/coin.png',
                                        width: 18,
                                        height: 18,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
    );
  }
}
