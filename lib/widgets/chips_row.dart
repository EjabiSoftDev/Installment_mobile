import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ChipsRow extends StatelessWidget {
  final bool isArabic;
  final VoidCallback? onFilterTap;
  const ChipsRow({super.key, required this.isArabic, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    final a = 'installment_category'.tr();
    final b = 'brand_category'.tr();
    return Row(
      children: [
        _Chip(text: a, icon: Icons.check_circle),
        const SizedBox(width: 8),
        _Chip(text: b, icon: Icons.label),
        const Spacer(),
        _FilterButton(onTap: onFilterTap),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Chip({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0B82FF)),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _FilterButton({this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: const Icon(Icons.tune, color: Color(0xFF0B82FF)),
      ),
    );
  }
}
