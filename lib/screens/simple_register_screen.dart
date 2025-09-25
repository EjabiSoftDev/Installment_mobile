import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/otpDialogsRegister.dart';

class InitialRegisterScreen extends StatefulWidget {
  const InitialRegisterScreen({super.key});

  @override
  State<InitialRegisterScreen> createState() => _InitialRegisterScreen();
}

class _InitialRegisterScreen extends State<InitialRegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _deviceSerial;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDeviceSerial();
  }

  Future<void> _loadDeviceSerial() async {
    final info = DeviceInfoPlugin();
    String? serial;
    try {
      final android = await info.androidInfo;
      serial = android.id; // ANDROID_ID as a stable identifier
    } catch (_) {
      try {
        final ios = await info.iosInfo;
        serial = ios.identifierForVendor;
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _deviceSerial = serial);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.registerCustomer(
        phone: _phoneController.text.trim(),
        name: _nameController.text.trim(),
        phoneSerial: _deviceSerial,
        password: _passwordController.text,
      );

      if (!mounted) return;
      if (res.success) {
        final sentTo =  _phoneController.text.trim();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => OtpDialog(
            phone: sentTo,
            name: _nameController.text.trim(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message.isEmpty ? 'Request failed' : res.message,
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final phoneHint = 'phone_with_cc'.tr();
    final nameHint = 'name'.tr();
    final passwordHint = 'password'.tr();
    final submit = 'continue'.tr();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_main.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RoundedField(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: phoneHint,
                              border: InputBorder.none,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'enter_phone'.tr()
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: nameHint,
                              border: InputBorder.none,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'enter_name'.tr()
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: passwordHint,
                              border: InputBorder.none,
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'enter_password'.tr()
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 220,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(submit),
                          ),
                        ),
                      ],
                    ),
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
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: child,
    );
  }
}
