import 'package:flutter/services.dart';
import 'package:flutter/material.dart'; // Tambahkan import material untuk debugPrint
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  final LocalAuthentication _localAuth;
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;

  BiometricService._(this._localAuth);

  static Future<BiometricService> init() async {
    final service = BiometricService._(LocalAuthentication());
    await service._checkBiometric();
    return service;
  }

  Future<void> _checkBiometric() async {
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      debugPrint('canCheckBiometrics: $_canCheckBiometrics'); // Debug log

      if (_canCheckBiometrics == true) {
        _availableBiometrics = await _localAuth.getAvailableBiometrics();
        debugPrint('availableBiometrics: $_availableBiometrics'); // Debug log
      } else {
        debugPrint('Device TIDAK mendukung biometric!'); // Debug log
      }
    } on PlatformException catch (e) {
      debugPrint(
        'Error checking biometric: ${e.message}, code: ${e.code}',
      ); // Debug log error
      _canCheckBiometrics = false;
      _availableBiometrics = [];
    }
  }

  bool get isBiometricAvailable =>
      _canCheckBiometrics == true &&
      (_availableBiometrics?.isNotEmpty ?? false);

  bool get hasFaceId =>
      _availableBiometrics?.contains(BiometricType.face) ?? false;

  bool get hasFingerprint =>
      _availableBiometrics?.contains(BiometricType.fingerprint) ?? false;

  Future<bool> authenticate() async {
    if (!isBiometricAvailable) {
      debugPrint('Biometric tidak tersedia untuk autentikasi'); // Debug log
      return false;
    }

    try {
      debugPrint('Mencoba autentikasi biometrik...'); // Debug log
      final result = await _localAuth.authenticate(
        localizedReason: 'Autentikasi untuk melanjutkan',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      debugPrint('Hasil autentikasi: $result'); // Debug log hasil
      return result;
    } on PlatformException catch (e) {
      debugPrint(
        'Error autentikasi: ${e.message}, code: ${e.code}',
      ); // Debug log error

      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        return false;
      }
      rethrow;
    }
  }
}
