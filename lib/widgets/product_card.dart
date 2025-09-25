import 'package:flutter/material.dart';
import '../models/product.dart';
import '../api/api_client.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String priceText;
  final String monthlyText;
  final String totalText;
  final String installmentsText;
  final String moreText;
  final String? imageUrl;

  const ProductCard({
    super.key,
    required this.title,
    required this.priceText,
    required this.monthlyText,
    required this.totalText,
    required this.installmentsText,
    required this.moreText,
    required this.imageUrl,
  });

  factory ProductCard.fromProduct({
    required Product p,
    required bool isArabic,
    required String moreText,
  }) {
    String fmt(num n) => n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
    final monthly = (p.minSalePrice / (p.maxInstallments == 0 ? 1 : p.maxInstallments));
    final total = p.minSalePrice;

    final title =
        isArabic && p.nameAr.isNotEmpty ? p.nameAr : (p.nameEn.isNotEmpty ? p.nameEn : p.brand.name);

    final priceText = (isArabic ? 'دينار ' : 'JOD ') +
        (p.minSalePrice == p.maxSalePrice
            ? fmt(p.minSalePrice)
            : '${fmt(p.minSalePrice)} - ${fmt(p.maxSalePrice)}');

    final installmentsText =
        isArabic ? '${p.minInstallments}+ أقساط' : '${p.minInstallments}+ installments';

    final monthlyText =
        isArabic ? 'قيمة القسط الشهري ${fmt(monthly)}' : 'Monthly payment ${fmt(monthly)}';

    final totalText = isArabic ? 'المجموع ${fmt(total)}' : 'Total ${fmt(total)}';

    final img = p.imageUrls.isNotEmpty
        ? ApiClient.instance.toAbsolute(p.imageUrls.first)
        : null;

    return ProductCard(
      title: title,
      priceText: priceText,
      monthlyText: monthlyText,
      totalText: totalText,
      installmentsText: installmentsText,
      moreText: moreText,
      imageUrl: img?.isEmpty == true ? null : img,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5FBFF),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl == null
                  ? const Icon(Icons.phone_iphone, size: 60, color: Color(0xFF0B82FF))
                  : Image.network(imageUrl!, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
            ),
          ),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF0B82FF)),
              const SizedBox(width: 6),
              Text(installmentsText.split(' ').first),
              const Spacer(),
              Text(
                installmentsText.contains('أقساط') ? 'أقساط' : 'Installments',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(priceText, style: const TextStyle(color: Colors.black87, fontSize: 12)),
          const SizedBox(height: 4),
          Text(monthlyText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(totalText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B82FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(moreText),
            ),
          ),
        ],
      ),
    );
  }
}
