
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'signup_screen.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isResettingPassword = false;

  Timer? _resendTimer;

  final ValueNotifier<int> _resendSeconds = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isResending = ValueNotifier<bool>(false);

  static const Color primaryBlue = Color(0xFF075CF5);
  static const Color darkBlue = Color(0xFF073A91);

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendSeconds.value = 60;

    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendSeconds.value <= 1) {
          _resendSeconds.value = 0;
          timer.cancel();
        } else {
          _resendSeconds.value--;
        }
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Email/Password login is not enabled.';
      default:
        return '${e.code}: ${e.message ?? 'Login failed.'}';
    }
  }

  Future<String?> _sendVerification(User user) async {
    try {
      await user.sendEmailVerification();
      debugPrint('Verification email sent to ${user.email}');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('VERIFICATION ERROR: ${e.code} - ${e.message}');
      return _authError(e);
    } catch (e) {
      debugPrint('UNKNOWN VERIFICATION ERROR: $e');
      return 'Could not send verification email: $e';
    }
  }

  Future<void> _resendVerification(User user) async {
    if (_isResending.value || _resendSeconds.value > 0) return;

    _isResending.value = true;

    try {
      final error = await _sendVerification(user);

      if (!mounted) return;

      if (error == null) {
        _startResendCooldown();
        _showMessage('Verification email sent. Check your inbox.');
      } else {
        _showMessage('Email sending failed: $error');
      }
    } finally {
      _isResending.value = false;
    }
  }

  Future<bool> _checkVerification(User user) async {
    try {
      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null) return false;

      await refreshedUser.getIdToken(true);
      await refreshedUser.reload();

      return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    } catch (e) {
      debugPrint('VERIFICATION CHECK ERROR: $e');
      return false;
    }
  }

  Future<void> _showVerificationDialog(User user) async {
    _startResendCooldown();

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool checking = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: const BorderSide(
                  color: Color(0xFFDCE8FF),
                  width: 1.3,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 82,
                        width: 82,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF1FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          color: primaryBlue,
                          size: 43,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Your Account Created!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Verify Your Email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A verification link is required for your SkillSwap account:\n'
                        '${user.email ?? ''}\n\n'
                        'Please check your inbox and click the verification link.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            dialogError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: checking
                              ? null
                              : () async {
                                  dialogSetState(() {
                                    checking = true;
                                    dialogError = null;
                                  });

                                  final isVerified =
                                      await _checkVerification(user);

                                  if (!dialogContext.mounted) return;

                                  if (isVerified) {
                                    Navigator.pop(dialogContext, true);
                                  } else {
                                    dialogSetState(() {
                                      checking = false;
                                      dialogError =
                                          'Email is not verified yet. Open the verification link in your inbox first.';
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: checking
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Verify Your Email',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isResending,
                        builder: (context, isResending, _) {
                          return ValueListenableBuilder<int>(
                            valueListenable: _resendSeconds,
                            builder: (context, seconds, _) {
                              return TextButton(
                                onPressed: isResending || seconds > 0
                                    ? null
                                    : () async {
                                        await _resendVerification(user);
                                        if (dialogContext.mounted) {
                                          dialogSetState(() {
                                            dialogError = null;
                                          });
                                        }
                                      },
                                child: isResending
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        seconds > 0
                                            ? 'Resend available in 00:${seconds.toString().padLeft(2, '0')}'
                                            : 'Resend Verification Email',
                                        style: TextStyle(
                                          color: seconds > 0
                                              ? Colors.grey
                                              : primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 15,
                            color: Color(0xFF98A2B3),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Resend available after 1 minute.',
                            style: TextStyle(
                              color: Color(0xFF98A2B3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'SkillSwap',
                        style: TextStyle(
                          color: Color(0xFF073A91),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Learn. Teach. Exchange.',
                        style: TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    _resendTimer?.cancel();

    if (verified == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigation(),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Could not load account.');
      }

      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        throw Exception('Could not load account.');
      }

      if (!refreshedUser.emailVerified) {
        if (!mounted) return;

        setState(() => _isLoading = false);
        await _showVerificationDialog(refreshedUser);
        return;
      }

      await refreshedUser.getIdToken(true);

      // AuthCheck in main.dart handles verified users.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage(_authError(e));
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      if (!mounted) return;
      _showMessage('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    if (_isResettingPassword || _isLoading) return;

    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _showMessage('Enter a valid email address first.');
      return;
    }

    setState(() => _isResettingPassword = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _showMessage('Password reset email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showMessage('Password reset failed: ${_authError(e)}');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not send reset email: $e');
    } finally {
      if (mounted) {
        setState(() => _isResettingPassword = false);
      }
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _resendSeconds.dispose();
    _isResending.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 25,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    color: primaryBlue,
                    size: 65,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login to continue your SkillSwap journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 35),
                  const Text(
                    'Email Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: _inputDecoration(
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email.';
                      }

                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                          .hasMatch(value.trim())) {
                        return 'Enter a valid email address.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: _inputDecoration(
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: (_isLoading || _isResettingPassword)
                          ? null
                          : _forgotPassword,
                      child: _isResettingPassword
                          ? const SizedBox(
                              height: 17,
                              width: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            primaryBlue.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 23,
                              width: 23,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Color(0xFF667085),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading || _isResettingPassword
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Learn. Teach. Exchange.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkBlue.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryBlue),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFDCE3F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFDCE3F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: primaryBlue,
          width: 1.5,
        ),
      ),
    );
  }
}
