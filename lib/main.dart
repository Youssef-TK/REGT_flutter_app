
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:regt_app/providers/app_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/ads_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/withdrawal_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'screens/reset_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ← NEW
import 'screens/post_login_setup_screen.dart';

// Global navigator key for navigation outside of widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) async {
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (e) {
      debugPrint('Deep-link error: $e');
    }
    });

  
  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final event = data.event;
    final session = data.session;

    // Handle global auth events that should always trigger (even if another listener already ran)
    if (event == AuthChangeEvent.signedOut) {
      debugPrint('Signed out');
      navigatorKey.currentState?.pushReplacementNamed('/login');
      return;
    }

    if (event == AuthChangeEvent.passwordRecovery) {
      debugPrint('Password recovery');
      navigatorKey.currentState?.pushNamed('/reset-password');
      return;
    }

    // Only handle sign-in events from here
    if (event == AuthChangeEvent.signedIn && session != null) {
      debugPrint('Signed in: ${session.user.email}');

      final userId = session.user.id;


      try {
        debugPrint('checking referral...');
        final response = await Supabase.instance.client
            .from('referrals')
            .select(
              'referrer_id, profiles!referrer_id(email)',
            ) // fixed join syntax
            .eq('referred_id', userId)
            .maybeSingle();

        if (response == null) {
         
          debugPrint('no referral...');
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (_) => const ReferredWelcomeScreen(
                referrerCode: 'WELCOME',
                referrerEmail: 'the community', // or whatever you prefer
              ),
            ),
          );
        } else {
         
          debugPrint('has referral...');
          final referrerEmail = response['profiles']?['email'] ?? 'unknown';
          debugPrint('User was referred by: $referrerEmail');

          navigatorKey.currentState?.pushReplacementNamed('/home');
        }
      } catch (e) {
        debugPrint('Error checking referral: $e');
       
        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    }
  });

  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REGT Token Earning App',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white)),
      ),
      navigatorKey: navigatorKey,
      home: const LauncherPage(), // ← CHANGED: now goes through launcher first
      routes: {
        '/home': (_) => const HomeScreen(),
        '/ads': (_) => const AdsScreen(),
        '/withdrawal': (_) => const WithdrawalScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/reset-password': (_) => const ResetPasswordScreen(),
        '/login': (_) => const LoginScreen(),
        '/post-login-setup': (_) =>
            ReferredWelcomeScreen(referrerCode: '', referrerEmail: ''),
      },
    );
  }
}

class LauncherPage extends StatelessWidget {
  const LauncherPage({super.key});

  Future<bool> _hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenOnboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            // Already seen → go straight to normal auth wrapper
            return const _AuthWrapper();
          } else {
            // First time ever → show onboarding
            return const OnboardingScreen();
          }
        }

        // While checking prefs, show loading
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          ),
        );
      },
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Colors.black],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // You can put a logo/image here later
                const Text(
                  "Welcome to\nREGT Token",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Earn tokens daily by watching ads,\ncompleting tasks and inviting friends.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 80),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('hasSeenOnboarding', true);

                      if (context.mounted) {
                        // Go to normal flow (login or home depending on session)
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const _AuthWrapper(),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "GET STARTED",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }


  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      setState(() => _checking = false);
      navigatorKey.currentState?.pushReplacementNamed('/login');
      return;
    }

    final userId = session.user.id;

    try {
      debugPrint('checking referral in initial session...');
      final response = await Supabase.instance.client
          .from('referrals')
          .select('referrer_id, profiles!referrer_id(email)')
          .eq('referred_id', userId)
          .maybeSingle();

      if (!mounted) return;

      setState(() => _checking = false);

      if (response == null) {
        debugPrint('no referral...');
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ReferredWelcomeScreen(
              referrerCode: 'WELCOME',
              referrerEmail: 'the community',
            ),
          ),
        );
      } else {
        debugPrint('has referral...');
        final referrerEmail = response['profiles']?['email'] ?? 'unknown';
        debugPrint('User was referred by: $referrerEmail');

        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    } catch (e) {
      debugPrint('Error checking referral: $e');
      if (!mounted) return;
      setState(() => _checking = false);
      navigatorKey.currentState?.pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
