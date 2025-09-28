import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_auth_service.dart';
import '../api/api_client.dart';
import 'Loginscreen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isArabic;
  const SettingsScreen({super.key, this.isArabic = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _deviceCredEnabled = false; // pattern / PIN / password
  bool _fingerprintEnabled = false;
  bool _isLoading = false;

  List<BiometricType> _availableBiometrics = [];
  Map<String, dynamic> _biometricCapabilities = {};
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometricAvailability();
  }

  Future<void> _loadSettings() async {
    final devEnabled = await _biometricAuth.isDeviceCredentialEnabled();
    final fpEnabled = await _biometricAuth.isFingerprintEnabled();
    if (!mounted) return;
    setState(() {
      _deviceCredEnabled = devEnabled;
      _fingerprintEnabled = fpEnabled;
    });
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      setState(() => _statusMessage = 'Checking biometric availability...');
      final capabilities = await _biometricAuth.getBiometricCapabilities();
      final availableBiometrics = await _biometricAuth.getAvailableBiometricTypes();
      if (!mounted) return;
      setState(() {
        _biometricCapabilities = capabilities;
        _availableBiometrics = availableBiometrics;
        _statusMessage = capabilities['isDeviceSupported'] == true
            ? 'Biometric / device credentials supported'
            : 'Biometric / device credentials not supported';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Error checking biometric availability: $e');
    }
  }

  Future<void> _toggleDeviceCredential() async {
    if (_deviceCredEnabled) {
      await _biometricAuth.disableDeviceCredential();
      if (!mounted) return;
      setState(() => _deviceCredEnabled = false);
      _showMessage('pattern_disabled'.tr());
      await _loadSettings();   // refresh from storage
    } else {
      setState(() => _isLoading = true);
      final ok = await _biometricAuth.enableDeviceCredential(
        localizedReason: 'use_pattern_auth'.tr(), // Pattern / PIN / Password
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (ok) {
        setState(() => _deviceCredEnabled = true);
        _showMessage('pattern_enabled'.tr());
        await _loadSettings(); // refresh
      } else {
        _showMessage('pattern_auth_failed'.tr());
      }
    }
  }

  Future<void> _toggleFingerprint() async {
    if (_fingerprintEnabled) {
      await _biometricAuth.disableFingerprint();
      if (!mounted) return;
      setState(() => _fingerprintEnabled = false);
      _showMessage('fingerprint_disabled'.tr());
      await _loadSettings();   // refresh
    } else {
      setState(() => _isLoading = true);
      final ok = await _biometricAuth.enableFingerprint(
        localizedReason: 'use_fingerprint_auth'.tr(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (ok) {
        setState(() => _fingerprintEnabled = true);
        _showMessage('fingerprint_enabled'.tr());
        await _loadSettings(); // refresh
      } else {
        _showMessage('fingerprint_auth_failed'.tr());
      }
    }
  }

  Future<void> _testDeviceCredential() async {
    setState(() => _isLoading = true);
    final ok = await _biometricAuth.authenticateWithDeviceCredential(
      localizedReason: 'test_pattern'.tr(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showMessage(ok ? 'pattern_auth_success'.tr() : 'pattern_auth_failed'.tr());
  }

  Future<void> _testFingerprint() async {
    setState(() => _isLoading = true);
    final ok = await _biometricAuth.authenticateWithFingerprint(
      localizedReason: 'test_fingerprint'.tr(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showMessage(ok ? 'fingerprint_auth_success'.tr() : 'fingerprint_auth_failed'.tr());
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _getBiometricTypeName(BiometricType type) {
    return _biometricAuth.getBiometricTypeName(type, isArabic: widget.isArabic);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = widget.isArabic;
    final ui.TextDirection direction = isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    final String title = 'settings'.tr();

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B82FF),
          foregroundColor: Colors.white,
          title: Text(title),
          elevation: 0,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/bg_main.png', fit: BoxFit.cover),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Device Credential (Pattern/PIN/Password)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.key, color: Color(0xFF4CAF50), size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('pattern_authentication'.tr(),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('use_pattern_auth'.tr(),
                                          style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _deviceCredEnabled,
                                  onChanged: _isLoading ? null : (_) => _toggleDeviceCredential(),
                                  activeColor: const Color(0xFF4CAF50),
                                ),
                              ],
                            ),
                            if (_deviceCredEnabled) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _CircleActionButton(
                                    icon: Icons.security,
                                    label: 'test_pattern'.tr(),
                                    color: const Color(0xFF4CAF50),
                                    onTap: _isLoading ? null : _testDeviceCredential,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fingerprint
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.fingerprint, color: Color(0xFF0B82FF), size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('fingerprint_authentication'.tr(),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('use_fingerprint_auth'.tr(),
                                          style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _fingerprintEnabled,
                                  onChanged: _isLoading ? null : (_) => _toggleFingerprint(),
                                  activeColor: const Color(0xFF0B82FF),
                                ),
                              ],
                            ),
                            if (_fingerprintEnabled) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _CircleActionButton(
                                    icon: Icons.fingerprint,
                                    label: 'test_fingerprint'.tr(),
                                    color: const Color(0xFF0B82FF),
                                    onTap: _isLoading ? null : _testFingerprint,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const SizedBox(height: 24),

                    // Optional: show availability/debug (can hide in production)
                    Text(
                      _statusMessage,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    if (_availableBiometrics.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: _availableBiometrics
                            .map((t) => Chip(label: Text(_getBiometricTypeName(t))))
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Only clear session-related data, preserve ALL user data and biometric settings
                          await _storage.delete(key: 'customer_data');
                          
                          // Clear session cookie
                          await ApiClient.instance.clearSessionCookie();
                          
                          if (mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(isArabic: widget.isArabic),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: Text('logout'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _CircleActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RawMaterialButton(
          onPressed: onTap,
          elevation: 3,
          constraints: const BoxConstraints.tightFor(width: 64, height: 64),
          shape: const CircleBorder(),
          fillColor: color ?? Theme.of(context).primaryColor,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
