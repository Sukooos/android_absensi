import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../domain/models/user_model.dart';
import 'session_service.dart';

class AuthService {
  final SessionService _sessionService;
  final AppConfig _config = AppConfig();
  User? _currentUser;

  AuthService(this._sessionService);

  static Future<AuthService> init() async {
    final sessionService = await SessionService.init();
    return AuthService(sessionService);
  }

  User? get currentUser => _currentUser;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${_config.apiBaseUrl}/auth/login-json'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Assuming the API returns a token in the format: { "data": { "token": "your_token" } }
        if (responseData['access_token'] != null) {
          final token = responseData['access_token'];
          await _sessionService.saveToken(token);

          // Store user data if available in response
          if (responseData['user'] != null) {
            _currentUser = User.fromJson(responseData['user']);
            await _saveUserDataToStorage(_currentUser!);
          } else {
            // If user data isn't in response, try to fetch it
            await getUserProfile();
          }

          return {'success': true, 'data': responseData};
        }
        return {
          'success': false,
          'message': 'Token tidak ditemukan dalam respons',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] != null
              ? responseData['message'].toString()
              : 'Gagal login. Silakan coba lagi.',
        };
      }
    } catch (e) {
      debugPrint('Error during login: $e');

      // FOR TESTING: Create mock data when backend is not available
      if (_config.isDevelopment) {
        await _createMockUserForTesting(email);
        return {
          'success': true,
          'data': {'message': 'Login berhasil (mode pengembangan)'},
        };
      }

      return {
        'success': false,
        'message':
            'Terjadi kesalahan koneksi ke server. Pastikan server berjalan dan periksa URL.',
      };
    }
  }

  // Mock method for testing without backend
  Future<void> _createMockUserForTesting(String email) async {
    final mockUser = User(
      id: 1,
      name: 'Pengguna Test',
      email: email,
      position: 'Software Engineer',
      employeeId: 'EMP-123',
      phone: '+62 812-3456-7890',
      address: 'Jl. Contoh No. 123, Jakarta',
      profilePicture: null,
    );

    _currentUser = mockUser;
    await _saveUserDataToStorage(_currentUser!);

    // Create a fake token
    const mockToken =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwibmFtZSI6IlBlbmdndW5hIFRlc3QiLCJpYXQiOjE2OTcwMjE1NzQsImV4cCI6MTcyODU3OTE3NH0.8e2dACrUw96UbZfPoZL_l5oPbKL_ucnlm-_blaiNCKQ';
    await _sessionService.saveToken(mockToken);

    debugPrint('Created mock user for testing: ${mockUser.name}');
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final currentToken = _sessionService.getToken();
      if (currentToken == null) {
        return {'success': false, 'message': 'Tidak ada token tersedia'};
      }

      final response = await http.post(
        Uri.parse('${_config.apiBaseUrl}/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Assuming the API returns a new token
        if (responseData['data'] != null &&
            responseData['data']['token'] != null) {
          final newToken = responseData['data']['token'];
          await _sessionService.saveToken(newToken);
          return {'success': true, 'data': responseData['data']};
        }
        return {
          'success': false,
          'message': 'Token baru tidak ditemukan dalam respons',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Gagal refresh token. Silakan login ulang.',
        };
      }
    } catch (e) {
      debugPrint('Error during token refresh: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = _sessionService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Tidak ada token tersedia'};
      }

      final response = await http.get(
        Uri.parse('${_config.apiBaseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Handle different API response formats
        Map<String, dynamic> userData;
        if (responseData['user'] != null) {
          userData = responseData['user'];
        } else if (responseData['data'] != null) {
          userData = responseData['data'];
        } else {
          userData = responseData; // Assume response itself is user data
        }

        try {
          _currentUser = User.fromJson(userData);
          await _saveUserDataToStorage(_currentUser!);
          return {'success': true, 'data': _currentUser};
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          return {
            'success': false,
            'message': 'Format data pengguna tidak valid: ${e.toString()}',
          };
        }
      } else {
        final errorMsg = responseData['message'] != null
            ? responseData['message'].toString()
            : 'Gagal mendapatkan profil pengguna.';
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');

      // Try to load from storage first before creating mock data
      final storedUser = await loadUserFromStorage();
      if (storedUser != null) {
        return {'success': true, 'data': storedUser};
      }

      // FOR TESTING: Create mock data when backend is not available
      if (_config.isDevelopment) {
        await _createMockUserForTesting('user@example.com');
        return {'success': true, 'data': _currentUser};
      }

      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  Future<void> _saveUserDataToStorage(User user) async {
    await _sessionService.saveUserData(json.encode(user.toJson()));
  }

  Future<User?> loadUserFromStorage() async {
    final userData = await _sessionService.getUserData();
    if (userData != null) {
      try {
        _currentUser = User.fromJson(json.decode(userData));
        return _currentUser;
      } catch (e) {
        debugPrint('Error parsing stored user data: $e');
      }
    }
    return null;
  }

  Future<bool> logout() async {
    try {
      final token = _sessionService.getToken();
      if (token == null) return true;

      final response = await http.post(
        Uri.parse('${_config.apiBaseUrl}/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Regardless of API response, clear local session
      _currentUser = null;
      await _sessionService.clearSession();
      return true;
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Still clear session locally even if API fails
      _currentUser = null;
      await _sessionService.clearSession();
      return true;
    }
  }
}
