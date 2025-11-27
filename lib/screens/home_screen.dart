
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:regt_app/providers/app_state.dart';
import 'ads_screen.dart'; // Assuming this file exists
import 'referrals_screen.dart'; // From previous context
import 'profile_screen.dart'; // Assuming this file exists
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:share_plus/share_plus.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SupabaseClient supabase;
  double _balance = 0.0;
  double _balanceOnHold = 0.0;
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _withdrawals = [];
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  int _currentIndex = 0;

  // Pagination
  int _displayedHistoryCount = 10;
  int _displayedWithdrawalsCount = 10;

  String _referralLink = '';
  ReferralStats _stats = ReferralStats(
    totalReferrals: 0,
    activeReferrals: 0,
    totalCommissions: 0,
    thisMonthCommissions: 0,
  );
  String _userCurrency = 'usd';
  double _regtPrice = 0.1;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    _generateReferralLink();
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => _loadData(),
    );
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _loadData(); // Refresh balance after confirmation
      }
    });
  }

  void _generateReferralLink() {
    final userId = supabase.auth.currentUser?.id ?? '';
    final referralCode = 'REGT${userId.toUpperCase()}';
    // _referralLink = 'https://regtai.com/join?ref=$referralCode';
    _referralLink = referralCode;
  }

  Future<void> _loadData() async {
    setState(() {
      _isRefreshing = true;
    });

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isRefreshing = false;
      });
      return;
    }

    // Print JWT metadata for debug
    final session = supabase.auth.currentSession;
    if (session != null) {
      debugPrint('JWT User Metadata: ${session.user.userMetadata}');
    }

    try {
      // Fetch user currency from profiles
      final profileData = await supabase
          .from('profiles')
          .select('currency')
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null) {
        _userCurrency = profileData['currency'] as String? ?? 'usd';
      }

      // Fetch prices from configs (assuming single config row)
      final configData = await supabase
          .from('configs')
          .select('usd_regt_price, eur_regt_price')
          .maybeSingle();

      if (configData != null) {
        final double usdPrice = (configData['usd_regt_price'] as num? ?? 0.1).toDouble();
        final double eurPrice = (configData['eur_regt_price'] as num? ?? 0.08).toDouble();
        _regtPrice = _userCurrency == 'usd' ? usdPrice : eurPrice;
      }

      final data = await supabase
          .from('user_balances')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _balance = (data['balance'] as num? ?? 0.0).toDouble();
          _balanceOnHold = (data['balance_on_hold'] as num? ?? 0.0).toDouble();

          final historyData = data['transaction_history'];

          if (historyData is List) {
            _history = historyData.cast<Map<String, dynamic>>();
          } else if (historyData is String) {
            try {
              final decoded = jsonDecode(historyData);
              if (decoded is List) {
                _history = decoded.cast<Map<String, dynamic>>();
              } else {
                _history = [];
                debugPrint('Decoded transaction history is not a List');
              }
            } catch (e) {
              _history = [];
              debugPrint('Error decoding transaction history: $e');
            }
          } else {
            _history = [];
          }

          // Sort history by date descending (newest first)
          _history.sort(
            (a, b) => DateTime.parse(
              b['date'] ?? DateTime.now().toIso8601String(),
            ).compareTo(
              DateTime.parse(a['date'] ?? DateTime.now().toIso8601String()),
            ),
          );
        });
        Provider.of<AppState>(context, listen: false).updateBalance(_balance);
      } else {
        setState(() {
          _balance = 0.0;
          _balanceOnHold = 0.0;
          _history = [];
        });
      }

      final referralData = await supabase
          .from('referrals')
          .select()
          .eq('referrer_id', userId);
      double totalComm = 0.0;
      double monthComm = 0.0;
      int active = 0;
      DateTime now = DateTime.now();
      for (var m in referralData) {
        bool isActive = m['active_status'] as bool? ?? false;
        if (isActive) active++;
        if (m['commission_history'] != null) {
          List<dynamic> history = m['commission_history'];
          for (var h in history) {
            if (h['user'] == m['referred_id']) {
              double value = (h['value'] as num? ?? 0).toDouble();
              totalComm += value;
              if (h['date'] != null) {
                DateTime commDate = DateTime.parse(h['date']);
                if (commDate.month == now.month && commDate.year == now.year) {
                  monthComm += value;
                }
              }
            }
          }
        }
      }
      setState(() {
        _stats = ReferralStats(
          totalReferrals: referralData.length,
          activeReferrals: active,
          totalCommissions: totalComm,
          thisMonthCommissions: monthComm,
        );
      });

      // Fetch all withdrawals for the user with explicit columns
      final withdrawalsData = await supabase
          .from('withdraw_requests')
          .select(
            'id, user_id, amount, method, details, status, request_date, transaction_ref, approved_at, rejection_ref',
          )
          .eq('user_id', userId);
      debugPrint('Withdrawals fetched: ${withdrawalsData.length}'); // Debug log
      setState(() {
        List<Map<String, dynamic>> processing = [];
        List<Map<String, dynamic>> pending = [];
        List<Map<String, dynamic>> others = [];
        for (var wd in withdrawalsData) {
          String status = (wd['status'] as String?)?.toLowerCase() ?? '';
          if (status == 'processing') {
            processing.add(wd);
          } else if (status == 'pending') {
            pending.add(wd);
          } else {
            others.add(wd);
          }
        }

        // Sort each group by request_date descending (new to old)
        int sortFunc(Map<String, dynamic> a, Map<String, dynamic> b) {
          try {
            return DateTime.parse(
              b['request_date'] ?? DateTime.now().toIso8601String(),
            ).compareTo(
              DateTime.parse(
                a['request_date'] ?? DateTime.now().toIso8601String(),
              ),
            );
          } catch (e) {
            return 0; // Graceful if parse fails
          }
        }

        processing.sort(sortFunc);
        pending.sort(sortFunc);
        others.sort(sortFunc);

        // Combine in order: processing then pending then others
        _withdrawals = [...processing, ...pending, ...others];
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _loadMoreHistory() {
    setState(() {
      _displayedHistoryCount += 10;
    });
  }

  void _loadMoreWithdrawals() {
    setState(() {
      _displayedWithdrawalsCount += 10;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String formatNumber(double num) {
    String strNum = num.toString();
    int dotIdx = strNum.indexOf('.');
    if (dotIdx == -1) {
      return '$strNum.0000';
    }
    int endIdx = dotIdx + 5;
    String truncated = endIdx > strNum.length
        ? strNum
        : strNum.substring(0, endIdx);
    List<String> parts = truncated.split('.');
    String integer = parts[0];
    String decimal = parts.length > 1 ? parts[1] : '';
    decimal = decimal.padRight(4, '0');
    return '$integer.$decimal';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  IconData _getTransactionIcon(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('ad')) {
      return Icons.play_arrow;
    } else if (lowerType.contains('survey')) {
      return Icons.description;
    } else if (lowerType.contains('referral')) {
      return Icons.trending_up;
    } else if (lowerType.contains('withdrawal')) {
      return Icons.trending_down;
    } else {
      return Icons.info;
    }
  }

  String _formatDescription(String type) {
    return type
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showShareModal() {
    Share.share(_referralLink);
  }

  Widget _buildHomeContent() {
    String symbol = _userCurrency == 'usd' ? '\$' : '€';
    String currencyName = _userCurrency.toUpperCase();
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage(
                        'assets/images/regt_logo.png',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Text(
                          'REGT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Image.asset(
                        //   'assets/images/coin.png',
                        //   width: 40,
                        //   height: 40,
                        // ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildAmountWithCoin(
                      formatNumber(_balance),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      coinSize: 14,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),
          // Balance Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Balance',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            _buildAmountWithCoin(
                              formatNumber(_balance),
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              coinSize: 28,
                            ),
                            Text(
                              '≈ ${symbol}${formatNumber(_balance * _regtPrice)} $currencyName',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _isRefreshing ? null : _loadData,
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFFFD700),
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh,
                                  color: Color(0xFFFFD700),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _currentIndex = 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              side: BorderSide(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                              foregroundColor: Colors.blue[300],
                              shape: const CircleBorder(),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, size: 42),
                                SizedBox(height: 4),
                                Text('Ads'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _currentIndex = 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.2),
                              side: BorderSide(
                                color: Colors.green.withOpacity(0.3),
                              ),
                              foregroundColor: Colors.green[300],
                              shape: const CircleBorder(),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description, size: 32),
                                SizedBox(height: 4),
                                Text('Surveys'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'On Hold Balance',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    _buildAmountWithCoin(
                      formatNumber(_balanceOnHold),
                      textStyle: const TextStyle(
                        color: Color.fromARGB(255, 255, 108, 11),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      coinSize: 24,
                    ),
                    Text(
                      '≈ ${symbol}${formatNumber(_balanceOnHold * _regtPrice)} $currencyName',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Referral Link Card
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
                  color: const Color(0xffFFD700).withOpacity(0.2),
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
                        'Referral Link',
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
          // Referral Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard(_stats.totalReferrals.toString(), 'Total Referrals'),
                _buildStatCard(_stats.activeReferrals.toString(), 'Active Referrals'),
              ],
            ),
          ),
          // Commission Earnings Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Icon(
                        Icons.trending_up,
                        color: Colors.green[400],
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAmountWithCoin(
                              _stats.totalCommissions.toStringAsFixed(2),
                              textStyle: const TextStyle(
                                color: Color(0xffFFD700),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              coinSize: 22,
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
                      // Expanded(
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Text(
                      //         '${_stats.thisMonthCommissions.toStringAsFixed(2)} REGT',
                      //         style: TextStyle(
                      //           color: Colors.green[400],
                      //           fontSize: 20,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //       ),
                      //       const Text(
                      //         'This Month',
                      //         style: TextStyle(
                      //           color: Color(0xff808080),
                      //           fontSize: 12,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Withdrawals Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Withdrawals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/withdrawal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 16),
                      SizedBox(width: 4),
                      Text('Withdraw'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Withdrawals List or Empty Message
          if (_withdrawals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'No withdrawals',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _withdrawals.length > _displayedWithdrawalsCount
                  ? _displayedWithdrawalsCount
                  : _withdrawals.length,
              itemBuilder: (context, index) {
                final item = _withdrawals[index];
                final amount = item['amount'] as num? ?? 0;
                String method = item['method'] as String? ?? 'Unknown';
                String status = item['status'] as String? ?? 'pending';
                final requestDate =
                    item['request_date'] as String? ?? DateTime.now().toIso8601String();
                DateTime parsedDate;
                try {
                  parsedDate = DateTime.parse(requestDate);
                } catch (e) {
                  parsedDate = DateTime.now();
                }
                final formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                // Capitalize status and method for display
                status = '${status[0].toUpperCase()}${status.substring(1)}';
                method = method
                    .split(' ')
                    .map(
                      (word) => '${word[0].toUpperCase()}${word.substring(1)}',
                    )
                    .join(' ');

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8.0,
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      final details =
                          item['details'] as Map<String, dynamic>? ?? {};
                      final rawMethod = (item['method'] as String? ?? 'unknown')
                          .toLowerCase();
                      final rawStatus = (item['status'] as String? ?? 'pending')
                          .toLowerCase();
                      final transactionRef =
                          item['transaction_ref'] as String? ?? 'N/A';
                      final rejectionRef =
                          item['rejection_ref'] as String? ?? 'N/A';
                      final approvedAt = item['approved_at'] as String?;
                      DateTime parsedApprovedAt;
                      String formattedApprovedDate = '';
                      String formattedApprovedTime = '';
                      if (approvedAt != null) {
                        try {
                          parsedApprovedAt = DateTime.parse(approvedAt);
                          formattedApprovedDate = DateFormat('dd/MM/yyyy').format(parsedApprovedAt);
                          formattedApprovedTime = DateFormat('hh:mm a').format(parsedApprovedAt);
                        } catch (e) {
                          formattedApprovedDate = approvedAt.split('T')[0];
                          formattedApprovedTime = 'N/A';
                        }
                      }
                      final formattedRequestDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                      final formattedRequestTime = DateFormat('hh:mm a').format(parsedDate);

                      debugPrint(
                        'Withdrawal item tapped: method=$rawMethod, status=$rawStatus, details=$details',
                      );

                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF1A1A1A),
                            title: const Text(
                              'Withdrawal Details',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow(
                                    'Amount',
                                    formatNumber(amount.toDouble()),
                                  ),
                                  _buildDetailRow('Method', method),
                                  _buildDetailRow('Status', status),
                                  _buildDetailRow('Request Date', formattedRequestDate),
                                  _buildDetailRow('Request Time', formattedRequestTime),
                                  if (approvedAt != null)
                                    _buildDetailRow('Approved Date', formattedApprovedDate),
                                  if (approvedAt != null)
                                    _buildDetailRow('Approved Time', formattedApprovedTime),
                                  if (rawMethod == 'bank') ...[
                                    _buildDetailRow(
                                      'IBAN',
                                      details['iban'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'Name',
                                      details['name'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'SWIFT',
                                      details['swift'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'Country',
                                      details['country'] ?? 'N/A',
                                    ),
                                    _buildDetailRow(
                                      'Bank Name',
                                      details['bankName'] ?? 'N/A',
                                    ),
                                  ] else if (rawMethod == 'regt' ||
                                      rawMethod == 'usdt' ||
                                      rawMethod == 'wallet') ...[
                                    _buildExpandableDetailRow(
                                      'Wallet Address',
                                      details['walletAddress'] ?? 'N/A',
                                    ),
                                  ],
                                  if (rawStatus == 'approved')
                                    _buildCopyableDetailRow(
                                      'Transaction Ref',
                                      transactionRef,
                                      context,
                                    ),
                                  if (rawStatus == 'rejected')
                                    _buildExpandableDetailRow(
                                      'Rejection Ref',
                                      rejectionRef,
                                    ),
                                ],
                              ),
                            ),
                            actions: [
                              if (rawStatus == 'pending')
                                TextButton(
                                  onPressed: () async {
                                    final withdrawalId = item['id'] as int?;
                                    if (withdrawalId != null) {
                                      try {
                                        await supabase
                                            .from('withdraw_requests')
                                            .delete()
                                            .eq('id', withdrawalId);
                                        Navigator.of(context).pop();
                                        _loadData();
                                      } catch (e) {
                                        debugPrint('Error deleting withdrawal: $e');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Error canceling request'),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Cancel Request',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(color: Color(0xFFFFD700)),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildAmountWithCoin(
                                  amount.toString(),
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  coinSize: 16,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  method,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          // Load More Button for Withdrawals
          if (_displayedWithdrawalsCount < _withdrawals.length)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _loadMoreWithdrawals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Load More'),
              ),
            ),
          // Recent Activity Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Transaction List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.length > _displayedHistoryCount
                ? _displayedHistoryCount
                : _history.length,
            itemBuilder: (context, index) {
              final item = _history[index];
              final type = item['type'] as String? ?? 'unknown';
              final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
              final dateStr =
                  item['date'] as String? ?? DateTime.now().toIso8601String();
              final date = DateTime.parse(dateStr);
              final timeAgo = _formatTimeAgo(date);
              final description = _formatDescription(type);
              final icon = _getTransactionIcon(type);
              final amountColor = amount >= 0
                  ? Colors.green[400]
                  : Colors.red[400];
              final sign = amount > 0 ? '+' : (amount < 0 ? '-' : '');

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 8.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      child: Icon(icon, color: amountColor, size: 16),
                    ),
                    title: Text(
                      description,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      timeAgo,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: _buildAmountWithCoin(
                      '$sign${formatNumber(amount.abs())}',
                      textStyle: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      coinSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
          if (_displayedHistoryCount < _history.length)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _loadMoreHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Load More'),
              ),
            ),
          const SizedBox(height: 80), // Padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xff0a0a0a),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableDetailRow(String label, String value, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xff0a0a0a),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.copy,
                      color: Color(0xFFFFD700),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const AdsScreen(),
          const ReferralsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFFD700),
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: 'Ads'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Referrals'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to display amount with coin image
  Widget _buildAmountWithCoin(String amount, {TextStyle? textStyle, double coinSize = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: textStyle,
        ),
        const SizedBox(width: 4),
        Image.asset(
          'assets/images/coin.png',
          width: coinSize,
          height: coinSize,
        ),
      ],
    );
  }
}