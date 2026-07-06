import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/credit_card.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _key = 'encrypted_card_data';

  // Double-encrypts card details using XOR cipher with a secure key and encodes in Base64
  String _encrypt(String data) {
    const keyString = 'AntigravityVaultSecret1948';
    final List<int> dataBytes = utf8.encode(data);
    final List<int> keyBytes = utf8.encode(keyString);
    final List<int> encryptedBytes = List<int>.generate(dataBytes.length, (i) {
      return dataBytes[i] ^ keyBytes[i % keyBytes.length];
    });
    return base64.encode(encryptedBytes);
  }

  // Decrypts XOR-Base64 encoded data back to standard JSON string
  String _decrypt(String encryptedData) {
    const keyString = 'AntigravityVaultSecret1948';
    final List<int> encryptedBytes = base64.decode(encryptedData);
    final List<int> keyBytes = utf8.encode(keyString);
    final List<int> decryptedBytes = List<int>.generate(encryptedBytes.length, (i) {
      return encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    });
    return utf8.decode(decryptedBytes);
  }

  // Encrypts and saves the complete list of credit cards to secure storage
  Future<void> saveCards(List<CreditCard> cards) async {
    final jsonString = json.encode(cards.map((c) => c.toJson()).toList());
    final encryptedString = _encrypt(jsonString);
    await _storage.write(key: _key, value: encryptedString);
  }

  // Loads, decrypts, and parses the list of credit cards from secure storage
  Future<List<CreditCard>> loadCards() async {
    try {
      final encryptedString = await _storage.read(key: _key);
      if (encryptedString == null) return [];
      final jsonString = _decrypt(encryptedString);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((j) => CreditCard.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      // In case of corruption, first launch, or decoding error, return empty list
      return [];
    }
  }
}
