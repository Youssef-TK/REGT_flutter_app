
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  String _method = '';
  final _walletAddressController = TextEditingController();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _swiftController = TextEditingController();
  final _ibanController = TextEditingController();
  int _currentStep = 1;
  bool _loading = false;
  bool _showSuccess = false;
  List<Map<String, dynamic>> _pendingRequests = [];
  double _totalBalance = 0.0;
  double _balanceOnHold = 0.0;
  double _pendingTotal = 0.0;
  double _minWithdrawal = 100.0;
  Map<String, dynamic> _bankingInfo = {};

  final withdrawalMethods = [
    {
      'id': 'regt',
      'label': 'REGT',
      'description':
          'crypto-currency wallet __metamask, Trust wallet, etc. (bnb smart chain)',
      'icon': Icons.account_balance_wallet,
      'fee': '0 REGT',
      'time': '24-48 hours',
    },
    {
      'id': 'usdt',
      'label': 'USDT',
      'description': 'crypto-currency wallet __ (bnb smart chain)',
      'icon': Icons.credit_card,
      'fee': '2 USDT',
      'time': '1-6 hours',
    },
    {
      'id': 'bank',
      'label': 'bank transfer',
      'description': 'name, bank name, country, swift, IBAN',
      'icon': Icons.account_balance,
      'fee': '5 USD',
      'time': '3-5 days',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final data = await Supabase.instance.client
          .from('user_balances')
          .select('balance, balance_on_hold')
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) {
        debugPrint('No user_balance row for user $userId');
      } else {
        debugPrint(
          'Fetched balance: ${data['balance']}, on_hold: ${data['balance_on_hold']}',
        );
      }
      setState(() {
        _totalBalance = ((data?['balance'] as num?) ?? 0.0).toDouble();
        _balanceOnHold = ((data?['balance_on_hold'] as num?) ?? 0.0).toDouble();
      });
    } catch (e) {
      debugPrint('Error loading balance: $e');
    }

    try {
      final data = await Supabase.instance.client
          .from('withdraw_requests')
          .select()
          .eq('user_id', userId)
          .order('request_date', ascending: false);
      debugPrint('Fetched pending count: ${data.length}');
      setState(() {
        _pendingRequests = data;
        debugPrint('Pending details: ${_pendingRequests.map((r) => "${r['status'] ?? 'null'}: ${r['amount'] ?? 'null'}").join(", ")}');
        _pendingTotal = _pendingRequests
            .where(
              (req) =>
                  req['status'] == 'pending',
            )
            .fold(0.0, (sum, req) => sum + (req['amount'] as double? ?? 0.0));
      });
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }

    try {
      final configData = await Supabase.instance.client
          .from('configs')
          .select('minimum_withdraw')
          .maybeSingle();
      if (configData != null) {
        _minWithdrawal = (configData['minimum_withdraw'] as num? ?? 100.0)
            .toDouble();
      }
    } catch (e) {
      debugPrint('Error loading configs: $e');
    }

    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('banking_info')
          .eq('id', userId)
          .maybeSingle();
      if (profileData != null) {
        _bankingInfo =
            profileData['banking_info'] as Map<String, dynamic>? ?? {};
      }
    } catch (e) {
      debugPrint('Error loading banking info: $e');
    }

    setState(() {});
  }

  double get _availableBalance => ((_totalBalance - _pendingTotal) * 100000).round() / 100000;

  bool _validateStep1() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < _minWithdrawal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal amount is $_minWithdrawal REGT'),
        ),
      );
      return false;
    }
    if (amount > _availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient available balance')),
      );
      return false;
    }
    if (_method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a withdrawal method')),
      );
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_method == 'regt' || _method == 'usdt') {
      final wallet = _walletAddressController.text.trim();
      if (wallet.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your wallet address')),
        );
        return false;
      }
      if (wallet.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet address must be at least 10 characters'),
          ),
        );
        return false;
      }
    } else if (_method == 'bank') {
      if (_nameController.text.trim().isEmpty ||
          _bankNameController.text.trim().isEmpty ||
          _countryController.text.trim().isEmpty ||
          _swiftController.text.trim().isEmpty ||
          _ibanController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all bank details')),
        );
        return false;
      }
    }
    return true;
  }

  void _handleNext() {
    if (_currentStep == 1 && _validateStep1()) {
      setState(() {
        _currentStep = 2;
        if (_method == 'regt' || _method == 'usdt') {
          _walletAddressController.text = _bankingInfo['wallet'] ?? '';
        } else if (_method == 'bank') {
          _nameController.text = _bankingInfo['name'] ?? '';
          _bankNameController.text = _bankingInfo['bank'] ?? '';
          _countryController.text = _bankingInfo['country'] ?? '';
          _swiftController.text = _bankingInfo['swift'] ?? '';
          _ibanController.text = _bankingInfo['iban'] ?? '';
        }
      });
    } else if (_currentStep == 2 && _validateStep2()) {
      setState(() => _currentStep = 3);
    }
  }

  Future<void> _submitWithdrawal() async {
    setState(() => _loading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final amount = double.tryParse(_amountController.text);
    if (userId == null || amount == null || amount < _minWithdrawal) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid amount (min $_minWithdrawal REGT)')),
      );
      return;
    }

    Map<String, dynamic> details;
    if (_method == 'bank') {
      details = {
        'name': _nameController.text,
        'bankName': _bankNameController.text,
        'country': _countryController.text,
        'swift': _swiftController.text,
        'iban': _ibanController.text,
      };
    } else {
      details = {'walletAddress': _walletAddressController.text};
    }

    try {
      await Supabase.instance.client.from('withdraw_requests').insert({
        'user_id': userId,
        'amount': amount,
        'method': _method.toUpperCase(),
        'details': details,
        'status': 'pending',
        'request_date': DateTime.now().toIso8601String(),
      });
      await _loadData();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _showSuccess = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal requested. Admin will review.'),
        ),
      );
    } catch (e) {
      debugPrint('Insertion error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
      setState(() => _loading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Withdrawal Submitted!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your withdrawal request has been submitted successfully. You\'ll receive a confirmation email shortly.',
                style: TextStyle(color: Color(0xff808080), fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showSuccess = false;
                    _currentStep = 1;
                    _amountController.clear();
                    _method = '';
                    _walletAddressController.clear();
                    _nameController.clear();
                    _bankNameController.clear();
                    _countryController.clear();
                    _swiftController.clear();
                    _ibanController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFFD700),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Make Another Withdrawal'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFFD700),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
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
                    'Withdraw Funds',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ...List.generate(3, (index) {
                        final step = index + 1;
                        return Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: step <= _currentStep
                                      ? const Color(0xffFFD700)
                                      : const Color(0xff2a2a2a),
                                ),
                                child: Center(
                                  child: step < _currentStep
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.black,
                                        )
                                      : Text(
                                          step.toString(),
                                          style: TextStyle(
                                            color: step <= _currentStep
                                                ? Colors.black
                                                : const Color(0xff808080),
                                          ),
                                        ),
                                ),
                              ),
                              if (index < 2)
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xff808080),
                                    thickness: 1,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Step $_currentStep: ${_currentStep == 1
                        ? 'Amount & Method'
                        : _currentStep == 2
                        ? 'Payment Details'
                        : 'Review & Confirm'}',
                    style: const TextStyle(
                      color: Color(0xff808080),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _currentStep == 1
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xff1a1a1a),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xff808080)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available Balance to Withdraw',
                                style: TextStyle(
                                  color: Color(0xff808080),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$_availableBalance REGT',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'On Hold Balance',
                                style: TextStyle(
                                  color: Color(0xff808080),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$_balanceOnHold REGT',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 255, 108, 11),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pending Withdrawals',
                                style: TextStyle(
                                  color: Color(0xff808080),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '$_pendingTotal REGT',
                                style: const TextStyle(
                                  color: Color(0xff808080),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Withdrawal Amount',
                            labelStyle: const TextStyle(
                              color: Color(0xff808080),
                            ),
                            hintText: 'Minimum $_minWithdrawal REGT',
                            hintStyle: const TextStyle(
                              color: Color(0xff808080),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Withdrawal Method',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...withdrawalMethods.map(
                          (m) => GestureDetector(
                            onTap: () =>
                                setState(() => _method = m['id'] as String),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _method == (m['id'] as String)
                                    ? const Color(0xffFFD700).withValues(alpha: 0.1)
                                    : const Color(0xff1a1a1a),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _method == (m['id'] as String)
                                      ? const Color(0xffFFD700)
                                      : const Color(0xff808080),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    m['icon'] as IconData,
                                    color: const Color(0xffFFD700),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['label'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          (m['description'] as String?) ?? '',
                                          style: const TextStyle(
                                            color: Color(0xff808080),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Fee: ${(m['fee'] as String?) ?? ''} • Time: ${(m['time'] as String?) ?? ''}',
                                          style: const TextStyle(
                                            color: Color(0xff808080),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_method == (m['id'] as String))
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xffFFD700),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _currentStep == 2
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_method == 'regt' || _method == 'usdt')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (withdrawalMethods.firstWhere(
                                          (m) => m['id'] == _method,
                                        )['description']
                                        as String?) ??
                                    '',
                                style: const TextStyle(
                                  color: Color(0xff808080),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _walletAddressController,
                                decoration: InputDecoration(
                                  labelText: 'Wallet Address',
                                  labelStyle: const TextStyle(
                                    color: Color(0xff808080),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  labelStyle: const TextStyle(
                                    color: Color(0xff808080),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _bankNameController,
                                decoration: InputDecoration(
                                  labelText: 'Bank Name',
                                  labelStyle: const TextStyle(
                                    color: Color(0xff808080),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _countryController,
                                decoration: InputDecoration(
                                  labelText: 'Country',
                                  labelStyle: const TextStyle(
                                    color: Color(0xff808080),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _swiftController,
                                decoration: InputDecoration(
                                  labelText: 'SWIFT',
                                  labelStyle: const TextStyle(
                                    color: Color(0xff808080),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _ibanController,
                                decoration: InputDecoration(
                                  labelText: 'IBAN',
                                  labelStyle: const TextStyle(
                                    color: Color(0xff808080),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Review Withdrawal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Amount',
                                    style: TextStyle(color: Color(0xff808080)),
                                  ),
                                  Text(
                                    '${_amountController.text} REGT',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Method',
                                    style: TextStyle(color: Color(0xff808080)),
                                  ),
                                  Text(
                                    (withdrawalMethods
                                            .firstWhere(
                                              (m) => m['id'] == _method,
                                            )['label']
                                            ?.toString() ??
                                        ''),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_method != 'bank')
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Address',
                                      style: TextStyle(
                                        color: Color(0xff808080),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${_walletAddressController.text.substring(0, 10)}...${_walletAddressController.text.substring(_walletAddressController.text.length - 6)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _copyToClipboard(
                                            _walletAddressController.text,
                                          ),
                                          icon: const Icon(
                                            Icons.copy,
                                            size: 16,
                                            color: Color(0xff808080),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Name',
                                          style: TextStyle(
                                            color: Color(0xff808080),
                                          ),
                                        ),
                                        Text(
                                          _nameController.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Bank Name',
                                          style: TextStyle(
                                            color: Color(0xff808080),
                                          ),
                                        ),
                                        Text(
                                          _bankNameController.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Country',
                                          style: TextStyle(
                                            color: Color(0xff808080),
                                          ),
                                        ),
                                        Text(
                                          _countryController.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'SWIFT',
                                          style: TextStyle(
                                            color: Color(0xff808080),
                                          ),
                                        ),
                                        Text(
                                          _swiftController.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'IBAN',
                                          style: TextStyle(
                                            color: Color(0xff808080),
                                          ),
                                        ),
                                        Text(
                                          _ibanController.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xff808080)),
                          foregroundColor: Color(0xff808080),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : (_currentStep == 3
                                ? _submitWithdrawal
                                : _handleNext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffFFD700),
                        foregroundColor: Colors.black,
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(
                              _currentStep == 3
                                  ? 'Submit Withdrawal'
                                  : 'Continue',
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (_pendingRequests.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xff808080))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Withdrawals',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._pendingRequests.map(
                      (request) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xff1a1a1a),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xff808080)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${request['amount']} REGT',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  request['method'],
                                  style: const TextStyle(
                                    color: Color(0xff808080),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  request['status'].toString().capitalize(),
                                  style: TextStyle(
                                    color: _getStatusColor(request['status']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, yyyy').format(
                                    DateTime.parse(request['request_date']),
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xff808080),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
