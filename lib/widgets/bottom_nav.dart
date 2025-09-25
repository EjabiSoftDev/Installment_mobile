import 'package:flutter/material.dart';
import '../screens/registration_screen.dart';

class BottomNav extends StatelessWidget {
  final bool isArabic;
  const BottomNav({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final i1 = isArabic ? 'الرئيسية' : 'Home';
    final i2 = isArabic ? 'طلباتي' : 'Orders';
    final i3 = isArabic ? 'أقساطي' : 'Installments';
    final i4 = isArabic ? 'حسابي' : 'Account';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _BottomItem(icon: Icons.home, label: 'الرئيسية', selected: true),
          const _BottomItem(icon: Icons.assignment, label: 'طلباتي'),
          const _BottomItem(icon: Icons.credit_card, label: 'أقساطي'),
          _BottomItem(
            icon: Icons.person,
            label: i4,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RegistrationScreen(isArabic: isArabic),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _BottomItem({required this.icon, required this.label, this.selected = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? const Color(0xFF0B82FF) : Colors.grey),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: selected ? const Color(0xFF0B82FF) : Colors.grey, fontSize: 12)),
      ],
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: content));
  }
}
