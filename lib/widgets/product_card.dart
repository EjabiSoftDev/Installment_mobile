import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/product.dart';
import '../api/api_client.dart';
import 'product_details_dialog.dart';

class ProductCard extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final int? productId;
  final bool isArabic;
  final double minSalePrice;
  final double maxSalePrice;
  final int minInstallments;
  final int maxInstallments;
  final double? overallRating;
  final String brandName;

  const ProductCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.productId,
    required this.isArabic,
    required this.minSalePrice,
    required this.maxSalePrice,
    required this.minInstallments,
    required this.maxInstallments,
    this.overallRating,
    required this.brandName,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();

  factory ProductCard.fromProduct({
    required Product p,
    required bool isArabic,
  }) {
    final title = isArabic && p.nameAr.isNotEmpty ? p.nameAr : (p.nameEn.isNotEmpty ? p.nameEn : p.brand.name);

    final img = p.imageUrls.isNotEmpty
        ? ApiClient.instance.toAbsolute(p.imageUrls.first)
        : null;

    return ProductCard(
      title: title,
      imageUrl: img?.isEmpty == true ? null : img,
      productId: p.id,
      isArabic: isArabic,
      minSalePrice: p.minSalePrice,
      maxSalePrice: p.maxSalePrice,
      minInstallments: p.minInstallments,
      maxInstallments: p.maxInstallments,
      overallRating: p.overallRating,
      brandName: p.brand.name,
    );
  }
}

class _ProductCardState extends State<ProductCard> {
  int _installmentCount = 6; // Default installment count

  double _calculateMonthlyPayment() {
    return widget.minSalePrice / _installmentCount;
  }

  Widget _buildStarRating(double? rating) {
    if (rating == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) => const Icon(
          Icons.star_border,
          color: Colors.amber,
          size: 12,
        )),
      );
    }

    final fullStars = rating.floor();
    final hasHalfStar = rating - fullStars >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full stars
        ...List.generate(fullStars, (index) => const Icon(
          Icons.star,
          color: Colors.amber,
          size: 12,
        )),
        // Half star
        if (hasHalfStar) const Icon(
          Icons.star_half,
          color: Colors.amber,
          size: 12,
        ),
        // Empty stars
        ...List.generate(emptyStars, (index) => const Icon(
          Icons.star_border,
          color: Colors.amber,
          size: 12,
        )),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showProductDetails(BuildContext context) {
    if (widget.productId != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          child: ProductDetailsDialog(
            productId: widget.productId!,
            isArabic: widget.isArabic,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProductDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5FBFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.imageUrl == null
                    ? const Icon(Icons.phone_iphone, size: 50, color: Color(0xFF0B82FF))
                    : Image.network(widget.imageUrl!, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Product Title
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            
            const SizedBox(height: 2),
            
            // Brand Name
            Text(
              widget.brandName,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Star Rating
            _buildStarRating(widget.overallRating),
            
            const SizedBox(height: 4),
            
            // Price Range
            Text(
              '${widget.minSalePrice.toStringAsFixed(0)} - ${widget.maxSalePrice.toStringAsFixed(0)} ${'currency'.tr()}',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Installment Controls - Compact
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'installment_count'.tr(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _installmentCount > widget.minInstallments
                          ? () {
                              setState(() {
                                _installmentCount--;
                              });
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _installmentCount > widget.minInstallments
                              ? const Color(0xFF0B82FF)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _installmentCount.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _installmentCount < widget.maxInstallments
                          ? () {
                              setState(() {
                                _installmentCount++;
                              });
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _installmentCount < widget.maxInstallments
                              ? const Color(0xFF0B82FF)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Monthly Payment
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'monthly_payment'.tr(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  '${_calculateMonthlyPayment().toStringAsFixed(0)} ${'currency'.tr()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // More Details Button
            SizedBox(
              height: 24,
              child: ElevatedButton(
                onPressed: () => _showProductDetails(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B82FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'more_details'.tr(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
