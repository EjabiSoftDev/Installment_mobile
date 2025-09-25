import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import '../api/api_client.dart';

class SecondaryOtpDialog extends StatefulWidget {
  final String phone;
  final int customerId;
  const SecondaryOtpDialog({super.key, required this.phone, required this.customerId});

  @override
  State<SecondaryOtpDialog> createState() => _SecondaryOtpDialogState();
}

class _SecondaryOtpDialogState extends State<SecondaryOtpDialog> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  bool _loading = false;
  int _secondsLeft = 60;
  bool _resending = false;
  String? _serverOtp; // optional display/debug
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() {});
        return;
      }
      setState(() {
        _secondsLeft -= 1;
      });
    });
  }

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text.trim()).join();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('enter_otp'.tr())));
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await ApiClient.instance.verifySecondaryOtp(
        customerId: widget.customerId,
        secondaryPhone: widget.phone,
        otp: code,
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final resp = await ApiClient.instance.sendSecondaryOtp(
        customerId: widget.customerId,
        secondaryPhone: widget.phone,
      );
      if (!mounted) return;
      _serverOtp = resp['Otp']?.toString();
      _startTimer();
      final m = 'otp_sent'.tr();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _resending = false);
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
            children: List.generate(6, (i) => _OtpCircleField(controller: _controllers[i])),
          ),
          const SizedBox(height: 8),
          Text(
            _secondsLeft > 0 ? tr('resend_in_secs', args: [_secondsLeft.toString()]) : tr('you_can_resend'),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (_secondsLeft == 0)
            TextButton(
              onPressed: _resending ? null : _resend,
              child: _resending ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text('resend_otp'.tr()),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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


