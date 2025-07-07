import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../core/utils/route_transition.dart';
import '../../services/session_service.dart';
import 'login_page.dart';
import 'dashboard_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Remove native splash screen
    FlutterNativeSplash.remove();

    // Initialize session service
    final sessionService = await SessionService.init();

    // Add artificial delay for splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check session and navigate accordingly
    final isActive = await sessionService.isSessionActive();
    if (isActive) {
      // Update last activity time when app starts
      await sessionService.updateLastActivity();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(FadePageRoute(page: const DashboardPage()));
    } else {
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(FadePageRoute(page: const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, color: Colors.white, size: 64),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Memuat aplikasi...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
