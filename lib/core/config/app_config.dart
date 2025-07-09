import 'package:flutter/foundation.dart';
import 'dart:io';

enum Environment { development, staging, production }

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  Environment _environment = Environment.development;
  String _apiBaseUrl = '';

  // Initialize configuration based on environment
  void init({Environment environment = Environment.development}) {
    _environment = environment;

    switch (_environment) {
      case Environment.development:
        // For Android emulator, use 10.0.2.2 to access host machine
        // For iOS simulator, use localhost or 127.0.0.1
        if (kIsWeb) {
          _apiBaseUrl = 'http://localhost:8000/api/v1';
        } else if (Platform.isAndroid) {
          _apiBaseUrl = 'http://10.0.2.2:8000/api/v1';
        } else if (Platform.isIOS) {
          _apiBaseUrl = 'http://localhost:8000/api/v1';
        } else {
          _apiBaseUrl = 'http://localhost:8000/api/v1';
        }
        break;

      case Environment.staging:
        _apiBaseUrl = 'https://staging-api.example.com/api/v1';
        break;

      case Environment.production:
        _apiBaseUrl = 'https://api.example.com/api/v1';
        break;
    }
  }

  // Getters
  String get apiBaseUrl => _apiBaseUrl;
  Environment get environment => _environment;
  bool get isDevelopment => _environment == Environment.development;
  bool get isProduction => _environment == Environment.production;

  // Update the base URL manually (useful for debugging or custom server)
  void updateApiBaseUrl(String url) {
    _apiBaseUrl = url;
    debugPrint('API Base URL updated: $_apiBaseUrl');
  }
}
