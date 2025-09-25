import 'package:flutter/material.dart';

class BrandRow extends StatelessWidget {
  final bool isArabic;
  final ValueChanged<int?>? onBrandSelected;
  const BrandRow({super.key, required this.isArabic, this.onBrandSelected});

  @override
  Widget build(BuildContext context) {
    // Example IDs: adapt to your backend IDs if different.
    final items = [
      _BrandItem(label: isArabic ? 'هواوي' : 'Huawei', icon: Icons.public, id: 2),
      _BrandItem(label: isArabic ? 'سامسونج' : 'Samsung', icon: Icons.blur_circular, id: 1),
      _BrandItem(label: isArabic ? 'آيفون' : 'Apple', icon: Icons.apple, id: 3, highlighted: true),
    ];
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onBrandSelected?.call(items[i].id),
          child: items[i],
        ),
      ),
    );
  }
}

class _BrandItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlighted;
  final int id;
  const _BrandItem({
    required this.label,
    required this.icon,
    required this.id,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration:
                BoxDecoration(color: const Color(0xFFF5FBFF), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon,
                color: highlighted ? const Color(0xFF0B82FF) : Colors.black87, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
