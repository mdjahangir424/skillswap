
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<void> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      Firebase.initializeApp(),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillSwap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: FutureBuilder<void>(
        future: _startup,
        builder: (context, startupSnapshot) {
          if (startupSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const SplashScreen();
          }

          if (startupSnapshot.hasError) {
            return Scaffold(
              backgroundColor: const Color(0xFF061442),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to start SkillSwap.\n'
                    'Please check your connection and restart the app.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }

          return const AuthCheck();
        },
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _showLogin = false;

  void _openLogin() {
    setState(() {
      _showLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasError) {
          return const LoginScreen();
        }

        if (snapshot.hasData) {
          return const MainNavigation();
        }

        if (_showLogin) {
          return const LoginScreen();
        }

        return SplashScreen(
          onGetStarted: _openLogin,
        );
      },
    );
  }
}
