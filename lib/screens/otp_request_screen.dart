import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'registration_screen.dart';
import 'simple_register_screen.dart';
import '../api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'otp_verify_screen.dart';

class OtpRequestScreen extends StatefulWidget {
  final bool isArabic;
  const OtpRequestScreen({super.key, this.isArabic = false});

  @override
  State<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends State<OtpRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _obscurePassword = true;

  Country _selectedCountry =
      const Country(code: 'JO', dialCode: '962', flag: '🇯🇴', name: 'Jordan');

  @override
  void dispose() {
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _loading = false;

  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true) return;
    final String fullPhone =
        '+${_selectedCountry.dialCode}${_phoneController.text.trim()}';
    final String password = _passwordController.text.trim();
    final int languageId = widget.isArabic ? 1 : 2; // adjust if needed

    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.loginCustomer(
        phone: fullPhone,
        password: password,
        languageId: languageId,
      );
      if (res.success && res.customer != null) {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'Name', value: res.customer!.name);
        await storage.write(key: 'LanguageId', value: languageId.toString());
        await storage.write(key: 'Password', value: password);
        await storage.write(key: 'Phone', value: fullPhone);
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerifyScreen(
              isArabic: widget.isArabic,
              name: res.customer!.name,
              phone: fullPhone,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(res.message.isNotEmpty
                  ? res.message
                  : (widget.isArabic
                      ? 'بيانات غير صحيحة'
                      : 'Invalid phone or password'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      setState(() => _selectedCountry = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = widget.isArabic;
    final ui.TextDirection direction =
        isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final String phoneHint = 'phone'.tr();
    final String loginText = 'login'.tr();
    final String passwordHint = isAr ? 'كلمة المرور' : 'Password';

    return Scaffold(
      body: Stack(
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
                      // Phone first
                      _RoundedField(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pickCountry,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Text(_selectedCountry.flag,
                                        style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text('+${_selectedCountry.dialCode}',
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                    const VerticalDivider(
                                        width: 16, thickness: 1),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textAlign:
                                    isAr ? TextAlign.right : TextAlign.left,
                                decoration: InputDecoration(
                                    hintText: phoneHint,
                                    border: InputBorder.none),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? (isAr
                                            ? 'أدخل رقم الجوال'
                                            : 'Enter phone number')
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Password field at bottom (below phone)
                      _RoundedField(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(
                            hintText: passwordHint,
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (isAr ? 'أدخل كلمة المرور' : 'Enter password')
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _loading ? null : _login,
                        child: Text(
                          loginText,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                      ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: CircularProgressIndicator(),
                        ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SimpleRegisterScreen(isArabic: true),
                            ),
                          );
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
          BoxShadow(
              color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: child,
    );
  }
}

class Country {
  final String code;
  final String dialCode;
  final String flag;
  final String name;
  const Country(
      {required this.code,
      required this.dialCode,
      required this.flag,
      required this.name});
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
            trailing:
                isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () => Navigator.of(context).pop(c),
          );
        },
      ),
    );
  }
}