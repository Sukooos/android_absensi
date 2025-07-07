import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const _keyName = 'encryption_key';
  static const _ivName = 'encryption_iv';
  final FlutterSecureStorage _secureStorage;
  late Encrypter _encrypter;
  late IV _iv;

  EncryptionService._(this._secureStorage);

  static Future<EncryptionService> init() async {
    final service = EncryptionService._(const FlutterSecureStorage());
    await service._initialize();
    return service;
  }

  Future<void> _initialize() async {
    // Get or generate encryption key
    String? keyString = await _secureStorage.read(key: _keyName);
    String? ivString = await _secureStorage.read(key: _ivName);

    if (keyString == null || ivString == null) {
      // Generate new key and IV if not exists
      final key = Key.fromSecureRandom(32); // 256-bit key
      final iv = IV.fromSecureRandom(16);

      // Save key and IV
      await _secureStorage.write(key: _keyName, value: key.base64);
      await _secureStorage.write(key: _ivName, value: iv.base64);

      keyString = key.base64;
      ivString = iv.base64;
    }

    // Initialize encrypter
    final key = Key.fromBase64(keyString);
    _iv = IV.fromBase64(ivString);
    _encrypter = Encrypter(AES(key));
  }

  String encrypt(String data) {
    return _encrypter.encrypt(data, iv: _iv).base64;
  }

  String decrypt(String encryptedData) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      // Return empty string if decryption fails
      return '';
    }
  }
}
