
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main_navigation.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _selectedCountryCode;
  String? _selectedGender;

  static const Color primaryBlue = Color(0xFF075CF5);

  static const List<Map<String, String>> _countries = [
    {'name': 'Bangladesh', 'code': 'BD'},
    {'name': 'India', 'code': 'IN'},
    {'name': 'Pakistan', 'code': 'PK'},
    {'name': 'Nepal', 'code': 'NP'},
    {'name': 'Sri Lanka', 'code': 'LK'},
    {'name': 'United States', 'code': 'US'},
    {'name': 'United Kingdom', 'code': 'GB'},
    {'name': 'Canada', 'code': 'CA'},
    {'name': 'Australia', 'code': 'AU'},
    {'name': 'United Arab Emirates', 'code': 'AE'},
    {'name': 'Saudi Arabia', 'code': 'SA'},
    {'name': 'Qatar', 'code': 'QA'},
    {'name': 'Kuwait', 'code': 'KW'},
    {'name': 'Oman', 'code': 'OM'},
    {'name': 'Malaysia', 'code': 'MY'},
    {'name': 'Singapore', 'code': 'SG'},
    {'name': 'Indonesia', 'code': 'ID'},
    {'name': 'Japan', 'code': 'JP'},
    {'name': 'China', 'code': 'CN'},
    {'name': 'South Korea', 'code': 'KR'},
    {'name': 'Turkey', 'code': 'TR'},
    {'name': 'Germany', 'code': 'DE'},
    {'name': 'France', 'code': 'FR'},
    {'name': 'Italy', 'code': 'IT'},
    {'name': 'Spain', 'code': 'ES'},
    {'name': 'Netherlands', 'code': 'NL'},
    {'name': 'South Africa', 'code': 'ZA'},
    {'name': 'Nigeria', 'code': 'NG'},
    {'name': 'Brazil', 'code': 'BR'},
    {'name': 'Mexico', 'code': 'MX'},
    {'name': 'New Zealand', 'code': 'NZ'},
    {'name': 'Thailand', 'code': 'TH'},
    {'name': 'Vietnam', 'code': 'VN'},
    {'name': 'Philippines', 'code': 'PH'},
    {'name': 'Ireland', 'code': 'IE'},
    {'name': 'Sweden', 'code': 'SE'},
    {'name': 'Switzerland', 'code': 'CH'},
    {'name': 'Norway', 'code': 'NO'},
    {'name': 'Russia', 'code': 'RU'},
    {'name': 'Egypt', 'code': 'EG'},
  ];

  Timer? _resendTimer;

  final ValueNotifier<int> _resendSeconds = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isResending = ValueNotifier<bool>(false);

  String _countryFlag(String countryCode) {
    return countryCode.toUpperCase().codeUnits
        .map((code) => String.fromCharCode(code + 127397))
        .join();
  }

  String get _selectedCountryName {
    final country = _countries.firstWhere(
      (item) => item['code'] == _selectedCountryCode,
      orElse: () => {'name': '', 'code': ''},
    );

    return country['name'] ?? '';
  }

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

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'Firebase temporarily blocked requests. Please try later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/Password authentication is not enabled.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return '${e.code}: ${e.message ?? 'Unknown Firebase error'}';
    }
  }

  Future<String?> _sendVerification(User user) async {
    try {
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('VERIFICATION ERROR: ${e.code} - ${e.message}');
      return _firebaseErrorMessage(e);
    } catch (e) {
      debugPrint('UNKNOWN VERIFICATION ERROR: $e');
      return 'Could not send email: $e';
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

  Future<void> _showVerificationDialog(
    User user, {
    String? initialError,
  }) async {
    if (initialError == null) {
      _startResendCooldown();
    } else {
      _resendSeconds.value = 0;
    }

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool checking = false;
        String? dialogError = initialError;

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
                            'Email Error:\n$dialogError',
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
                                          'Email is not verified yet. Open the verification link in your email first.';
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
                                onPressed: (isResending || seconds > 0)
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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCountryCode == null || _selectedGender == null) {
      _showMessage('Please select your country and gender.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    User? createdUser;

    try {
      final email = _emailController.text.trim();

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('User account could not be created.');
      }

      createdUser = user;

      final userName = _nameController.text.trim();

      await user.updateDisplayName(userName);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': userName,
        'email': user.email,
        'country': _selectedCountryName,
        'countryCode': _selectedCountryCode,
        'gender': _selectedGender,
        'bio': '',
        'photoUrl': '',
        'skillsOffered': [],
        'skillsWanted': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final emailError = await _sendVerification(user);

      if (!mounted) return;

      setState(() => _isLoading = false);

      await _showVerificationDialog(
        user,
        initialError: emailError,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      _showMessage(_firebaseErrorMessage(e));
    } catch (e) {
      debugPrint('SIGNUP ERROR: $e');

      if (!mounted) return;

      // If Auth account was created but profile creation failed,
      // do not hide the real error.
      if (createdUser != null) {
        _showMessage(
          'Account was created, but profile setup failed: $e',
        );
      } else {
        _showMessage('Account creation failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _resendSeconds.dispose();
    _isResending.dispose();

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        foregroundColor: const Color(0xFF172033),
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 15,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    color: primaryBlue,
                    size: 62,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Join SkillSwap!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Create your account and start exchanging skills.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _fieldLabel('Full Name'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name.';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must contain at least 2 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  _fieldLabel('Email Address'),
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
                  const SizedBox(height: 18),

                  _fieldLabel('Country'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCountryCode,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      hint: 'Select your country',
                      icon: Icons.public,
                    ),
                    items: _countries.map((country) {
                      final code = country['code']!;
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(
                          '${_countryFlag(code)}  ${country['name']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCountryCode = value);
                    },
                    validator: (value) =>
                        value == null ? 'Please select your country.' : null,
                  ),
                  const SizedBox(height: 18),

                  _fieldLabel('Gender'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      hint: 'Select your gender',
                      icon: Icons.person_outline,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Male',
                        child: Text('Male'),
                      ),
                      DropdownMenuItem(
                        value: 'Female',
                        child: Text('Female'),
                      ),
                      DropdownMenuItem(
                        value: 'Prefer not to say',
                        child: Text('Prefer not to say'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedGender = value);
                    },
                    validator: (value) =>
                        value == null ? 'Please select an option.' : null,
                  ),
                  const SizedBox(height: 18),

                  _fieldLabel('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: _inputDecoration(
                      hint: 'Create a password',
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
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please create a password.';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  _fieldLabel('Confirm Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: _inputDecoration(
                      hint: 'Confirm your password',
                      icon: Icons.lock_reset_outlined,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password.';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            primaryBlue.withOpacity(0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Color(0xFF172033),
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
