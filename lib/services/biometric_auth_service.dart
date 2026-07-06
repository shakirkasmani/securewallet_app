import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  // Checks if the device has biometric hardware and has enrolled credentials
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Triggers the Face ID / Touch ID / Fingerprint biometric authentication prompt
  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock your credit card vault',
        biometricOnly: false, // Allows passcode fallback if biometrics fail/aren't configured
        persistAcrossBackgrounding: true, // Keep authentication prompt active if app goes to background
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
