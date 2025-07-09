import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import 'encryption_service.dart';
import 'biometric_service.dart';

class SessionService {
  static const String _tokenKey = 'auth_token';
  static const String _lastActivityKey = 'last_activity';
  static const String _userDataKey = 'user_data';
  static const Duration _sessionTimeout = Duration(minutes: 20);
  static const Duration _tokenRefreshThreshold = Duration(minutes: 5);

  final SharedPreferences _prefs;
  final EncryptionService _encryptionService;
  final BiometricService _biometricService;
  final AppConfig _config = AppConfig();

  SessionService._(
    this._prefs,
    this._encryptionService,
    this._biometricService,
  );

  static Future<SessionService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptionService = await EncryptionService.init();
    final biometricService = await BiometricService.init();

    return SessionService._(prefs, encryptionService, biometricService);
  }

  // Save auth token with encryption
  Future<void> saveToken(String token) async {
    final encryptedToken = _encryptionService.encrypt(token);
    await _prefs.setString(_tokenKey, encryptedToken);
    await updateLastActivity();
  }

  // Get stored auth token with decryption
  String? getToken() {
    final encryptedToken = _prefs.getString(_tokenKey);
    if (encryptedToken == null) return null;
    return _encryptionService.decrypt(encryptedToken);
  }

  // Save user data with encryption
  Future<void> saveUserData(String userData) async {
    final encryptedUserData = _encryptionService.encrypt(userData);
    await _prefs.setString(_userDataKey, encryptedUserData);
  }

  // Get stored user data with decryption
  String? getUserData() {
    final encryptedUserData = _prefs.getString(_userDataKey);
    if (encryptedUserData == null) return null;
    return _encryptionService.decrypt(encryptedUserData);
  }

  // Update last activity timestamp
  Future<void> updateLastActivity() async {
    await _prefs.setInt(
      _lastActivityKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Check if token needs refresh (5 minutes before expiry)
  bool needsTokenRefresh() {
    final token = getToken();
    if (token == null) return false;

    try {
      final decodedToken = JwtDecoder.decode(token);
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(
        decodedToken['exp'] * 1000,
      );
      final now = DateTime.now();
      return now.isAfter(expiryDate.subtract(_tokenRefreshThreshold));
    } catch (e) {
      return false;
    }
  }

  // Helper method to get token expiry date
  DateTime? getTokenExpiryDate() {
    final token = getToken();
    if (token == null) return null;

    try {
      final decodedToken = JwtDecoder.decode(token);
      return DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
    } catch (e) {
      return null;
    }
  }

  // Refresh token if needed - to be called by other services
  Future<void> checkAndRefreshTokenIfNeeded() async {
    if (needsTokenRefresh()) {
      // This method just signals that refresh is needed
      // The actual refresh will be implemented by AuthService
      debugPrint('Token needs refresh - signaling to refresh');
    }
  }

  // Check if session is active and validate with biometric if needed
  Future<bool> isSessionActive() async {
    final token = getToken();
    if (token == null) return false;

    // Validate token with backend first
    final isValid = await validateTokenWithBackend(token);
    if (!isValid) {
      // Clear invalid session
      await clearSession();
      return false;
    }

    final lastActivity = _prefs.getInt(_lastActivityKey);
    if (lastActivity == null) return false;

    final lastActivityTime = DateTime.fromMillisecondsSinceEpoch(lastActivity);
    final now = DateTime.now();
    final difference = now.difference(lastActivityTime);

    // If session timeout is reached, require biometric authentication
    if (difference > _sessionTimeout) {
      // Only try biometric if available
      if (_biometricService.isBiometricAvailable) {
        final authenticated = await _biometricService.authenticate();
        if (authenticated) {
          await updateLastActivity();
          return true;
        }
      }
      return false;
    }

    return true;
  }

  // Clear session data
  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_lastActivityKey);
    await _prefs.remove(_userDataKey);
  }

  // Validate token with backend
  Future<bool> validateTokenWithBackend(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${_config.apiBaseUrl}/auth/validate-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        debugPrint(
          'Token validation failed with status ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error validating token: $e');
      return false;
    }
  }
}
