import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import 'catalog_home_screen.dart';
import 'main_navigation_screen.dart';
import '../services/biometric_auth_service.dart';

class LoginScreen extends StatefulWidget {
  final bool isArabic;
  const LoginScreen({super.key, this.isArabic = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _obscurePassword = true;

  final BiometricAuthService _biometricAuth = BiometricAuthService();

  bool _loading = false;
  bool _patternAvailable = false;
  bool _patternEnabled = false;
  bool _fingerprintAvailable = false;
  bool _fingerprintEnabled = false;
  bool _hasSavedCredentials = false;
  bool _hasTypedCredentials = false;

  Country _selectedCountry =
      const Country(code: 'JO', dialCode: '962', flag: '🇯🇴', name: 'Jordan');

  @override
  void initState() {
    super.initState();
    _bootstrap();
    // Listen to text field changes to update button visibility
    _phoneController.addListener(_updateTypedCredentialsStatus);
    _passwordController.addListener(_updateTypedCredentialsStatus);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updateTypedCredentialsStatus);
    _phoneController.removeListener(_updateTypedCredentialsStatus);
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateTypedCredentialsStatus() {
    final bool hasTyped = _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
    if (hasTyped != _hasTypedCredentials) {
      if (!mounted) return;
      setState(() {
        _hasTypedCredentials = hasTyped;
      });
    }
  }

  Future<void> _bootstrap() async {
    await _loadSessionCookie();
    await _prefillSavedCredentials();
    await _checkPatternStatus();
  }

  Future<void> _loadSessionCookie() async {
    await ApiClient.instance.loadSessionCookie();
  }

  Future<void> _prefillSavedCredentials() async {
    const storage = FlutterSecureStorage();
    final savedPhone = await storage.read(key: 'Phone');
    final savedPass = await storage.read(key: 'Password');

    if (savedPhone != null && _phoneController.text.isEmpty) {
      final dialPrefix = '+${_selectedCountry.dialCode}';
      if (savedPhone.startsWith(dialPrefix)) {
        _phoneController.text = savedPhone.substring(dialPrefix.length);
      } else {
        _phoneController.text = savedPhone;
      }
    }
    if (savedPass != null && _passwordController.text.isEmpty) {
      _passwordController.text = savedPass;
    }
  }

  Future<void> _checkPatternStatus() async {
    try {
      // Check if pattern and fingerprint are enabled in app settings
      final patternEnabled = await _biometricAuth.isDeviceCredentialEnabled();
      final fingerprintEnabled = await _biometricAuth.isFingerprintEnabled();
      
      print('🔐 Authentication status:');
      print('🔐 Pattern enabled: $patternEnabled');
      print('🔐 Fingerprint enabled: $fingerprintEnabled');

      // Check if we have saved credentials
      const storage = FlutterSecureStorage();
      final savedPhone = await storage.read(key: 'Phone');
      final savedPassword = await storage.read(key: 'Password');
      final savedName = await storage.read(key: 'Name');

      print('🔐 Checking saved credentials:');
      print('🔐 Saved Phone: $savedPhone');
      print('🔐 Saved Password: ${savedPassword != null ? '***' : 'null'}');
      print('🔐 Saved Name: $savedName');

      final bool hasSaved = savedPhone != null &&
          savedPassword != null &&
          savedName != null;

      final bool hasTyped = _phoneController.text.trim().isNotEmpty &&
          _passwordController.text.trim().isNotEmpty;
          
      print('🔐 Has saved credentials: $hasSaved');
      print('🔐 Has typed credentials: $hasTyped');

      if (!mounted) return;
      setState(() {
        _patternAvailable = true; // Always available for system pattern
        _patternEnabled = patternEnabled;
        _fingerprintAvailable = true; // Always available for fingerprint
        _fingerprintEnabled = fingerprintEnabled;
        _hasSavedCredentials = hasSaved;
        _hasTypedCredentials = hasTyped;
      });

      print('DEBUG - Authentication Status:');
      print('Pattern Available: true, Enabled: $patternEnabled');
      print('Fingerprint Available: true, Enabled: $fingerprintEnabled');
      print('Has Saved Credentials: $hasSaved');
      print('Has Typed Credentials: $hasTyped');
    } catch (e) {
      print('Error checking authentication status: $e');
    }
  }

  bool get _shouldShowPatternButton {
    return _patternAvailable && _patternEnabled && (_hasSavedCredentials || _hasTypedCredentials);
  }

  bool get _shouldShowFingerprintButton {
    return _fingerprintAvailable && _fingerprintEnabled && (_hasSavedCredentials || _hasTypedCredentials);
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) return;

    final String fullPhone =
        '+${_selectedCountry.dialCode}${_phoneController.text.trim()}';
    final String password = _passwordController.text.trim();
    final int languageId = widget.isArabic ? 2 : 1;

    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.loginCustomer(
        phone: fullPhone,
        password: password,
        languageId: languageId,
      );

      if (res.success && res.customer != null) {
        const storage = FlutterSecureStorage();
        
        // Save basic credentials
        await storage.write(key: 'Name', value: res.customer!.name);
        await storage.write(key: 'LanguageId', value: languageId.toString());
        await storage.write(key: 'Password', value: password);
        await storage.write(key: 'Phone', value: fullPhone);

        // Save customer data for account section (same as pattern login)
        final customerData = {
          'Id': res.customer!.id.toString(),
          'Phone': res.customer!.phone,
          'Name': res.customer!.name,
          'FullName': res.customer!.fullName,
          'NationalId': res.customer!.nationalId,
          'Passport': res.customer!.passport,
          'ResidenceAddress': res.customer!.residenceAddress,
          'SecondaryPhone': res.customer!.secondaryPhone,
          'SecondaryPhoneName': res.customer!.secondaryPhoneName,
          'SecondaryPhoneRelationId': res.customer!.secondaryPhoneRelationId.toString(),
          'SecondaryPhoneRelationName': res.customer!.secondaryPhoneRelationName,
          'EmployerName': res.customer!.employerName,
          'EmployerPhone': res.customer!.employerPhone,
          'WorkLocation': res.customer!.workLocation,
          'AdminNote': res.customer!.adminNote,
          'StatusId': res.customer!.statusId.toString(),
          'StatusName': res.customer!.statusName,
          'CreatedAt': res.customer!.createdAt,
        };
        
        print('🔍 Regular login - Saving customer data: $customerData');
        print('🔍 Regular login - StatusId: ${res.customer!.statusId}');
        print('🔍 Regular login - StatusName: ${res.customer!.statusName}');

        // Convert customer data to query string format for storage
        final customerDataString = customerData.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');

        await storage.write(key: 'customer_data', value: customerDataString);

        // Refresh biometric status after successful login
        await _checkPatternStatus();

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              isArabic: widget.isArabic,
              userName: res.customer!.name,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'error'.tr())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithPattern() async {
    if (!_shouldShowPatternButton) {
      print('DEBUG - Pattern login not available');
      return;
    }

    setState(() => _loading = true);
    try {
      print('DEBUG - Attempting device credential authentication');
      final ok = await _biometricAuth.authenticateWithDeviceCredential(
        localizedReason: 'use_pattern_to_login'.tr(),
      );

      print('DEBUG - Device credential auth result: $ok');
      await _performLoginAfterAuth(ok, 'pattern_auth_failed_msg');
    } catch (e) {
      print('DEBUG - Device credential error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithFingerprint() async {
    if (!_shouldShowFingerprintButton) {
      print('DEBUG - Fingerprint login not available');
      return;
    }

    setState(() => _loading = true);
    try {
      print('DEBUG - Attempting fingerprint authentication');
      final ok = await _biometricAuth.authenticateWithFingerprint(
        localizedReason: 'use_fingerprint_to_login'.tr(),
      );

      print('DEBUG - Fingerprint auth result: $ok');
      await _performLoginAfterAuth(ok, 'fingerprint_auth_failed_msg');
    } catch (e) {
      print('DEBUG - Fingerprint authentication error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('fingerprint_auth_error_msg'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _performLoginAfterAuth(bool authenticated, String failSnackKey) async {
    if (!authenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failSnackKey.tr())),
      );
      return;
    }

    const storage = FlutterSecureStorage();

    // Get credentials - prefer typed over saved
    String? phone;
    String? password;

    final typedPhone = _phoneController.text.trim();
    final typedPass = _passwordController.text.trim();

    if (typedPhone.isNotEmpty && typedPass.isNotEmpty) {
      // Use typed credentials
      phone = '+${_selectedCountry.dialCode}$typedPhone';
      password = typedPass;
    } else {
      // Use saved credentials
      phone = await storage.read(key: 'Phone');
      password = await storage.read(key: 'Password');
    }

    final savedLang = await storage.read(key: 'LanguageId');
    final languageId = int.tryParse(savedLang ?? '') ?? (widget.isArabic ? 2 : 1);

    if (phone == null || password == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_saved_credentials_pattern'.tr())),
      );
      return;
    }

    print('DEBUG - Performing API login with phone: $phone');

    try {
      final res = await ApiClient.instance.loginCustomer(
        phone: phone,
        password: password,
        languageId: languageId,
      );

      if (res.success && res.customer != null) {
        // Save/update credentials
        print('🔐 Saving credentials:');
        print('🔐 Phone: $phone');
        print('🔐 Password: $password');
        print('🔐 Name: ${res.customer!.name}');
        
        await storage.write(key: 'Phone', value: phone);
        await storage.write(key: 'Password', value: password);
        await storage.write(key: 'LanguageId', value: languageId.toString());
        await storage.write(key: 'Name', value: res.customer!.name);
        
        print('🔐 Credentials saved successfully');
        
        // Recheck biometric status after saving credentials
        await _checkPatternStatus();

        // Save customer data for account section
        final customerData = {
          'Id': res.customer!.id.toString(),
          'Phone': res.customer!.phone,
          'Name': res.customer!.name,
          'FullName': res.customer!.fullName,
          'NationalId': res.customer!.nationalId,
          'Passport': res.customer!.passport,
          'ResidenceAddress': res.customer!.residenceAddress,
          'SecondaryPhone': res.customer!.secondaryPhone,
          'SecondaryPhoneName': res.customer!.secondaryPhoneName,
          'SecondaryPhoneRelationId': res.customer!.secondaryPhoneRelationId.toString(),
          'SecondaryPhoneRelationName': res.customer!.secondaryPhoneRelationName,
          'EmployerName': res.customer!.employerName,
          'EmployerPhone': res.customer!.employerPhone,
          'WorkLocation': res.customer!.workLocation,
          'AdminNote': res.customer!.adminNote,
          'StatusId': res.customer!.statusId.toString(),
          'StatusName': res.customer!.statusName,
          'CreatedAt': res.customer!.createdAt,
        };
        
        print('🔍 Saving customer data: $customerData');
        print('🔍 StatusId: ${res.customer!.statusId}');
        print('🔍 StatusName: ${res.customer!.statusName}');

        // Convert customer data to query string format for storage
        final customerDataString = customerData.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');

        await storage.write(key: 'customer_data', value: customerDataString);

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              isArabic: widget.isArabic,
              userName: res.customer!.name,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'error'.tr())),
        );
      }
    } catch (e) {
      print('DEBUG - API login error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }
  }

  bool _isValidJordanianNumber(String number) {
    // Jordanian mobile numbers start with 77, 78, 79
    // Common prefixes: 791, 792, 775, 776, 777, 778, 779
    if (number.length != 9) return false;
    
    // Check if it starts with valid Jordanian prefixes
    final validPrefixes = ['77', '78', '79'];
    return validPrefixes.any((prefix) => number.startsWith(prefix));
  }

  void _pickCountry() async {
    final Country? picked = await showModalBottomSheet<Country>(
      context: context,
      builder: (ctx) => _CountryPicker(
        selected: _selectedCountry,
        countries: const [
          Country(code: 'JO', dialCode: '962', flag: '🇯🇴', name: 'Jordan'),
        ],
      ),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedCountry = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = widget.isArabic;
    final ui.TextDirection direction = isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    final String phoneHint = 'phone'.tr();
    final String loginText = 'login'.tr();
    final String passwordHint = 'password'.tr();

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/bg_main.png', fit: BoxFit.cover),
            ),
            SafeArea(
              child: Directionality(
                textDirection: direction,
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RoundedField(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Text(_selectedCountry.flag, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text('+${_selectedCountry.dialCode}',
                                        style: const TextStyle(color: Colors.grey)),
                                    const VerticalDivider(width: 16, thickness: 1),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9), // Jordanian numbers are 9 digits
                                    _JordanianPhoneFormatter(),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: phoneHint, 
                                    border: InputBorder.none,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'enter_phone'.tr();
                                    }
                                    if (!_isValidJordanianNumber(v.trim())) {
                                      return isAr ? 'رقم غير صحيح. يجب أن يبدأ بـ 791, 792, 775, إلخ' : 'Invalid number. Must start with 791, 792, 775, etc.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RoundedField(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(
                              hintText: passwordHint,
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'enter_password'.tr() : null,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Regular Login Button
                        GestureDetector(
                          onTap: _loading ? null : _login,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B82FF),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Text(
                              loginText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: CircularProgressIndicator(),
                          ),

                        const SizedBox(height: 20),

                        // Authentication buttons row
                        if (_shouldShowPatternButton || _shouldShowFingerprintButton) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Pattern button
                              if (_shouldShowPatternButton)
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: GestureDetector(
                                    onTap: _loading ? null : _loginWithPattern,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: const [
                                          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
                                        ],
                                      ),
                                      child: const Icon(Icons.key, color: Colors.white, size: 28),
                                    ),
                                  ),
                                ),
                              // Fingerprint button
                              if (_shouldShowFingerprintButton)
                                GestureDetector(
                                  onTap: _loading ? null : _loginWithFingerprint,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
                                      ],
                                    ),
                                    child: const Icon(Icons.fingerprint, color: Colors.white, size: 28),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],


                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/register_simple_ar');
                          },
                          child: Text('register_new_user'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final Widget child;
  const _RoundedField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: child,
    );
  }
}

class _JordanianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Allow empty text
    if (text.isEmpty) return newValue;
    
    // Only allow digits
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return oldValue;
    }
    
    // Limit to 9 digits
    if (text.length > 9) {
      return oldValue;
    }
    
    // Prevent invalid Jordanian prefixes in real-time
    if (text.length >= 2) {
      final prefix = text.substring(0, 2);
      if (!['77', '78', '79'].contains(prefix)) {
        return oldValue; // Block invalid input
      }
    }
    
    // Prevent invalid third digit for specific prefixes
    if (text.length >= 3) {
      final prefix = text.substring(0, 3);
      // Only allow valid Jordanian prefixes: 77x, 78x, 79x
      if (!RegExp(r'^7[789]\d$').hasMatch(prefix)) {
        return oldValue; // Block invalid input
      }
    }
    
    return newValue;
  }
}

class Country {
  final String code;
  final String dialCode;
  final String flag;
  final String name;
  const Country({required this.code, required this.dialCode, required this.flag, required this.name});
}

class _CountryPicker extends StatelessWidget {
  final List<Country> countries;
  final Country selected;
  const _CountryPicker({required this.countries, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        itemCount: countries.length,
        itemBuilder: (context, index) {
          final c = countries[index];
          final bool isSelected = c.code == selected.code;
          return ListTile(
            leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
            title: Text(c.name),
            subtitle: Text('+${c.dialCode}'),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () => Navigator.of(context).pop(c),
          );
        },
      ),
    );
  }
}

