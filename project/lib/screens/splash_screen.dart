import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    bool isLoggedIn = false;
    bool isOnboardingCompleted = false;

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (!isOnboardingCompleted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43E08B), Color(0xFF23C7DD), Color(0xFF8A7CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 52,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'TimeMate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Focus your task, avoid distraction',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 48),

              const _LoadingDots(),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Text(
                  'Plan • Focus • Review',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(isActive: true),
        const SizedBox(width: 8),
        _dot(isActive: false),
        const SizedBox(width: 8),
        _dot(isActive: false),
      ],
    );
  }

  Widget _dot({required bool isActive}) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isActive ? 1 : 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
