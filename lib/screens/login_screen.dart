
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _storage = FlutterSecureStorage();
  bool _isLoading = false;
  bool isLogin = true;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool showForgotPassword = false;
  String? formError;

  bool validateEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  Future<void> handleSubmit() async {
    setState(() {
      formError = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty ||
        password.isEmpty ||
        (!isLogin && confirmPassword.isEmpty)) {
      setState(() {
        formError = 'Please fill in all fields';
      });
      _isLoading = false;
      return;
    }

    if (!validateEmail(email)) {
      setState(() {
        formError = 'Please enter a valid email address';
      });
      _isLoading = false;
      return;
    }

    if (password.length < 6) {
      setState(() {
        formError = 'Password must be at least 6 characters';
      });
      _isLoading = false;
      return;
    }

    if (!isLogin && password != confirmPassword) {
      setState(() {
        formError = 'Passwords do not match';
      });
      _isLoading = false;
      return;
    }

    if (isLogin) {
      await _signIn();
    } else {
      await _signUp();
    }
  }

  Future<void> _signUp() async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: 'com.primesoftworks.regtapp://auth/confirm',
      );

      if (response.user != null) {
        if (response.session != null) {
          // Confirmation is off: Immediate login
          await _saveSession(response.session!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign-up successful! Welcome!')),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // Confirmation is on: User created, but needs email verification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sign-up successful! Check your email to confirm.',
                ),
              ),
            );
            // Optionally navigate to a confirmation screen or back to login
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-up failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error during sign-up: ${e.toString().split(':').last.trim()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signIn() async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.session != null) {
        await _saveSession(response.session!);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Login successful!')));
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Check your credentials.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error during login: ${e.toString().split(':').last.trim()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Replace the _googleSignIn method with this corrected version
Future<void> _googleSignIn() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Use Supabase's built-in OAuth for Google
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      // Optional: Customize scopes (e.g., for email/profile access)
      scopes: 'email profile',
      // Optional: Redirect URL for deep link callback (must match your Supabase settings)
      redirectTo: 'com.primesoftworks.regtapp://auth/confirm', // Replace with your app's scheme
    );

    // If successful, the auth state listener in main.dart will auto-navigate to /home
    // (No need for manual Navigator.pushReplacementNamed here)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In successful!')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during Google Sign-In: ${e.toString().split(':').last.trim()}')),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  Future<void> _forgotPassword() async {
    final forgotEmail = _forgotEmailController.text.trim();
    if (forgotEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }
    if (!validateEmail(forgotEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        forgotEmail,
        redirectTo: 'com.primesoftworks.regtapp://auth/reset',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link sent to your email')),
      );
      setState(() {
        showForgotPassword = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _saveSession(Session session) async {
    await _storage.write(key: 'access_token', value: session.accessToken);
    await _storage.write(
      key: 'refresh_token',
      value: session.refreshToken ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (showForgotPassword) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black, Color(0xFF1A1A1A), Colors.black],
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mail,
                          size: 32,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your email to receive reset link',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _forgotEmailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.mail,
                            color: Colors.grey,
                          ),
                          hintText: 'Enter your email',
                          hintStyle: const TextStyle(color: Colors.grey),
                          fillColor: const Color(0xFF1A1A1A),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _forgotPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Send Reset Link'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() {
                          showForgotPassword = false;
                        }),
                        child: const Text(
                          'Back to Login',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black, Color(0xFF1A1A1A), Colors.black],
                ),
              ),
            ),
            const Positioned(
              top: 80,
              right: 40,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.public, size: 80, color: Color(0xFFFFD700)),
              ),
            ),

            // const Positioned(
            //   bottom: 128,
            //   left: 40,
            //   child: Opacity(
            //     opacity: 0.1,
            //     child: Icon(
            //       Icons.apartment,
            //       size: 64,
            //       color: Color(0xFFFFD700),
            //     ),
            //   ),
            // ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Container(
                      //   width: 80,
                      //   height: 80,
                      //   decoration: BoxDecoration(
                      //     gradient: const LinearGradient(
                      //       colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      //     ),
                      //     shape: BoxShape.circle,
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: const Color(0xFFFFD700).withOpacity(0.3),
                      //         blurRadius: 20,
                      //         spreadRadius: 5,
                      //       ),
                      //     ],
                      //   ),
                      //   child: Center(
                      //     child: Container(
                      //       width: 56,
                      //       height: 56,
                      //       decoration: const BoxDecoration(
                      //         color: Colors.black,
                      //         shape: BoxShape.circle,
                      //       ),
                      //       child: const Icon(
                      //         Icons.public,
                      //         color: Color(0xFFFFD700),
                      //         size: 28,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: CircleAvatar(
                            radius: 50, // Increased for larger inner circle
                            backgroundColor: Colors.black,
                            backgroundImage: AssetImage(
                              'assets/images/regt_logo.png',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'REGT',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLogin
                            ? 'Welcome back! Sign in to continue'
                            : 'Create your account to start earning',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (formError != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (formError != null) const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.mail,
                            color: Colors.grey,
                          ),
                          hintText: 'Email address',
                          hintStyle: const TextStyle(color: Colors.grey),
                          fillColor: const Color(0xFF1A1A1A),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF424242),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF424242),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.grey),
                          fillColor: const Color(0xFF1A1A1A),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF424242),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF424242),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (!isLogin) const SizedBox(height: 16),
                      if (!isLogin)
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: !showConfirmPassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.grey,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  showConfirmPassword = !showConfirmPassword;
                                });
                              },
                            ),
                            hintText: 'Confirm password',
                            hintStyle: const TextStyle(color: Colors.grey),
                            fillColor: const Color(0xFF1A1A1A),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF424242),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF424242),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(isLogin ? 'Sign In' : 'Create Account'),
                      ),
                      if (isLogin) const SizedBox(height: 8),
                      if (isLogin)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showForgotPassword = true;
                            });
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _googleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Google Sign In'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLogin
                                ? "Don't have an account?"
                                : 'Already have an account?',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isLogin = !isLogin;
                                formError = null;
                                _emailController.clear();
                                _passwordController.clear();
                                _confirmPasswordController.clear();
                              });
                            },
                            child: Text(
                              isLogin ? 'Sign Up' : 'Sign In',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'By continuing, you agree to our Terms of Service',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
