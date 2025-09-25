import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../api/api_client.dart';
import '../screens/catalog_home_screen.dart';

class OtpDialog extends StatefulWidget {
  final String phone;
  final String name;
  const OtpDialog({super.key, required this.phone, required this.name});

  @override
  State<OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<OtpDialog> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  bool _loading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

Future<void> _verify() async {
  final code = _controllers.map((c) => c.text.trim()).join();
  if (code.length != 6) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('enter_otp'.tr())));
    return;
  }

  setState(() => _loading = true);
  try {
    final ok = await ApiClient.instance.verifyOtp(
      phone: widget.phone,
      otp: code,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(); 
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CatalogHomeScreen(isArabic: true, userName: widget.name),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final verifyText = 'otp_verify'.tr();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'enter_otp'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (i) => _OtpCircleField(controller: _controllers[i]),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: _loading ? null : _verify,
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
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(verifyText),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpCircleField extends StatelessWidget {
  final TextEditingController controller;
  const _OtpCircleField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFE9F0FF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
