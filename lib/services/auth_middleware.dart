import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'session_service.dart';

class AuthMiddleware {
  final SessionService _sessionService;
  final AuthService _authService;

  AuthMiddleware(this._sessionService, this._authService);

  static Future<AuthMiddleware> init() async {
    final sessionService = await SessionService.init();
    final authService = AuthService(sessionService);
    return AuthMiddleware(sessionService, authService);
  }

  // Check authentication before accessing a protected route
  Future<bool> checkAuth(BuildContext context) async {
    // Check if session is active
    final isActive = await _sessionService.isSessionActive();
    if (!isActive) {
      // Session not active, navigate to login
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
      return false;
    }

    // Check if token needs refreshing
    if (_sessionService.needsTokenRefresh()) {
      debugPrint('Token needs refresh, refreshing...');
      final result = await _authService.refreshToken();

      if (!result['success']) {
        // Refresh failed, clear session and go to login
        await _sessionService.clearSession();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        return false;
      }
    }

    return true;
  }
}
