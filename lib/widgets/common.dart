import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TitleRow extends StatelessWidget {
  final String title;
  const TitleRow({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0B2A5B))),
      ],
    );
  }
}

class EmptyBox extends StatelessWidget {
  final String text;
  const EmptyBox({super.key, required this.text});
  @override
  Widget build(BuildContext context) =>
      Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(text)));
}

class ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorBox({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(message),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: Text('retry'.tr())),
          ],
        ),
      ),
    );
  }
}
