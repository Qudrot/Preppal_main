import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prepal2/presentation/providers/auth_provider.dart';
import 'package:prepal2/presentation/screens/auth/login_screen.dart';
import 'package:prepal2/presentation/screens/main_shell.dart';
import 'package:prepal2/presentation/screens/auth/signup_screen.dart';
import 'package:prepal2/core/constants/app_colors.dart';
import 'package:prepal2/presentation/widgets/shared_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    final startedAt = DateTime.now();
    const minSplash = Duration(milliseconds: 800);
    const maxWait = Duration(seconds: 3);

    while ((authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading) &&
        DateTime.now().difference(startedAt) < maxWait) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < minSplash) {
      await Future.delayed(minSplash - elapsed);
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => authProvider.status == AuthStatus.authenticated
            ? const MainShell()
            : const WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// Welcome Screen (first screen from wireframe)
// --------------------------------------------------

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // PrepPal Logo
                    Image.asset(
                      'assets/logo.png',
                      width: 200,
                      height: 200,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'PrepPal is here to make prepping more\n'
                      'effective and profitable',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7A7A7A),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'AI powered app to help you cut down wastage and\n'
                      'optimized your prepping for your business',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9E9E),
                        height: 1.4,
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Log In button
                    PrimaryButton(
                      text: 'Log in',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Sign Up button
                    PrimaryButton(
                      text: 'Sign up',
                      type: ButtonType.tertiary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}