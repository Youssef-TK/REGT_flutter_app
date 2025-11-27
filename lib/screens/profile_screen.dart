// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:regt_app/providers/app_state.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   String _language = 'en';
//   String _currency = 'usd';
//   bool _notificationsEnabled = true;
//   bool _emailUpdates = false;
//   String? _userId;
//   String? _email;
//   double _balance = 0.0;




//   Map<String, dynamic>? _profileInfo;
//   Map<String, dynamic>? _bankingInfo;

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _countryController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genders = [
//     'Male',
//     'Female',
//     'Other',
//     'Prefer not to say',
//   ];

//   // Financial info
//   final TextEditingController _bankController = TextEditingController();
//   final TextEditingController _ibanController = TextEditingController();
//   final TextEditingController _accountNameController = TextEditingController();
//   final TextEditingController _swiftController = TextEditingController();
//   final TextEditingController _walletController = TextEditingController();
//   final TextEditingController _financialCountryController = TextEditingController();

//   final List<Map<String, dynamic>> languages = [
//     {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'rtl': false},
//     {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'rtl': true},
//     {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳', 'rtl': false},
//     {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'rtl': false},
//     {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'rtl': false},
//     {'code': 'zh', 'name': '中文', 'flag': '🇨🇳', 'rtl': false},
//   ];

//   final List<Map<String, dynamic>> currencies = [
//     {'code': 'usd', 'name': 'US Dollar', 'symbol': '\$'},
//     {'code': 'eur', 'name': 'Euro', 'symbol': '€'},
//   ];

//   late Map<String, dynamic> selectedCurrencyMap;

//   @override
//   void initState() {
//     super.initState();
//     selectedCurrencyMap = currencies[0];
//     _loadProfile();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final user = Supabase.instance.client.auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _userId = user.id;
//         _email = user.email;
//       });
//       _balance = Provider.of<AppState>(context, listen: false).balance;
//     }
//   }

//   Future<void> _loadProfile() async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;

//     final data = await Supabase.instance.client
//         .from('profiles')
//         .select('language, currency, profile_info, banking_info')
//         .eq('id', userId)
//         .single();

//     setState(() {
//       _language = data['language'] ?? 'en';
//       _currency = data['currency'] ?? 'usd';
//       selectedCurrencyMap = currencies.firstWhere(
//         (c) => c['code'] == _currency,
//         orElse: () => currencies[0],
//       );
//       _profileInfo = data['profile_info'] ?? {};
//       _bankingInfo = data['banking_info'] ?? {};
//     });
//   }



//   Future<void> _updateLanguage(String newLang) async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;

//     await Supabase.instance.client
//         .from('profiles')
//         .update({'language': newLang})
//         .eq('id', userId);

//     setState(() => _language = newLang);

//     if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Language changed to $newLang')),
//       );
//   }

//   Future<void> _updateCurrency(String newCurr) async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;

//     await Supabase.instance.client
//         .from('profiles')
//         .update({'currency': newCurr})
//         .eq('id', userId);

//     setState(() {
//       _currency = newCurr;
//       selectedCurrencyMap = currencies.firstWhere((c) => c['code'] == newCurr);
//     });

//     if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Currency changed to ${newCurr.toUpperCase()}')),
//       );
//   }

//   Future<void> _updateProfileInfo(Map<String, dynamic> info) async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;
//     await Supabase.instance.client
//         .from('profiles')
//         .update({'profile_info': info})
//         .eq('id', userId);
//     setState(() => _profileInfo = info);
//     if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile info updated')));
//   }

//   Future<void> _updateBankingInfo(Map<String, dynamic> info) async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;
//     await Supabase.instance.client
//         .from('profiles')
//         .update({'banking_info': info})
//         .eq('id', userId);
//     setState(() => _bankingInfo = info);
//     if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Financial info updated')));
//   }

//   void _handleLanguageChange(Map<String, dynamic> language) {
//     _updateLanguage(language['code']);

//   }

//   void _handleCurrencyChange(Map<String, dynamic> currency) {
//     _updateCurrency(currency['code']);

//   }

//   void _handleCopyUserId() {
//     if (_userId != null) {
//       Clipboard.setData(ClipboardData(text: _userId!));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('User ID copied to clipboard!')),
//       );
//     }
//   }

//   void _handleLogout() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () async {
//               await Supabase.instance.client.auth.signOut();
//               if (context.mounted) {
//                 Navigator.pushReplacementNamed(context, '/login');
//               }
//             },
//             child: const Text('Yes'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _openProfileModal() {
//     _nameController.text = _profileInfo?['name'] ?? '';
//     _ageController.text = _profileInfo?['age']?.toString() ?? '';
//     _countryController.text = _profileInfo?['country'] ?? '';
//     _phoneController.text = _profileInfo?['phone'] ?? '';
//     _selectedGender = _profileInfo?['gender'];
//     setState(() => _showProfileModal = true);
//   }

//   void _saveProfileInfo() async {
//     final ageStr = _ageController.text.trim();
//     int? age = ageStr.isNotEmpty ? int.tryParse(ageStr) : null;
//     if (ageStr.isNotEmpty && age == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid age')));
//       return;
//     }
//     final info = <String, dynamic>{
//       'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
//       'age': age,
//       'gender': _selectedGender,
//       'country': _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
//       'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
//     }..removeWhere((key, value) => value == null);

//     await _updateProfileInfo(info);
//     setState(() => _isEditingProfile = false);
//   }

//   void _openFinancialModal() {
//     _bankController.text = _bankingInfo?['bank'] ?? '';
//     _ibanController.text = _bankingInfo?['iban'] ?? '';
//     _accountNameController.text = _bankingInfo?['name'] ?? '';
//     _swiftController.text = _bankingInfo?['swift'] ?? '';
//     _walletController.text = _bankingInfo?['wallet'] ?? '';
//     _financialCountryController.text = _bankingInfo?['country'] ?? '';
//     setState(() => _showFinancialModal = true);
//   }

//   void _saveFinancialInfo() async {
//     final info = <String, dynamic>{
//       'bank': _bankController.text.trim().isNotEmpty ? _bankController.text.trim() : null,
//       'iban': _ibanController.text.trim().isNotEmpty ? _ibanController.text.trim() : null,
//       'name': _accountNameController.text.trim().isNotEmpty ? _accountNameController.text.trim() : null,
//       'swift': _swiftController.text.trim().isNotEmpty ? _swiftController.text.trim() : null,
//       'wallet': _walletController.text.trim().isNotEmpty ? _walletController.text.trim() : null,
//       'country': _financialCountryController.text.trim().isNotEmpty ? _financialCountryController.text.trim() : null,
//     }..removeWhere((key, value) => value == null);

//     await _updateBankingInfo(info);
//     setState(() => _isEditingFinancial = false);
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _ageController.dispose();
//     _countryController.dispose();
//     _phoneController.dispose();
//     _bankController.dispose();
//     _ibanController.dispose();
//     _accountNameController.dispose();
//     _swiftController.dispose();
//     _walletController.dispose();
//     _financialCountryController.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedLangName = languages.firstWhere(
//       (lang) => lang['code'] == _language,
//       orElse: () => languages[0],
//     )['name'];

//     final bool isProfileEmpty = _profileInfo?.isEmpty ?? true;
//     final bool isBankingEmpty = _bankingInfo?.isEmpty ?? true;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           ListView(
//             children: [
//               // Profile Header
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Color(0xff1a1a1a), Color(0xff2a2a2a)],
//                     begin: Alignment.centerLeft,
//                     end: Alignment.centerRight,
//                   ),
//                   border: Border(bottom: BorderSide(color: Color(0xff808080))),
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           width: 80,
//                           height: 80,
//                           decoration: const BoxDecoration(
//                             color: Color(0xffFFD700),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Center(
//                             child: Text(
//                               _userId?.substring(0, 2).toUpperCase() ?? 'U',
//                               style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text('Welcome back!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
//                               const SizedBox(height: 4),
//                               Text(_email ?? '', style: const TextStyle(color: Color(0xff808080), fontSize: 12)),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       'ID: ${_userId ?? ''}',
//                                       style: const TextStyle(color: Color(0xff808080), fontSize: 12),
//                                       overflow: TextOverflow.ellipsis,
//                                       maxLines: 1,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   IconButton(
//                                     onPressed: _handleCopyUserId,
//                                     icon: const Icon(Icons.copy, size: 16, color: Color(0xffFFD700)),
//                                     padding: EdgeInsets.zero,
//                                     constraints: const BoxConstraints(),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         Column(
//                           children: [
//                             Text(
//                               '${selectedCurrencyMap['symbol']}${_balance.toStringAsFixed(2)}',
//                               style: const TextStyle(color: Color(0xffFFD700), fontSize: 20, fontWeight: FontWeight.bold),
//                             ),
//                             const Text('REGT Balance', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
//                           ],
//                         ),
//                         Column(
//                           children: const [
//                             Text('5', style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
//                             Text('Referrals', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
//                           ],
//                         ),
//                         Column(
//                           children: const [
//                             Text('28', style: TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
//                             Text('Days Active', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               // Settings Sections
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Personal Info & Financial Info buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: GestureDetector(
//                             onTap: _openProfileModal,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xff1a1a1a),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(color: const Color(0xff808080)),
//                               ),
//                               child: const Padding(
//                                 padding: EdgeInsets.all(16.0),
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.person, color: Color(0xffFFD700), size: 20),
//                                     SizedBox(width: 12),
//                                     Expanded(
//                                       child: Text('Personal Info', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                     ),
//                                     Icon(Icons.chevron_right, color: Color(0xff808080)),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: GestureDetector(
//                             onTap: _openFinancialModal,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xff1a1a1a),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(color: const Color(0xff808080)),
//                               ),
//                               child: const Padding(
//                                 padding: EdgeInsets.all(16.0),
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.account_balance_wallet, color: Color(0xffFFD700), size: 20),
//                                     SizedBox(width: 12),
//                                     Expanded(
//                                       child: Text('Financial Info', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                     ),
//                                     Icon(Icons.chevron_right, color: Color(0xff808080)),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Language Selector
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xff1a1a1a),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: const Color(0xff808080)),
//                       ),
//                       child: GestureDetector(
//                         onTap: () => setState(() => _showLanguageModal = true),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.language, color: Color(0xffFFD700), size: 20),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Text('Language', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                     const SizedBox(height: 4),
//                                     Text(selectedLangName, style: const TextStyle(color: Color(0xff808080), fontSize: 14)),
//                                   ],
//                                 ),
//                               ),
//                               const Icon(Icons.chevron_right, color: Color(0xff808080)),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // CURRENCY SELECTOR - EXACTLY SAME STYLE
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xff1a1a1a),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: const Color(0xff808080)),
//                       ),
//                       child: GestureDetector(
//                         onTap: () => setState(() => _showCurrencyModal = true),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.currency_exchange, color: Color(0xffFFD700), size: 20),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Text('Currency', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       '${selectedCurrencyMap['name']} (${selectedCurrencyMap['symbol']})',
//                                       style: const TextStyle(color: Color(0xff808080), fontSize: 14),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const Icon(Icons.chevron_right, color: Color(0xff808080)),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // Notification Settings
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xff1a1a1a),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: const Color(0xff808080)),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 const Icon(Icons.notifications, color: Color(0xffFFD700), size: 20),
//                                 const SizedBox(width: 12),
//                                 const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 const Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text('Push Notifications', style: TextStyle(color: Colors.white, fontSize: 14)),
//                                     Text('Receive push notifications', style: TextStyle(color: Color(0xff808080), fontSize: 12)),
//                                   ],
//                                 ),
//                                 Switch(
//                                   value: _notificationsEnabled,
//                                   onChanged: (val) => setState(() => _notificationsEnabled = val),
//                                   activeThumbColor: const Color(0xffFFD700),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 const Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text('Email Updates', style: TextStyle(color: Colors.white, fontSize: 14)),
//                                     Text('Receive news & offers', style: TextStyle(color: Color(0xff808080), fontSize: 12)),
//                                   ],
//                                 ),
//                                 Switch(
//                                   value: _emailUpdates,
//                                   onChanged: (val) => setState(() => _emailUpdates = val),
//                                   activeThumbColor: const Color(0xffFFD700),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     // Logout Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _handleLogout,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.redAccent,
//                           padding: const EdgeInsets.symmetric(vertical: 18),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//                       ),
//                     ),

//                     const SizedBox(height: 40),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           // Language Modal
//           if (_showLanguageModal)
//             Center(
//               child: Container(
//                 color: Colors.black.withValues(alpha: 0.8),
//                 child: Center(
//                   child: Container(
//                     constraints: const BoxConstraints(maxWidth: 300),
//                     decoration: BoxDecoration(
//                       color: const Color(0xff1a1a1a),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Padding(
//                           padding: EdgeInsets.all(16.0),
//                           child: Text('Select Language', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
//                         ),
//                         const Divider(color: Color(0xff808080)),
//                         Flexible(
//                           child: ListView.builder(
//                             shrinkWrap: true,
//                             itemCount: languages.length,
//                             itemBuilder: (context, index) {
//                               final language = languages[index];
//                               final isSelected = _language == language['code'];
//                               return GestureDetector(
//                                 onTap: () => _handleLanguageChange(language),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     color: isSelected ? const Color(0xffFFD700).withValues(alpha: 0.1) : Colors.transparent,
//                                     border: isSelected
//                                         ? const Border(right: BorderSide(color: Color(0xffFFD700), width: 2))
//                                         : null,
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Text(language['flag'], style: const TextStyle(fontSize: 24)),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(language['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                             if (language['rtl']) const Text('RTL Support', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
//                                           ],
//                                         ),
//                                       ),
//                                       if (isSelected)
//                                         Container(
//                                           width: 8,
//                                           height: 8,
//                                           decoration: const BoxDecoration(color: Color(0xffFFD700), shape: BoxShape.circle),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         const Divider(color: Color(0xff808080)),
//                         TextButton(
//                           onPressed: () => setState(() => _showLanguageModal = false),
//                           child: const Text('Cancel', style: TextStyle(color: Color(0xff808080))),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Currency Modal (identical style)
//           if (_showCurrencyModal)
//             Center(
//               child: Container(
//                 color: Colors.black.withValues(alpha: 0.8),
//                 child: Center(
//                   child: Container(
//                     constraints: const BoxConstraints(maxWidth: 300),
//                     decoration: BoxDecoration(
//                       color: const Color(0xff1a1a1a),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Padding(
//                           padding: EdgeInsets.all(16.0),
//                           child: Text('Select Currency', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
//                         ),
//                         const Divider(color: Color(0xff808080)),
//                         Flexible(
//                           child: ListView.builder(
//                             shrinkWrap: true,
//                             itemCount: currencies.length,
//                             itemBuilder: (context, index) {
//                               final currency = currencies[index];
//                               final isSelected = _currency == currency['code'];
//                               return GestureDetector(
//                                 onTap: () => _handleCurrencyChange(currency),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     color: isSelected ? const Color(0xffFFD700).withValues(alpha: 0.1) : Colors.transparent,
//                                     border: isSelected
//                                         ? const Border(right: BorderSide(color: Color(0xffFFD700), width: 2))
//                                         : null,
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Text(currency['symbol'], style: const TextStyle(color: Color(0xffFFD700), fontSize: 32)),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: Text(
//                                           currency['name'],
//                                           style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
//                                         ),
//                                       ),
//                                       if (isSelected)
//                                         Container(
//                                           width: 8,
//                                           height: 8,
//                                           decoration: const BoxDecoration(color: Color(0xffFFD700), shape: BoxShape.circle),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         const Divider(color: Color(0xff808080)),
//                         TextButton(
//                           onPressed: () => setState(() => _showCurrencyModal = false),
//                           child: const Text('Cancel', style: TextStyle(color: Color(0xff808080))),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Personal Info Modal
//           if (_showProfileModal)
//             Center(
//               child: GestureDetector(
//                 onTap: () => setState(() => _showProfileModal = false),
//                 child: Container(
//                   color: Colors.black.withValues(alpha: 0.8),
//                   child: GestureDetector(
//                     onTap: () {}, // prevent closing
//                     child: Center(
//                       child: Container(
//                         constraints: const BoxConstraints(maxWidth: 300),
//                         decoration: BoxDecoration(
//                           color: const Color(0xff1a1a1a),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Text(
//                                 _isEditingProfile ? 'Edit Personal Info' : 'Personal Info',
//                                 style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
//                               ),
//                             ),
//                             const Divider(color: Color(0xff808080)),
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: _isEditingProfile
//                                   ? Column(
//                                       children: [
//                                         TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _ageController, decoration: const InputDecoration(labelText: 'Age', labelStyle: TextStyle(color: Color(0xff808080))), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         DropdownButtonFormField<String>(
//                                           initialValue: _selectedGender,
//                                           items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white)))).toList(),
//                                           onChanged: (val) => setState(() => _selectedGender = val),
//                                           decoration: const InputDecoration(labelText: 'Gender', labelStyle: TextStyle(color: Color(0xff808080))),
//                                           style: const TextStyle(color: Colors.white),
//                                           dropdownColor: const Color(0xff2a2a2a),
//                                         ),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _countryController, decoration: const InputDecoration(labelText: 'Country', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number (include country code)', labelStyle: TextStyle(color: Color(0xff808080))), keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white)),
//                                       ],
//                                     )
//                                   : Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: isProfileEmpty
//                                           ? [const Text('You have not provided any personal information yet.', style: TextStyle(color: Colors.white, fontSize: 16))]
//                                           : [
//                                               _buildInfoField('Name', _profileInfo?['name']),
//                                               _buildInfoField('Age', _profileInfo?['age']?.toString()),
//                                               _buildInfoField('Gender', _profileInfo?['gender']),
//                                               _buildInfoField('Country', _profileInfo?['country']),
//                                               _buildInfoField('Phone', _profileInfo?['phone']),
//                                             ],
//                                     ),
//                             ),
//                             const Divider(color: Color(0xff808080)),
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   if (_isEditingProfile)
//                                     TextButton(onPressed: () => setState(() => _isEditingProfile = false), child: const Text('Cancel', style: TextStyle(color: Color(0xff808080)))),
//                                   if (!_isEditingProfile)
//                                     TextButton(onPressed: () => setState(() => _showProfileModal = false), child: const Text('Close', style: TextStyle(color: Color(0xff808080)))),
//                                   if (_isEditingProfile)
//                                     TextButton(onPressed: _saveProfileInfo, child: const Text('Save', style: TextStyle(color: Color(0xffFFD700)))),
//                                   if (!_isEditingProfile)
//                                     TextButton(
//                                       onPressed: () => setState(() => _isEditingProfile = true),
//                                       child: Text(isProfileEmpty ? 'Add Info' : 'Edit', style: const TextStyle(color: Color(0xffFFD700))),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Financial Info Modal (identical structure)
//           if (_showFinancialModal)
//             Center(
//               child: GestureDetector(
//                 onTap: () => setState(() => _showFinancialModal = false),
//                 child: Container(
//                   color: Colors.black.withValues(alpha: 0.8),
//                   child: GestureDetector(
//                     onTap: () {},
//                     child: Center(
//                       child: Container(
//                         constraints: const BoxConstraints(maxWidth: 300),
//                         decoration: BoxDecoration(
//                           color: const Color(0xff1a1a1a),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Text(
//                                 _isEditingFinancial ? 'Edit Financial Info' : 'Financial Info',
//                                 style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
//                               ),
//                             ),
//                             const Divider(color: Color(0xff808080)),
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: _isEditingFinancial
//                                   ? Column(
//                                       children: [
//                                         TextField(controller: _bankController, decoration: const InputDecoration(labelText: 'Bank', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _ibanController, decoration: const InputDecoration(labelText: 'IBAN', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _accountNameController, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _swiftController, decoration: const InputDecoration(labelText: 'SWIFT', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _walletController, decoration: const InputDecoration(labelText: 'Wallet', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _financialCountryController, decoration: const InputDecoration(labelText: 'Country', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                       ],
//                                     )
//                                   : Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: isBankingEmpty
//                                           ? [const Text('You have not provided any financial information yet.', style: TextStyle(color: Colors.white, fontSize: 16))]
//                                           : [
//                                               _buildInfoField('Bank', _bankingInfo?['bank']),
//                                               _buildInfoField('IBAN', _bankingInfo?['iban']),
//                                               _buildInfoField('Name', _bankingInfo?['name']),
//                                               _buildInfoField('SWIFT', _bankingInfo?['swift']),
//                                               _buildInfoField('Wallet', _bankingInfo?['wallet']),
//                                               _buildInfoField('Country', _bankingInfo?['country']),
//                                             ],
//                                     ),
//                             ),
//                             const Divider(color: Color(0xff808080)),
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   if (_isEditingFinancial)
//                                     TextButton(onPressed: () => setState(() => _isEditingFinancial = false), child: const Text('Cancel', style: TextStyle(color: Color(0xff808080)))),
//                                   if (!_isEditingFinancial)
//                                     TextButton(onPressed: () => setState(() => _showFinancialModal = false), child: const Text('Close', style: TextStyle(color: Color(0xff808080)))),
//                                   if (_isEditingFinancial)
//                                     TextButton(onPressed: _saveFinancialInfo, child: const Text('Save', style: TextStyle(color: Color(0xffFFD700)))),
//                                   if (!_isEditingFinancial)
//                                     TextButton(
//                                       onPressed: () => setState(() => _isEditingFinancial = true),
//                                       child: Text(isBankingEmpty ? 'Add Info' : 'Edit', style: const TextStyle(color: Color(0xffFFD700))),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//   Widget _buildInfoField(String label, String? value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Color(0xff808080), fontSize: 12),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value != null && value.isNotEmpty ? value : 'Not set',
//             style: const TextStyle(color: Colors.white, fontSize: 16),
//           ),
//           const Divider(color: Color(0xff2a2a2a)),
//         ],
//       ),
//     );
//   }
// }












































// // lib/screens/profile_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:provider/provider.dart';
// import '../providers/app_state.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   String _language = 'en';
//   String _currency = 'usd';
//   bool _notificationsEnabled = true;
//   bool _emailUpdates = false;
//   String? _userId;
//   String? _email;
//   double _balance = 0.0;

//   Map<String, dynamic>? _profileInfo;
//   Map<String, dynamic>? _bankingInfo;

//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _ageController = TextEditingController();
//   final TextEditingController _countryController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   String? _selectedGender;

//   final List<String> _genders = [
//     'Male',
//     'Female',
//     'Other',
//     'Prefer not to say',
//   ];

//   // Financial info
//   final TextEditingController _bankController = TextEditingController();
//   final TextEditingController _ibanController = TextEditingController();
//   final TextEditingController _accountNameController = TextEditingController();
//   final TextEditingController _swiftController = TextEditingController();
//   final TextEditingController _walletController = TextEditingController();
//   final TextEditingController _financialCountryController = TextEditingController();

//   bool _showLanguageModal = false;
//   bool _showCurrencyModal = false;
//   bool _showProfileModal = false;
//   bool _showFinancialModal = false;
//   bool _isEditingProfile = false;
//   bool _isEditingFinancial = false;

//   final List<Map<String, dynamic>> languages = [
//     {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'rtl': false},
//     {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'rtl': true},
//     {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳', 'rtl': false},
//     {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'rtl': false},
//     {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'rtl': false},
//     {'code': 'zh', 'name': '中文', 'flag': '🇨🇳', 'rtl': false},
//   ];

//   final List<Map<String, dynamic>> currencies = [
//     {'code': 'usd', 'name': 'US Dollar', 'symbol': '\$'},
//     {'code': 'eur', 'name': 'Euro', 'symbol': '€'},
//   ];

//   late Map<String, dynamic> selectedCurrencyMap;

//   @override
//   void initState() {
//     super.initState();
//     selectedCurrencyMap = currencies[0];
//     _loadProfile();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     final user = Supabase.instance.client.auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _userId = user.id;
//         _email = user.email;
//       });
//       _balance = Provider.of<AppState>(context, listen: false).balance;
//     }
//   }

//   Future<void> _loadProfile() async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;

//     final data = await Supabase.instance.client
//         .from('profiles')
//         .select('language, currency, profile_info, banking_info')
//         .eq('id', userId)
//         .single();

//     setState(() {
//       _language = data['language'] ?? 'en';
//       _currency = data['currency'] ?? 'usd';
//       selectedCurrencyMap = currencies.firstWhere(
//         (c) => c['code'] == _currency,
//         orElse: () => currencies[0],
//       );
//       _profileInfo = data['profile_info'] ?? {};
//       _bankingInfo = data['banking_info'] ?? {};
//     });
//   }

//   Future<void> _updateLanguage(String newLang) async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;

//     await Supabase.instance.client
//         .from('profiles')
//         .update({'language': newLang})
//         .eq('id', userId);

//     setState(() => _language = newLang);

//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Language changed to $newLang')),
//     );
//   }

//   Future<void> _updateCurrency(String newCurr) async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;

//     await Supabase.instance.client
//         .from('profiles')
//         .update({'currency': newCurr})
//         .eq('id', userId);

//     setState(() {
//       _currency = newCurr;
//       selectedCurrencyMap = currencies.firstWhere((c) => c['code'] == newCurr);
//     });

//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Currency changed to ${newCurr.toUpperCase()}')),
//     );
//   }

//   Future<void> _updateProfileInfo(Map<String, dynamic> info) async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;
//     await Supabase.instance.client
//         .from('profiles')
//         .update({'profile_info': info})
//         .eq('id', userId);
//     setState(() => _profileInfo = info);
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile info updated')));
//   }

//   Future<void> _updateBankingInfo(Map<String, dynamic> info) async {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;
//     await Supabase.instance.client
//         .from('profiles')
//         .update({'banking_info': info})
//         .eq('id', userId);
//     setState(() => _bankingInfo = info);
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Financial info updated')));
//   }

//   void _handleLanguageChange(Map<String, dynamic> language) {
//     _updateLanguage(language['code']).then((_) {
//       if (mounted) {
//         setState(() => _showLanguageModal = false);
//       }
//     });
//   }

//   void _handleCurrencyChange(Map<String, dynamic> currency) {
//     _updateCurrency(currency['code']).then((_) {
//       if (mounted) {
//         setState(() => _showCurrencyModal = false);
//       }
//     });
//   }

//   void _handleCopyUserId() {
//     if (_userId != null) {
//       Clipboard.setData(ClipboardData(text: _userId!));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('User ID copied to clipboard!')),
//       );
//     }
//   }

//   void _handleLogout() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Logout'),
//         content: const Text('Are you sure you want to logout?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           TextButton(
//             onPressed: () async {
//               await Supabase.instance.client.auth.signOut();
//               if (context.mounted) {
//                 Navigator.pushReplacementNamed(context, '/login');
//               }
//             },
//             child: const Text('Yes'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _openProfileModal() {
//     _nameController.text = _profileInfo?['name'] ?? '';
//     _ageController.text = _profileInfo?['age']?.toString() ?? '';
//     _countryController.text = _profileInfo?['country'] ?? '';
//     _phoneController.text = _profileInfo?['phone'] ?? '';
//     _selectedGender = _profileInfo?['gender'];
//     setState(() => _showProfileModal = true);
//   }

//   void _saveProfileInfo() async {
//     final ageStr = _ageController.text.trim();
//     int? age = ageStr.isNotEmpty ? int.tryParse(ageStr) : null;
//     if (ageStr.isNotEmpty && age == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid age')));
//       return;
//     }
//     final info = <String, dynamic>{
//       'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
//       'age': age,
//       'gender': _selectedGender,
//       'country': _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
//       'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
//     }..removeWhere((key, value) => value == null);

//     await _updateProfileInfo(info);
//     setState(() => _isEditingProfile = false);
//   }

//   void _openFinancialModal() {
//     _bankController.text = _bankingInfo?['bank'] ?? '';
//     _ibanController.text = _bankingInfo?['iban'] ?? '';
//     _accountNameController.text = _bankingInfo?['name'] ?? '';
//     _swiftController.text = _bankingInfo?['swift'] ?? '';
//     _walletController.text = _bankingInfo?['wallet'] ?? '';
//     _financialCountryController.text = _bankingInfo?['country'] ?? '';
//     setState(() => _showFinancialModal = true);
//   }

//   void _saveFinancialInfo() async {
//     final info = <String, dynamic>{
//       'bank': _bankController.text.trim().isNotEmpty ? _bankController.text.trim() : null,
//       'iban': _ibanController.text.trim().isNotEmpty ? _ibanController.text.trim() : null,
//       'name': _accountNameController.text.trim().isNotEmpty ? _accountNameController.text.trim() : null,
//       'swift': _swiftController.text.trim().isNotEmpty ? _swiftController.text.trim() : null,
//       'wallet': _walletController.text.trim().isNotEmpty ? _walletController.text.trim() : null,
//       'country': _financialCountryController.text.trim().isNotEmpty ? _financialCountryController.text.trim() : null,
//     }..removeWhere((key, value) => value == null);

//     await _updateBankingInfo(info);
//     setState(() => _isEditingFinancial = false);
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _ageController.dispose();
//     _countryController.dispose();
//     _phoneController.dispose();
//     _bankController.dispose();
//     _ibanController.dispose();
//     _accountNameController.dispose();
//     _swiftController.dispose();
//     _walletController.dispose();
//     _financialCountryController.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final selectedLangName = languages.firstWhere(
//       (lang) => lang['code'] == _language,
//       orElse: () => languages[0],
//     )['name'];

//     final bool isProfileEmpty = _profileInfo?.isEmpty ?? true;
//     final bool isBankingEmpty = _bankingInfo?.isEmpty ?? true;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           ListView(
//             children: [
//               // Profile Header
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [Color(0xff1a1a1a), Color(0xff2a2a2a)],
//                     begin: Alignment.centerLeft,
//                     end: Alignment.centerRight,
//                   ),
//                   border: Border(bottom: BorderSide(color: Color(0xff808080))),
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           width: 80,
//                           height: 80,
//                           decoration: const BoxDecoration(
//                             color: Color(0xffFFD700),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Center(
//                             child: Text(
//                               _userId?.substring(0, 2).toUpperCase() ?? 'U',
//                               style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text('Welcome back!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
//                               const SizedBox(height: 4),
//                               Text(_email ?? '', style: const TextStyle(color: Color(0xff808080), fontSize: 12)),
//                               const SizedBox(height: 8),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       'ID: ${_userId ?? ''}',
//                                       style: const TextStyle(color: Color(0xff808080), fontSize: 12),
//                                       overflow: TextOverflow.ellipsis,
//                                       maxLines: 1,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   IconButton(
//                                     onPressed: _handleCopyUserId,
//                                     icon: const Icon(Icons.copy, size: 16, color: Color(0xffFFD700)),
//                                     padding: EdgeInsets.zero,
//                                     constraints: const BoxConstraints(),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: [
//                         Column(
//                           children: [
//                             Text(
//                               '${selectedCurrencyMap['symbol']}${_balance.toStringAsFixed(2)}',
//                               style: const TextStyle(color: Color(0xffFFD700), fontSize: 20, fontWeight: FontWeight.bold),
//                             ),
//                             const Text('REGT Balance', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
//                           ],
//                         ),
//                         Column(
//                           children: const [
//                             Text('5', style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
//                             Text('Referrals', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
//                           ],
//                         ),
//                         Column(
//                           children: const [
//                             Text('28', style: TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
//                             Text('Days Active', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               // Settings Sections
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Personal Info & Financial Info buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: GestureDetector(
//                             onTap: _openProfileModal,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xff1a1a1a),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(color: const Color(0xff808080)),
//                               ),
//                               child: const Padding(
//                                 padding: EdgeInsets.all(16.0),
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.person, color: Color(0xffFFD700), size: 20),
//                                     SizedBox(width: 12),
//                                     Expanded(
//                                       child: Text('Personal Info', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                     ),
//                                     Icon(Icons.chevron_right, color: Color(0xff808080)),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: GestureDetector(
//                             onTap: _openFinancialModal,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xff1a1a1a),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(color: const Color(0xff808080)),
//                               ),
//                               child: const Padding(
//                                 padding: EdgeInsets.all(16.0),
//                                 child: Row(
//                                   children: [
//                                     Icon(Icons.account_balance_wallet, color: Color(0xffFFD700), size: 20),
//                                     SizedBox(width: 12),
//                                     Expanded(
//                                       child: Text('Financial Info', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                     ),
//                                     Icon(Icons.chevron_right, color: Color(0xff808080)),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Language Selector
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xff1a1a1a),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: const Color(0xff808080)),
//                       ),
//                       child: GestureDetector(
//                         onTap: () => setState(() => _showLanguageModal = true),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.language, color: Color(0xffFFD700), size: 20),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Text('Language', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                     const SizedBox(height: 4),
//                                     Text(selectedLangName, style: const TextStyle(color: Color(0xff808080), fontSize: 14)),
//                                   ],
//                                 ),
//                               ),
//                               const Icon(Icons.chevron_right, color: Color(0xff808080)),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // CURRENCY SELECTOR - EXACTLY SAME STYLE
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xff1a1a1a),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: const Color(0xff808080)),
//                       ),
//                       child: GestureDetector(
//                         onTap: () => setState(() => _showCurrencyModal = true),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Row(
//                             children: [
//                               const Icon(Icons.currency_exchange, color: Color(0xffFFD700), size: 20),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Text('Currency', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       '${selectedCurrencyMap['name']} (${selectedCurrencyMap['symbol']})',
//                                       style: const TextStyle(color: Color(0xff808080), fontSize: 14),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const Icon(Icons.chevron_right, color: Color(0xff808080)),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // Notification Settings
//                     Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xff1a1a1a),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: const Color(0xff808080)),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 const Icon(Icons.notifications, color: Color(0xffFFD700), size: 20),
//                                 const SizedBox(width: 12),
//                                 const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 const Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text('Push Notifications', style: TextStyle(color: Colors.white, fontSize: 14)),
//                                     Text('Receive push notifications', style: TextStyle(color: Color(0xff808080), fontSize: 12)),
//                                   ],
//                                 ),
//                                 Switch(
//                                   value: _notificationsEnabled,
//                                   onChanged: (val) => setState(() => _notificationsEnabled = val),
//                                   activeThumbColor: const Color(0xffFFD700),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 const Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text('Email Updates', style: TextStyle(color: Colors.white, fontSize: 14)),
//                                     Text('Receive news & offers', style: TextStyle(color: Color(0xff808080), fontSize: 12)),
//                                   ],
//                                 ),
//                                 Switch(
//                                   value: _emailUpdates,
//                                   onChanged: (val) => setState(() => _emailUpdates = val),
//                                   activeThumbColor: const Color(0xffFFD700),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     // Logout Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _handleLogout,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.redAccent,
//                           padding: const EdgeInsets.symmetric(vertical: 18),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                         ),
//                         child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//                       ),
//                     ),

//                     const SizedBox(height: 40),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           // Language Modal
//           if (_showLanguageModal)
//             Center(
//               child: Container(
//                 color: Colors.black.withValues(alpha: 0.8),
//                 child: Center(
//                   child: Container(
//                     constraints: const BoxConstraints(maxWidth: 300),
//                     decoration: BoxDecoration(
//                       color: const Color(0xff1a1a1a),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Padding(
//                           padding: EdgeInsets.all(16.0),
//                           child: Text('Select Language', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
//                         ),
//                         const Divider(color: Color(0xff808080)),
//                         Flexible(
//                           child: ListView.builder(
//                             shrinkWrap: true,
//                             itemCount: languages.length,
//                             itemBuilder: (context, index) {
//                               final language = languages[index];
//                               final isSelected = _language == language['code'];
//                               return GestureDetector(
//                                 onTap: () => _handleLanguageChange(language),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     color: isSelected ? const Color(0xffFFD700).withValues(alpha: 0.1) : Colors.transparent,
//                                     border: isSelected
//                                         ? const Border(right: BorderSide(color: Color(0xffFFD700), width: 2))
//                                         : null,
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Text(language['flag'], style: const TextStyle(fontSize: 24)),
//                                       const SizedBox(width: 12),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             Text(language['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
//                                             if (language['rtl']) const Text('RTL Support', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
//                                           ],
//                                         ),
//                                       ),
//                                       if (isSelected)
//                                         Container(
//                                           width: 8,
//                                           height: 8,
//                                           decoration: const BoxDecoration(color: Color(0xffFFD700), shape: BoxShape.circle),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         const Divider(color: Color(0xff808080)),
//                         TextButton(
//                           onPressed: () => setState(() => _showLanguageModal = false),
//                           child: const Text('Cancel', style: TextStyle(color: Color(0xff808080))),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Currency Modal (identical style)
//           if (_showCurrencyModal)
//             Center(
//               child: Container(
//                 color: Colors.black.withValues(alpha: 0.8),
//                 child: Center(
//                   child: Container(
//                     constraints: const BoxConstraints(maxWidth: 300),
//                     decoration: BoxDecoration(
//                       color: const Color(0xff1a1a1a),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Padding(
//                           padding: EdgeInsets.all(16.0),
//                           child: Text('Select Currency', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
//                         ),
//                         const Divider(color: Color(0xff808080)),
//                         Flexible(
//                           child: ListView.builder(
//                             shrinkWrap: true,
//                             itemCount: currencies.length,
//                             itemBuilder: (context, index) {
//                               final currency = currencies[index];
//                               final isSelected = _currency == currency['code'];
//                               return GestureDetector(
//                                 onTap: () => _handleCurrencyChange(currency),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     color: isSelected ? const Color(0xffFFD700).withValues(alpha: 0.1) : Colors.transparent,
//                                     border: isSelected
//                                         ? const Border(right: BorderSide(color: Color(0xffFFD700), width: 2))
//                                         : null,
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Text(currency['symbol'], style: const TextStyle(color: Color(0xffFFD700), fontSize: 32)),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: Text(
//                                           currency['name'],
//                                           style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
//                                         ),
//                                       ),
//                                       if (isSelected)
//                                         Container(
//                                           width: 8,
//                                           height: 8,
//                                           decoration: const BoxDecoration(color: Color(0xffFFD700), shape: BoxShape.circle),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                         const Divider(color: Color(0xff808080)),
//                         TextButton(
//                           onPressed: () => setState(() => _showCurrencyModal = false),
//                           child: const Text('Cancel', style: TextStyle(color: Color(0xff808080))),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Personal Info Modal
//           if (_showProfileModal)
//             Center(
//               child: GestureDetector(
//                 onTap: () => setState(() => _showProfileModal = false),
//                 child: Container(
//                   color: Colors.black.withValues(alpha: 0.8),
//                   child: GestureDetector(
//                     onTap: () {}, // prevent closing
//                     child: Center(
//                       child: Container(
//                         constraints: const BoxConstraints(maxWidth: 300),
//                         decoration: BoxDecoration(
//                           color: const Color(0xff1a1a1a),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Text(
//                                 _isEditingProfile ? 'Edit Personal Info' : 'Personal Info',
//                                 style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
//                               ),
//                             ),
//                             const Divider(color: Color(0xff808080)),
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: _isEditingProfile
//                                   ? Column(
//                                       children: [
//                                         TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _ageController, decoration: const InputDecoration(labelText: 'Age', labelStyle: TextStyle(color: Color(0xff808080))), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         DropdownButtonFormField<String>(
//                                           value: _selectedGender,
//                                           items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white)))).toList(),
//                                           onChanged: (val) => setState(() => _selectedGender = val),
//                                           decoration: const InputDecoration(labelText: 'Gender', labelStyle: TextStyle(color: Color(0xff808080))),
//                                           style: const TextStyle(color: Colors.white),
//                                           dropdownColor: const Color(0xff2a2a2a),
//                                         ),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _countryController, decoration: const InputDecoration(labelText: 'Country', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number (include country code)', labelStyle: TextStyle(color: Color(0xff808080))), keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white)),
//                                       ],
//                                     )
//                                   : Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: isProfileEmpty
//                                           ? [const Text('You have not provided any personal information yet.', style: TextStyle(color: Colors.white, fontSize: 16))]
//                                           : [
//                                               _buildInfoField('Name', _profileInfo?['name']),
//                                               _buildInfoField('Age', _profileInfo?['age']?.toString()),
//                                               _buildInfoField('Gender', _profileInfo?['gender']),
//                                               _buildInfoField('Country', _profileInfo?['country']),
//                                               _buildInfoField('Phone', _profileInfo?['phone']),
//                                             ],
//                                     ),
//                             ),
//                             const Divider(color: Color(0xff808080)),
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   if (_isEditingProfile)
//                                     TextButton(onPressed: () => setState(() => _isEditingProfile = false), child: const Text('Cancel', style: TextStyle(color: Color(0xff808080)))),
//                                   if (!_isEditingProfile)
//                                     TextButton(onPressed: () => setState(() => _showProfileModal = false), child: const Text('Close', style: TextStyle(color: Color(0xff808080)))),
//                                   if (_isEditingProfile)
//                                     TextButton(onPressed: _saveProfileInfo, child: const Text('Save', style: TextStyle(color: Color(0xffFFD700)))),
//                                   if (!_isEditingProfile)
//                                     TextButton(
//                                       onPressed: () => setState(() => _isEditingProfile = true),
//                                       child: Text(isProfileEmpty ? 'Add Info' : 'Edit', style: const TextStyle(color: Color(0xffFFD700))),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Financial Info Modal (identical structure)
//           if (_showFinancialModal)
//             Center(
//               child: GestureDetector(
//                 onTap: () => setState(() => _showFinancialModal = false),
//                 child: Container(
//                   color: Colors.black.withValues(alpha: 0.8),
//                   child: GestureDetector(
//                     onTap: () {},
//                     child: Center(
//                       child: Container(
//                         constraints: const BoxConstraints(maxWidth: 300),
//                         decoration: BoxDecoration(
//                           color: const Color(0xff1a1a1a),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: Text(
//                                 _isEditingFinancial ? 'Edit Financial Info' : 'Financial Info',
//                                 style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
//                               ),
//                             ),
//                             const Divider(color: Color(0xff808080)),
//                             Padding(
//                               padding: const EdgeInsets.all(16.0),
//                               child: _isEditingFinancial
//                                   ? Column(
//                                       children: [
//                                         TextField(controller: _bankController, decoration: const InputDecoration(labelText: 'Bank', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _ibanController, decoration: const InputDecoration(labelText: 'IBAN', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _accountNameController, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _swiftController, decoration: const InputDecoration(labelText: 'SWIFT', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _walletController, decoration: const InputDecoration(labelText: 'Wallet', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                         const SizedBox(height: 16),
//                                         TextField(controller: _financialCountryController, decoration: const InputDecoration(labelText: 'Country', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
//                                       ],
//                                     )
//                                   : Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: isBankingEmpty
//                                           ? [const Text('You have not provided any financial information yet.', style: TextStyle(color: Colors.white, fontSize: 16))]
//                                           : [
//                                               _buildInfoField('Bank', _bankingInfo?['bank']),
//                                               _buildInfoField('IBAN', _bankingInfo?['iban']),
//                                               _buildInfoField('Name', _bankingInfo?['name']),
//                                               _buildInfoField('SWIFT', _bankingInfo?['swift']),
//                                               _buildInfoField('Wallet', _bankingInfo?['wallet']),
//                                               _buildInfoField('Country', _bankingInfo?['country']),
//                                             ],
//                                     ),
//                             ),
//                             const Divider(color: Color(0xff808080)),
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                 children: [
//                                   if (_isEditingFinancial)
//                                     TextButton(onPressed: () => setState(() => _isEditingFinancial = false), child: const Text('Cancel', style: TextStyle(color: Color(0xff808080)))),
//                                   if (!_isEditingFinancial)
//                                     TextButton(onPressed: () => setState(() => _showFinancialModal = false), child: const Text('Close', style: TextStyle(color: Color(0xff808080)))),
//                                   if (_isEditingFinancial)
//                                     TextButton(onPressed: _saveFinancialInfo, child: const Text('Save', style: TextStyle(color: Color(0xffFFD700)))),
//                                   if (!_isEditingFinancial)
//                                     TextButton(
//                                       onPressed: () => setState(() => _isEditingFinancial = true),
//                                       child: Text(isBankingEmpty ? 'Add Info' : 'Edit', style: const TextStyle(color: Color(0xffFFD700))),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoField(String label, String? value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Color(0xff808080), fontSize: 12),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value != null && value.isNotEmpty ? value : 'Not set',
//             style: const TextStyle(color: Colors.white, fontSize: 16),
//           ),
//           const Divider(color: Color(0xff2a2a2a)),
//         ],
//       ),
//     );
//   }
// }




















// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _language = 'en';
  String _currency = 'usd';
  bool _notificationsEnabled = true;
  bool _emailUpdates = false;
  String? _userId;
  String? _email;
  double _balance = 0.0;

  Map<String, dynamic>? _profileInfo;
  Map<String, dynamic>? _bankingInfo;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedGender;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  // Financial info
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _swiftController = TextEditingController();
  final TextEditingController _walletController = TextEditingController();
  final TextEditingController _financialCountryController = TextEditingController();

  bool _showLanguageModal = false;
  bool _showCurrencyModal = false;
  bool _showProfileModal = false;
  bool _showFinancialModal = false;
  bool _isEditingProfile = false;
  bool _isEditingFinancial = false;

  final List<Map<String, dynamic>> languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'rtl': false},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦', 'rtl': true},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳', 'rtl': false},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷', 'rtl': false},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'rtl': false},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳', 'rtl': false},
  ];

  final List<Map<String, dynamic>> currencies = [
    {'code': 'usd', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'eur', 'name': 'Euro', 'symbol': '€'},
  ];

  late Map<String, dynamic> selectedCurrencyMap;

  @override
  void initState() {
    super.initState();
    selectedCurrencyMap = currencies[0];
    _loadProfile();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.id;
        _email = user.email;
      });
      _balance = Provider.of<AppState>(context, listen: false).balance;
    }
  }

  Future<void> _loadProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select('language, currency, profile_info, banking_info')
        .eq('id', userId)
        .single();

    setState(() {
      _language = data['language'] ?? 'en';
      _currency = data['currency'] ?? 'usd';
      selectedCurrencyMap = currencies.firstWhere(
        (c) => c['code'] == _currency,
        orElse: () => currencies[0],
      );
      _profileInfo = data['profile_info'] ?? {};
      _bankingInfo = data['banking_info'] ?? {};
    });
  }

  Future<void> _updateLanguage(String newLang) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({'language': newLang})
        .eq('id', userId);

    setState(() => _language = newLang);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language changed to $newLang')),
    );
  }

  Future<void> _updateCurrency(String newCurr) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client
        .from('profiles')
        .update({'currency': newCurr})
        .eq('id', userId);

    setState(() {
      _currency = newCurr;
      selectedCurrencyMap = currencies.firstWhere((c) => c['code'] == newCurr);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Currency changed to ${newCurr.toUpperCase()}')),
    );
  }

  Future<void> _updateProfileInfo(Map<String, dynamic> info) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'profile_info': info})
        .eq('id', userId);
    setState(() => _profileInfo = info);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile info updated')));
  }

  Future<void> _updateBankingInfo(Map<String, dynamic> info) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client
        .from('profiles')
        .update({'banking_info': info})
        .eq('id', userId);
    setState(() => _bankingInfo = info);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Financial info updated')));
  }

  void _handleLanguageChange(Map<String, dynamic> language) {
    _updateLanguage(language['code']).then((_) {
      if (mounted) {
        setState(() => _showLanguageModal = false);
      }
    });
  }

  void _handleCurrencyChange(Map<String, dynamic> currency) {
    _updateCurrency(currency['code']).then((_) {
      if (mounted) {
        setState(() => _showCurrencyModal = false);
      }
    });
  }

  void _handleCopyUserId() {
    if (_userId != null) {
      Clipboard.setData(ClipboardData(text: _userId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID copied to clipboard!')),
      );
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _openProfileModal() {
    _nameController.text = _profileInfo?['name'] ?? '';
    _ageController.text = _profileInfo?['age']?.toString() ?? '';
    _countryController.text = _profileInfo?['country'] ?? '';
    _phoneController.text = _profileInfo?['phone'] ?? '';
    _selectedGender = _profileInfo?['gender'];
    setState(() => _showProfileModal = true);
  }

  void _saveProfileInfo() async {
    final ageStr = _ageController.text.trim();
    int? age = ageStr.isNotEmpty ? int.tryParse(ageStr) : null;
    if (ageStr.isNotEmpty && age == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid age')));
      return;
    }
    final info = <String, dynamic>{
      'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
      'age': age,
      'gender': _selectedGender,
      'country': _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    }..removeWhere((key, value) => value == null);

    await _updateProfileInfo(info);
    setState(() => _isEditingProfile = false);
  }

  void _openFinancialModal() {
    _bankController.text = _bankingInfo?['bank'] ?? '';
    _ibanController.text = _bankingInfo?['iban'] ?? '';
    _accountNameController.text = _bankingInfo?['name'] ?? '';
    _swiftController.text = _bankingInfo?['swift'] ?? '';
    _walletController.text = _bankingInfo?['wallet'] ?? '';
    _financialCountryController.text = _bankingInfo?['country'] ?? '';
    setState(() => _showFinancialModal = true);
  }

  void _saveFinancialInfo() async {
    final info = <String, dynamic>{
      'bank': _bankController.text.trim().isNotEmpty ? _bankController.text.trim() : null,
      'iban': _ibanController.text.trim().isNotEmpty ? _ibanController.text.trim() : null,
      'name': _accountNameController.text.trim().isNotEmpty ? _accountNameController.text.trim() : null,
      'swift': _swiftController.text.trim().isNotEmpty ? _swiftController.text.trim() : null,
      'wallet': _walletController.text.trim().isNotEmpty ? _walletController.text.trim() : null,
      'country': _financialCountryController.text.trim().isNotEmpty ? _financialCountryController.text.trim() : null,
    }..removeWhere((key, value) => value == null);

    await _updateBankingInfo(info);
    setState(() => _isEditingFinancial = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _bankController.dispose();
    _ibanController.dispose();
    _accountNameController.dispose();
    _swiftController.dispose();
    _walletController.dispose();
    _financialCountryController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedLangName = languages.firstWhere(
      (lang) => lang['code'] == _language,
      orElse: () => languages[0],
    )['name'];

    final bool isProfileEmpty = _profileInfo?.isEmpty ?? true;
    final bool isBankingEmpty = _bankingInfo?.isEmpty ?? true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ListView(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff1a1a1a), Color(0xff2a2a2a)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xff808080))),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xffFFD700),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _userId?.substring(0, 2).toUpperCase() ?? 'U',
                              style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome back!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_email ?? '', style: const TextStyle(color: Color(0xff808080), fontSize: 12)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'ID: ${_userId ?? ''}',
                                      style: const TextStyle(color: Color(0xff808080), fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: _handleCopyUserId,
                                    icon: const Icon(Icons.copy, size: 16, color: Color(0xffFFD700)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${selectedCurrencyMap['symbol']}${_balance.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xffFFD700), fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const Text('REGT Balance', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
                          ],
                        ),
                        Column(
                          children: const [
                            Text('5', style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Referrals', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
                          ],
                        ),
                        Column(
                          children: const [
                            Text('28', style: TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Days Active', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Settings Sections
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Info & Financial Info buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _openProfileModal,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xff1a1a1a),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xff808080)),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: Color(0xffFFD700), size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text('Personal Info', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                    ),
                                    Icon(Icons.chevron_right, color: Color(0xff808080)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openFinancialModal,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xff1a1a1a),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xff808080)),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, color: Color(0xffFFD700), size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text('Financial Info', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                    ),
                                    Icon(Icons.chevron_right, color: Color(0xff808080)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Language Selector
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xff808080)),
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _showLanguageModal = true),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.language, color: Color(0xffFFD700), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Language', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(selectedLangName, style: const TextStyle(color: Color(0xff808080), fontSize: 14)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Color(0xff808080)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CURRENCY SELECTOR - EXACTLY SAME STYLE
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xff808080)),
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _showCurrencyModal = true),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.currency_exchange, color: Color(0xffFFD700), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Currency', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${selectedCurrencyMap['name']} (${selectedCurrencyMap['symbol']})',
                                      style: const TextStyle(color: Color(0xff808080), fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Color(0xff808080)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notification Settings
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff1a1a1a),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xff808080)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notifications, color: Color(0xffFFD700), size: 20),
                                const SizedBox(width: 12),
                                const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Push Notifications', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    Text('Receive push notifications', style: TextStyle(color: Color(0xff808080), fontSize: 12)),
                                  ],
                                ),
                                Switch(
                                  value: _notificationsEnabled,
                                  onChanged: (val) => setState(() => _notificationsEnabled = val),
                                  activeThumbColor: const Color(0xffFFD700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Email Updates', style: TextStyle(color: Colors.white, fontSize: 14)),
                                    Text('Receive news & offers', style: TextStyle(color: Color(0xff808080), fontSize: 12)),
                                  ],
                                ),
                                Switch(
                                  value: _emailUpdates,
                                  onChanged: (val) => setState(() => _emailUpdates = val),
                                  activeThumbColor: const Color(0xffFFD700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),

          // Language Modal
          if (_showLanguageModal)
            Center(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: const Color(0xff1a1a1a),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Select Language', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                        const Divider(color: Color(0xff808080)),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: languages.length,
                            itemBuilder: (context, index) {
                              final language = languages[index];
                              final isSelected = _language == language['code'];
                              return GestureDetector(
                                onTap: () => _handleLanguageChange(language),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xffFFD700).withValues(alpha: 0.1) : Colors.transparent,
                                    border: isSelected
                                        ? const Border(right: BorderSide(color: Color(0xffFFD700), width: 2))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(language['flag'], style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(language['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                            if (language['rtl']) const Text('RTL Support', style: TextStyle(color: Color(0xff808080), fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: Color(0xffFFD700), shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(color: Color(0xff808080)),
                        TextButton(
                          onPressed: () => setState(() => _showLanguageModal = false),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xff808080))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Currency Modal (identical style)
          if (_showCurrencyModal)
            Center(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: const Color(0xff1a1a1a),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Select Currency', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                        const Divider(color: Color(0xff808080)),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: currencies.length,
                            itemBuilder: (context, index) {
                              final currency = currencies[index];
                              final isSelected = _currency == currency['code'];
                              return GestureDetector(
                                onTap: () => _handleCurrencyChange(currency),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xffFFD700).withValues(alpha: 0.1) : Colors.transparent,
                                    border: isSelected
                                        ? const Border(right: BorderSide(color: Color(0xffFFD700), width: 2))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(currency['symbol'], style: const TextStyle(color: Color(0xffFFD700), fontSize: 32)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          currency['name'],
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: Color(0xffFFD700), shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(color: Color(0xff808080)),
                        TextButton(
                          onPressed: () => setState(() => _showCurrencyModal = false),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xff808080))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Personal Info Modal
          if (_showProfileModal)
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _showProfileModal = false),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: GestureDetector(
                    onTap: () {}, // prevent closing
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: const Color(0xff1a1a1a),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _isEditingProfile ? 'Edit Personal Info' : 'Personal Info',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Divider(color: Color(0xff808080)),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _isEditingProfile
                                  ? Column(
                                      children: [
                                        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 16),
                                        TextField(controller: _ageController, decoration: const InputDecoration(labelText: 'Age', labelStyle: TextStyle(color: Color(0xff808080))), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<String>(
                                          initialValue: _selectedGender,
                                          items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: Colors.white)))).toList(),
                                          onChanged: (val) => setState(() => _selectedGender = val),
                                          decoration: const InputDecoration(labelText: 'Gender', labelStyle: TextStyle(color: Color(0xff808080))),
                                          style: const TextStyle(color: Colors.white),
                                          dropdownColor: const Color(0xff2a2a2a),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(controller: _countryController, decoration: const InputDecoration(labelText: 'Country', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 16),
                                        TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number (include country code)', labelStyle: TextStyle(color: Color(0xff808080))), keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white)),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: isProfileEmpty
                                          ? [const Text('You have not provided any personal information yet.', style: TextStyle(color: Colors.white, fontSize: 16))]
                                          : [
                                              _buildInfoField('Name', _profileInfo?['name']),
                                              _buildInfoField('Age', _profileInfo?['age']?.toString()),
                                              _buildInfoField('Gender', _profileInfo?['gender']),
                                              _buildInfoField('Country', _profileInfo?['country']),
                                              _buildInfoField('Phone', _profileInfo?['phone']),
                                            ],
                                    ),
                            ),
                            const Divider(color: Color(0xff808080)),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (_isEditingProfile)
                                    TextButton(onPressed: () => setState(() => _isEditingProfile = false), child: const Text('Cancel', style: TextStyle(color: Color(0xff808080)))),
                                  if (!_isEditingProfile)
                                    TextButton(onPressed: () => setState(() => _showProfileModal = false), child: const Text('Close', style: TextStyle(color: Color(0xff808080)))),
                                  if (_isEditingProfile)
                                    TextButton(onPressed: _saveProfileInfo, child: const Text('Save', style: TextStyle(color: Color(0xffFFD700)))),
                                  if (!_isEditingProfile)
                                    TextButton(
                                      onPressed: () => setState(() => _isEditingProfile = true),
                                      child: Text(isProfileEmpty ? 'Add Info' : 'Edit', style: const TextStyle(color: Color(0xffFFD700))),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Financial Info Modal (identical structure)
          if (_showFinancialModal)
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _showFinancialModal = false),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: GestureDetector(
                    onTap: () {},
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: const Color(0xff1a1a1a),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffFFD700).withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _isEditingFinancial ? 'Edit Financial Info' : 'Financial Info',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Divider(color: Color(0xff808080)),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _isEditingFinancial
                                  ? Column(
                                      children: [
                                        TextField(controller: _bankController, decoration: const InputDecoration(labelText: 'Bank', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 16),
                                        TextField(controller: _ibanController, decoration: const InputDecoration(labelText: 'IBAN', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 16),
                                        TextField(controller: _accountNameController, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 16),
                                        TextField(controller: _swiftController, decoration: const InputDecoration(labelText: 'SWIFT', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 16),
                                        TextField(controller: _walletController, decoration: const InputDecoration(labelText: 'Wallet', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 16),
                                        TextField(controller: _financialCountryController, decoration: const InputDecoration(labelText: 'Country', labelStyle: TextStyle(color: Color(0xff808080))), style: const TextStyle(color: Colors.white)),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: isBankingEmpty
                                          ? [const Text('You have not provided any financial information yet.', style: TextStyle(color: Colors.white, fontSize: 16))]
                                          : [
                                              _buildInfoField('Bank', _bankingInfo?['bank']),
                                              _buildInfoField('IBAN', _bankingInfo?['iban']),
                                              _buildInfoField('Name', _bankingInfo?['name']),
                                              _buildInfoField('SWIFT', _bankingInfo?['swift']),
                                              _buildInfoField('Wallet', _bankingInfo?['wallet']),
                                              _buildInfoField('Country', _bankingInfo?['country']),
                                            ],
                                    ),
                            ),
                            const Divider(color: Color(0xff808080)),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (_isEditingFinancial)
                                    TextButton(onPressed: () => setState(() => _isEditingFinancial = false), child: const Text('Cancel', style: TextStyle(color: Color(0xff808080)))),
                                  if (!_isEditingFinancial)
                                    TextButton(onPressed: () => setState(() => _showFinancialModal = false), child: const Text('Close', style: TextStyle(color: Color(0xff808080)))),
                                  if (_isEditingFinancial)
                                    TextButton(onPressed: _saveFinancialInfo, child: const Text('Save', style: TextStyle(color: Color(0xffFFD700)))),
                                  if (!_isEditingFinancial)
                                    TextButton(
                                      onPressed: () => setState(() => _isEditingFinancial = true),
                                      child: Text(isBankingEmpty ? 'Add Info' : 'Edit', style: const TextStyle(color: Color(0xffFFD700))),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xff808080), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value != null && value.isNotEmpty ? value : 'Not set',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Divider(color: Color(0xff2a2a2a)),
        ],
      ),
    );
  }
}