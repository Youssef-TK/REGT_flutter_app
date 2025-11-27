
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:regt_app/providers/app_state.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  RewardedAd? _rewardedAd;
  int _adsWatched = 0;
  bool _isAdReady = false;
  bool _isOnCooldown = false;
  Duration _remainingCooldown = Duration.zero;
  Timer? _cooldownTimer;
  double _lastReward = 0.0;

  // New: Commission rate for referrals (5% as per the latest code in "How It Works")
  double _commissionRate = 0.05;
  double _adReward = 0.006;

  int _maxAds = 16;
  int _adCooldownSeconds = 30;
  String _userCurrency = 'usd';
  double _regtPrice = 0.1;
  Timer? _configTimer;

  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadAd();
    _loadAdsWatched();
    _configTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => _loadConfig(),
    );
  }

  Future<void> _loadConfig() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Fetch user currency from profiles
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('currency')
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null) {
        _userCurrency = profileData['currency'] as String? ?? 'usd';
      }

      // Fetch prices and other configs from configs (assuming single config row)
      final configData = await Supabase.instance.client
          .from('configs')
          .select(
              'usd_regt_price, eur_regt_price, ad_reward, referral_reward, ad_cooldown, max_ads')
          .maybeSingle();

      if (configData != null) {
        final double usdPrice =
            (configData['usd_regt_price'] as num? ?? 0.1).toDouble();
        final double eurPrice =
            (configData['eur_regt_price'] as num? ?? 0.08).toDouble();
        _regtPrice = _userCurrency == 'usd' ? usdPrice : eurPrice;
        _adReward = (configData['ad_reward'] as num? ?? 0.006).toDouble();
        _commissionRate =
            (configData['referral_reward'] as num? ?? 0.05).toDouble();
        _maxAds = (configData['max_ads'] as num? ?? 16).toInt();
        _adCooldownSeconds = (configData['ad_cooldown'] as num? ?? 30).toInt();
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  Future<void> _loadAdsWatched() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final today = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String();
    try {
      final response = await Supabase.instance.client
          .from('ad_events')
          .select()
          .eq('user_id', userId)
          .eq('status', 'success')
          .gte('timestamp', today)
          .count(CountOption.exact);
      setState(() {
        _adsWatched = response.count;
      });
      debugPrint('Loaded ads watched: $_adsWatched');
    } catch (e) {
      debugPrint('Error loading ads watched: $e');
      setState(() {
        _adsWatched = 0;
      });
    }
  }

  void _loadAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Ad loaded');
          setState(() {
            _rewardedAd = ad;
            _isAdReady = true;
          });
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) =>
                debugPrint('Ad showed full screen'),
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Ad failed to show: $error');
              ad.dispose();
              _loadAd();
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Ad dismissed');
              ad.dispose();
              _loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Ad failed to load: $error');
          Future.delayed(
            const Duration(seconds: 5),
            _loadAd,
          ); // Add delay to prevent rapid retry loops
        },
      ),
    );
  }

  void _showAd() async {
    if (_rewardedAd == null || _isOnCooldown || _adsWatched >= _maxAds) {
      debugPrint(
        'Cannot show ad: ${_rewardedAd == null ? 'No ad' : ''} ${_isOnCooldown ? 'Cooldown' : ''} ${_adsWatched >= _maxAds ? 'Max ads' : ''}',
      );
      return;
    }

    debugPrint('Showing ad');
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        debugPrint(
          'Reward earned! Type: ${reward.type}, Amount: ${reward.amount}',
        );
        double baseReward = _adReward;
        _adsWatched++;
        if (_adsWatched % 10 == 0) baseReward += 1.0;
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) return;

        try {
          debugPrint('Inserting ad event');
          await Supabase.instance.client.from('ad_events').insert({
            'user_id': userId,
            'status': 'success',
            'reward': baseReward,
            'timestamp': DateTime.now().toIso8601String(),
            'ip_address': 'dummy',
          });
          debugPrint('Ad event inserted');

          debugPrint('Fetching current balance');
          final currentResponse = await Supabase.instance.client
              .from('user_balances')
              .select('balance, transaction_history')
              .eq('user_id', userId)
              .maybeSingle();

          final newHistoryEntry = {
            'type': 'ad_reward',
            'amount': baseReward,
            'date': DateTime.now().toIso8601String(),
          };

          double newBalance;
          List<Map<String, dynamic>> history = [];

          if (currentResponse == null) {
            debugPrint('No balance row - inserting new');
            newBalance = baseReward;
            history = [newHistoryEntry];
            await Supabase.instance.client.from('user_balances').insert({
              'user_id': userId,
              'balance': newBalance,
              'transaction_history': history,
            });
          } else {
            debugPrint('Updating existing balance');
            newBalance = (currentResponse['balance'] ?? 0.0) + baseReward;
            dynamic historyData = currentResponse['transaction_history'];
            if (historyData is List) {
              history = historyData.cast<Map<String, dynamic>>();
            } else if (historyData is String) {
              history = (jsonDecode(historyData) as List).cast<Map<String, dynamic>>();
            }
            history.add(newHistoryEntry);
            await Supabase.instance.client
                .from('user_balances')
                .update({
                  'balance': newBalance,
                  'transaction_history': history,
                })
                .eq('user_id', userId);
          }
          debugPrint('Balance updated');

          if (!mounted) return;
          Provider.of<AppState>(
            context,
            listen: false,
          ).updateBalance(newBalance);

          // New: Handle referrer commission
          await _handleReferrerCommission(userId, baseReward);

          await _loadAdsWatched();
          setState(() {
            _isOnCooldown = true;
            _remainingCooldown = Duration(
              seconds: _adCooldownSeconds,
            ); // Set to dynamic cooldown
            _lastReward = baseReward;
          });
          _startCooldownTimer();
          _showRewardModal();
        } catch (e) {
          debugPrint('Error updating balance: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update balance: $e')),
            );
          }
        }
      },
    );
    _rewardedAd = null;
    _loadAd();
  }

  // New method: Handle commission for the referrer
  Future<void> _handleReferrerCommission(String referredId, double baseReward) async {
    try {
      // Find the referrer for the current user (referred_id)
      final referralResponse = await Supabase.instance.client
          .from('referrals')
          .select('referrer_id, commission_history, active_status')
          .eq('referred_id', referredId)
          .maybeSingle();

      if (referralResponse == null) {
        debugPrint('No referrer found for user $referredId');
        return;
      }

      final bool isActive = referralResponse['active_status'] as bool? ?? false;
      if (!isActive) {
        debugPrint('Referral is not active for user $referredId');
        return;
      }

      final String referrerId = referralResponse['referrer_id'] as String;
      final double commission = (baseReward * _commissionRate * 0.01 * 100000).round() / 100000;
      // commission = (baseReward * _commissionRate * 100000).round() / 100000;

      debugPrint('Calculating commission for referrer $referrerId: $commission REGT');

      // Update referrer's balance
      final referrerBalanceResponse = await Supabase.instance.client
          .from('user_balances')
          .select('balance, transaction_history')
          .eq('user_id', referrerId)
          .maybeSingle();

      final referrerHistoryEntry = {
        'type': 'referral_commission',
        'amount': commission,
        'date': DateTime.now().toIso8601String(),
        'from_user': referredId, // Optional: track who the commission came from
      };

      double referrerNewBalance;
      List<Map<String, dynamic>> referrerHistory = [];

      if (referrerBalanceResponse == null) {
        debugPrint('No balance row for referrer - inserting new');
        referrerNewBalance = commission;
        referrerHistory = [referrerHistoryEntry];
        await Supabase.instance.client.from('user_balances').insert({
          'user_id': referrerId,
          'balance': referrerNewBalance,
          'transaction_history': referrerHistory,
        });
      } else {
        debugPrint('Updating existing balance for referrer');
        referrerNewBalance = (referrerBalanceResponse['balance'] ?? 0.0) + commission;
        dynamic historyData = referrerBalanceResponse['transaction_history'];
        if (historyData is List) {
          referrerHistory = historyData.cast<Map<String, dynamic>>();
        } else if (historyData is String) {
          referrerHistory = (jsonDecode(historyData) as List).cast<Map<String, dynamic>>();
        }
        referrerHistory.add(referrerHistoryEntry);
        debugPrint("old balance: ${referrerBalanceResponse['balance']} commission: $commission new balance: $referrerNewBalance");
        await Supabase.instance.client
            .from('user_balances')
            .update({
              'balance': referrerNewBalance,
              'transaction_history': referrerHistory,
            })
            .eq('user_id', referrerId);
      }
      debugPrint('Referrer balance updated');

      // Update commission_history in the referrals table
      List<dynamic> commissionHistory = referralResponse['commission_history'] ?? [];
      commissionHistory.add({
        'user': referredId, // As per your existing loop in _loadTeam
        'value': commission,
        // Optional: add 'date' if needed for future filtering
      });

      await Supabase.instance.client
          .from('referrals')
          .update({'commission_history': commissionHistory})
          .eq('referrer_id', referrerId)
          .eq('referred_id', referredId);

      debugPrint('Commission history updated in referrals table');
    } catch (e) {
      debugPrint('Error handling referrer commission: $e');
      // Optionally: Show a snackbar or log, but don't block the user's reward
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel(); // Cancel any existing timer
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingCooldown.inSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isOnCooldown = false;
          _remainingCooldown = Duration.zero;
        });
      } else {
        setState(() {
          _remainingCooldown = _remainingCooldown - const Duration(seconds: 1);
        });
      }
    });
  }

  String _formatCooldown() {
    final minutes = _remainingCooldown.inMinutes;
    final seconds = _remainingCooldown.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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

  void _showRewardModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.2)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard,
                size: 32,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reward Earned!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+${_lastReward.toStringAsFixed(4)} REGT',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _configTimer?.cancel();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final balance = appState.balance;
    String symbol = _userCurrency == 'usd' ? '\$' : '€';
    String currencyName = _userCurrency.toUpperCase();
    final adsLeft = _maxAds - _adsWatched;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage('assets/images/regt_logo.png'),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    ' REGT',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${formatNumber(balance)}  REGT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Text(
                  //   '\$${formatNumber(_balance * usdRate)}',
                  //   style: const TextStyle(color: Colors.grey),
                  // ),
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
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
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
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            '${formatNumber(balance)} REGT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '≈ $symbol${formatNumber(balance * _regtPrice)} $currencyName',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      // IconButton(
                      //   onPressed: _isRefreshing ? null : _loadData,
                      //   icon: _isRefreshing
                      //       ? const SizedBox(
                      //           width: 20,
                      //           height: 20,
                      //           child: CircularProgressIndicator(
                      //             strokeWidth: 2,
                      //             color: Color(0xFFFFD700),
                      //           ),
                      //         )
                      //       : const Icon(
                      //           Icons.refresh,
                      //           color: Color(0xFFFFD700),
                      //         ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //   children: [
                  //     SizedBox(
                  //       width:
                  //           120, // Adjust this value to change the button size (e.g., 120 for smaller, 200 for larger)
                  //       height: 120,
                  //       child: ElevatedButton(
                  //         onPressed: () => setState(() => _currentIndex = 1),
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: Colors.blue.withOpacity(0.2),
                  //           side: BorderSide(
                  //             color: Colors.blue.withOpacity(0.3),
                  //           ),
                  //           foregroundColor: Colors.blue[300],
                  //           shape: const CircleBorder(),
                  //         ),
                  //         child: const Column(
                  //           mainAxisAlignment: MainAxisAlignment.center,
                  //           children: [
                  //             Icon(Icons.play_arrow, size: 42),
                  //             SizedBox(height: 4),
                  //             Text('Watch Ads'),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width:
                  //           120, // Adjust this value to change the button size (e.g., 120 for smaller, 200 for larger)
                  //       height: 120,
                  //       child: ElevatedButton(
                  //         onPressed: () => setState(() => _currentIndex = 2),
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: Colors.green.withOpacity(0.2),
                  //           side: BorderSide(
                  //             color: Colors.green.withOpacity(0.3),
                  //           ),
                  //           foregroundColor: Colors.green[300],
                  //           shape: const CircleBorder(),
                  //         ),
                  //         child: const Column(
                  //           mainAxisAlignment: MainAxisAlignment.center,
                  //           children: [
                  //             Icon(Icons.description, size: 32),
                  //             SizedBox(height: 4),
                  //             Text('Surveys'),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),

        // Ads Progress
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Watch Ads',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      '$adsLeft/$_maxAds Left',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _adsWatched / _maxAds,
                  backgroundColor: Colors.grey[800],
                  color: const Color(0xFFFFD700),
                  minHeight: 6,
                ),
              ],
            ),
          ),
        ),
        // Main Content
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ads Watched: $_adsWatched / $_maxAds',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  _isOnCooldown
                      ? 'Cooldown: ${_formatCooldown()}'
                      : 'Ready to watch ad!',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isAdReady && !_isOnCooldown && adsLeft > 0
                      ? _showAd
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOnCooldown || adsLeft <= 0
                        ? Colors.grey
                        : const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isOnCooldown
                        ? 'Wait: ${_formatCooldown()}'
                        : (adsLeft <= 0 ? 'No Ads Left' : 'Watch Ad'),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bonus Info
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.1),
                  const Color(0xFFFFA500).withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                const Text(
                  'Bonus Rewards',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w100,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Watch 10 ads to earn a bonus +1 REGT! (${_adsWatched % 10}/10)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}