import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Unifies biometric (fingerprint/face) vs device credentials (PIN/Pattern/Password).
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // -------- Availability --------

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final types = await _localAuth.getAvailableBiometrics();
      return canCheck && types.isNotEmpty;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<bool> isFingerprintAvailable() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      final hasFingerprint = types.contains(BiometricType.fingerprint);
      print('Available biometric types: $types');
      print('Has fingerprint: $hasFingerprint');
      return hasFingerprint;
    } catch (e) {
      print('Error checking fingerprint availability: $e');
      return false;
    }
  }

  /// Device credential (PIN/Pattern/Password). Best-effort probe.
  Future<bool> isDeviceCredentialAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      print('Device supported for authentication: $supported');
      if (Platform.isAndroid) return supported;
      if (Platform.isIOS) return supported; // passcode
      return false;
    } catch (e) {
      print('Error checking device credential availability: $e');
      return false;
    }
  }

  // -------- App prefs (saved in secure storage) --------

  Future<bool> isFingerprintEnabled() async {
    try {
      final enabled = (await _storage.read(key: 'fingerprint_enabled')) == 'true';
      print('Fingerprint enabled in settings: $enabled');
      return enabled;
    } catch (e) {
      print('Error reading fingerprint enabled status: $e');
      return false;
    }
  }

  Future<bool> isDeviceCredentialEnabled() async {
    try {
      final enabled = (await _storage.read(key: 'pattern_enabled')) == 'true';
      print('Device credential enabled in settings: $enabled');
      return enabled;
    } catch (e) {
      print('Error reading device credential enabled status: $e');
      return false;
    }
  }

  // -------- Enable / disable toggles --------

  Future<bool> enableFingerprint({required String localizedReason}) async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,     // ensures only fingerprint/face is used
          stickyAuth: true,        // allows re-authentication if needed
        ),
      );
      if (ok) {
        await _storage.write(key: 'fingerprint_enabled', value: 'true');
        print('Fingerprint enabled and saved to storage');
      }
      return ok;
    } catch (e) {
      print('Error enabling fingerprint: $e');
      return false;
    }
  }

  Future<bool> enableDeviceCredential({required String localizedReason}) async {
    try {
      if (!await isDeviceCredentialAvailable()) {
        print('Device credential not available, cannot enable');
        return false;
      }

      print('Attempting to enable device credential with authentication...');
      final ok = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN/Pattern/Password
          stickyAuth: true,
        ),
      );

      print('Device credential authentication result: $ok');
      if (ok) {
        await _storage.write(key: 'pattern_enabled', value: 'true');
        print('Device credential enabled and saved to storage');
      }
      return ok;
    } catch (e) {
      print('Error enabling device credential: $e');
      return false;
    }
  }

  Future<void> disableFingerprint() async {
    try {
      await _storage.delete(key: 'fingerprint_enabled');
      print('Fingerprint disabled');
    } catch (e) {
      print('Error disabling fingerprint: $e');
    }
  }

  Future<void> disableDeviceCredential() async {
    try {
      await _storage.delete(key: 'pattern_enabled');
      print('Device credential disabled');
    } catch (e) {
      print('Error disabling device credential: $e');
    }
  }

  // -------- Auth actions --------

  Future<bool> authenticateWithFingerprint({required String localizedReason}) async {
    try {
      print('Attempting fingerprint authentication...');
      final result = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      print('Fingerprint authentication result: $result');
      return result;
    } catch (e) {
      print('Error during fingerprint authentication: $e');
      return false;
    }
  }

  Future<bool> authenticateWithDeviceCredential({required String localizedReason}) async {
    try {
      print('Attempting device credential authentication...');
      final result = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false, // <— key difference
          stickyAuth: true,
        ),
      );
      print('Device credential authentication result: $result');
      return result;
    } catch (e) {
      print('Error during device credential authentication: $e');
      return false;
    }
  }

  // -------- Diagnostics --------

  Future<List<BiometricType>> getAvailableBiometricTypes() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      print('Available biometric types: $types');
      return types;
    } catch (e) {
      print('Error getting available biometric types: $e');
      return <BiometricType>[];
    }
  }

  Future<Map<String, dynamic>> getBiometricCapabilities() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final types = await _localAuth.getAvailableBiometrics();

      final capabilities = {
        'canCheckBiometrics': canCheck,
        'isDeviceSupported': supported,
        'availableTypes': types.map((e) => e.toString()).toList(),
        'hasFingerprint': types.contains(BiometricType.fingerprint),
        'hasFace': types.contains(BiometricType.face),
        'hasIris': types.contains(BiometricType.iris),
      };

      print('Biometric capabilities: $capabilities');
      return capabilities;
    } catch (e) {
      print('Error getting biometric capabilities: $e');
      return {
        'canCheckBiometrics': false,
        'isDeviceSupported': false,
        'availableTypes': <String>[],
        'hasFingerprint': false,
        'hasFace': false,
        'hasIris': false,
      };
    }
  }

  // (optional) human-readable names
  String getBiometricTypeName(BiometricType type, {bool isArabic = false}) {
    if (isArabic) {
      switch (type) {
        case BiometricType.fingerprint:
          return 'بصمة الإصبع';
        case BiometricType.face:
          return 'الوجه';
        case BiometricType.iris:
          return 'القزحية';
        case BiometricType.strong:
          return 'مصادقة قوية';
        case BiometricType.weak:
          return 'مصادقة ضعيفة';
      }
    } else {
      switch (type) {
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.face:
          return 'Face';
        case BiometricType.iris:
          return 'Iris';
        case BiometricType.strong:
          return 'Strong Authentication';
        case BiometricType.weak:
          return 'Weak Authentication';
      }
    }
  }
}
