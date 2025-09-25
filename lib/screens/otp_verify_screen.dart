import 'package:flutter/material.dart';
import 'catalog_home_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import '../api/api_client.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class OtpVerifyScreen extends StatefulWidget {
  final bool isArabic;
  final String name;
  final String phone;

  const OtpVerifyScreen({
    super.key,
    required this.isArabic,
    required this.name,
    required this.phone,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  int _secondsLeft = 0;
  Timer? _timer;
  final List<String> _lastValues = List.filled(6, '');

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isArabic
                ? 'أدخل رمز التحقق (6 أرقام)'
                : 'Enter 6-digit code')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final success =
          await ApiClient.instance.verifyOtp(phone: widget.phone, otp: code);
      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CatalogHomeScreen(
              isArabic: widget.isArabic,
              userName: widget.name,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isArabic
                  ? 'رمز غير صالح'
                  : 'Invalid or expired OTP')),
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

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;
    try {
      final success = await ApiClient.instance
          .sendOtp(phone: widget.phone, name: widget.name);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isArabic ? 'تم إرسال رمز جديد' : 'OTP resent')),
        );
        _startCooldown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.isArabic
                  ? 'تعذر إرسال الرمز'
                  : 'Failed to resend OTP')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hello = tr('hello_name', namedArgs: {'name': widget.name});
    final verifyText = 'otp_verify'.tr();

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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hello,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double spacing = 10;
                        final double totalSpacing = spacing * 5;
                        final double size =
                            (constraints.maxWidth - totalSpacing) / 6;
                        final double itemSize = size.clamp(36.0, 48.0);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            return Padding(
                              padding:
                                  EdgeInsets.only(right: i == 5 ? 0 : spacing),
                              child: _OtpCircleField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                size: itemSize,
                                onChanged: (value) {
                                  final v = value.trim();
                                  if (v.isNotEmpty) {
                                    _controllers[i].text =
                                        v.substring(v.length - 1);
                                    _controllers[i].selection =
                                        const TextSelection.collapsed(
                                            offset: 1);
                                    _lastValues[i] = _controllers[i].text;
                                    if (i < 5) {
                                      _focusNodes[i + 1].requestFocus();
                                    } else {
                                      _focusNodes[i].unfocus();
                                    }
                                  } else {
                                    // Deletion: if this field previously had a value, just clear and stay
                                    if (_lastValues[i].isNotEmpty) {
                                      _lastValues[i] = '';
                                    } else if (i > 0) {
                                      // Already empty: move to previous and clear it
                                      _focusNodes[i - 1].requestFocus();
                                      _controllers[i - 1].clear();
                                      _lastValues[i - 1] = '';
                                    }
                                  }
                                },
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 160,
                      child: ElevatedButton(
                        onPressed: _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(verifyText),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _secondsLeft > 0 ? null : _resendOtp,
                      child: Text(
                        _secondsLeft > 0
                            ? (widget.isArabic
                                ? 'إعادة الإرسال خلال ${_secondsLeft}s'
                                : 'Resend in ${_secondsLeft}s')
                            : (widget.isArabic
                                ? 'إعادة إرسال الرمز'
                                : 'Resend code'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpCircleField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final double size;
  final VoidCallback? onBackspaceEmpty;
  const _OtpCircleField(
      {required this.controller,
      required this.focusNode,
      required this.onChanged,
      required this.size,
      this.onBackspaceEmpty});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE9F0FF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: size * 0.5,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
