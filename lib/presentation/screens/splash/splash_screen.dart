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
  bool _showGreenBg = false;

  @override
  void initState() {
    super.initState();
    _playAnimationAndNavigate();
  }

  Future<void> _playAnimationAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    
    // 1. Show white background for 1 second
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    // 2. Trigger transition to green
    setState(() {
      _showGreenBg = true;
    });

    // 3. Wait for auth state to resolve (with timeout)
    final startedAt = DateTime.now();
    const maxWait = Duration(seconds: 3);

    while ((authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading) &&
        DateTime.now().difference(startedAt) < maxWait) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    // 4. Ensure we show the green screen for at least 1.5 seconds so the animation finishes
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < const Duration(milliseconds: 1500)) {
      await Future.delayed(const Duration(milliseconds: 1500) - elapsed);
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
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        color: _showGreenBg ? AppColors.secondary : Colors.white,
        child: Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              color: Color(0xFF282324), // Dark grey
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(32),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
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