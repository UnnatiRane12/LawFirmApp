import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DocumentSecuritySync {
  /// Hashes a password using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Encrypts data using a password-derived key
  static String encryptData(String data, String password) {
    final key = encrypt.Key.fromUtf8(password.padRight(32).substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  /// Decrypts data using a password-derived key
  static String decryptData(String encryptedBase64, String password) {
    final key = encrypt.Key.fromUtf8(password.padRight(32).substring(0, 32));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    try {
      return encrypter.decrypt64(encryptedBase64, iv: iv);
    } catch (e) {
      return 'Decryption failed: Invalid password';
    }
  }
}
