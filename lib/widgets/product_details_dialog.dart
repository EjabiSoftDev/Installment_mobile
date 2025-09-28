import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import '../api/api_client.dart';

class ProductDetailsDialog extends StatefulWidget {
  final int productId;
  final bool isArabic;

  const ProductDetailsDialog({
    super.key,
    required this.productId,
    required this.isArabic,
  });

  @override
  State<ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<ProductDetailsDialog> {
  final ApiClient _api = ApiClient.instance;
  Map<String, dynamic>? _productData;
  bool _isLoading = true;
  int _installmentCount = 6; // Default installment count

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      final data = await _api.fetchProductDetails(widget.productId);
      if (mounted) {
        setState(() {
          _productData = data;
          _isLoading = false;
          // Set default installment count to minimum
          _installmentCount = data['MinInstallments'] ?? 6;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _calculateMonthlyPayment() {
    if (_productData == null) return 0.0;
    final minPrice = _productData!['MinSalePrice']?.toDouble() ?? 0.0;
    final maxPrice = _productData!['MaxSalePrice']?.toDouble() ?? 0.0;
    final avgPrice = (minPrice + maxPrice) / 2;
    return avgPrice / _installmentCount;
  }

  Widget _buildStarRating(double? rating) {
    if (rating == null) rating = 0.0;
    final filledStars = rating.floor();
    final hasHalfStar = rating - filledStars >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < filledStars) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index == filledStars && hasHalfStar) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  Future<void> _confirmOrder() async {
    if (_productData == null) return;

    setState(() => _isLoading = true);

    try {
      await _api.createOrder(
        totalAmount: (_installmentCount * _calculateMonthlyPayment()).round().toDouble(),
        itemId: widget.productId,
        numberOfMonths: _installmentCount,
        installmentAmount: _calculateMonthlyPayment(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('order_created_successfully'.tr())),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('order_creation_failed'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = widget.isArabic;
    final ui.TextDirection direction = isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Directionality(
        textDirection: direction,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _productData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'product_not_found'.tr(),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : _buildProductContent(),
      ),
    );
  }

  Widget _buildProductContent() {
    return Column(
      children: [
        // Header with close button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF0B82FF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _productData!['Name'] ?? 'product_details'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Center(
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: _productData!['Images'] != null && 
                           (_productData!['Images'] as List).isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              (_productData!['Images'] as List).first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image, size: 64, color: Colors.grey);
                              },
                            ),
                          )
                        : const Icon(Icons.image, size: 64, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Product Title
                Text(
                  _productData!['Name'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Brand
                if (_productData!['Brand'] != null)
                  Text(
                    'Brand: ${_productData!['Brand']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Star Rating
                Row(
                  children: [
                    Text(
                      'rating'.tr(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    _buildStarRating(_productData!['OverallRating']?.toDouble()),
                    const SizedBox(width: 8),
                    Text(
                      '${_productData!['OverallRating']?.toStringAsFixed(1) ?? '0.0'}/5',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Description
                if (_productData!['Description'] != null && _productData!['Description'].toString().isNotEmpty) ...[
                  Text(
                    'description'.tr(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _productData!['Description'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Price Range
                Text(
                  'price_range'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_productData!['MinSalePrice']?.toStringAsFixed(2) ?? '0.00'} - ${_productData!['MaxSalePrice']?.toStringAsFixed(2) ?? '0.00'} ${'currency'.tr()}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                
                // Installment Controls - Responsive Layout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'installment_options'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Installment Count Control - Responsive Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 300) {
                            // Vertical layout for small screens
                            return Column(
                              children: [
                                Text(
                                  'installment_count'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildControlButton(
                                      icon: Icons.remove,
                                      onTap: _installmentCount > (_productData!['MinInstallments'] ?? 6)
                                          ? () {
                                              setState(() {
                                                _installmentCount--;
                                              });
                                            }
                                          : null,
                                      enabled: _installmentCount > (_productData!['MinInstallments'] ?? 6),
                                    ),
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Text(
                                        '$_installmentCount',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    _buildControlButton(
                                      icon: Icons.add,
                                      onTap: _installmentCount < (_productData!['MaxInstallments'] ?? 24)
                                          ? () {
                                              setState(() {
                                                _installmentCount++;
                                              });
                                            }
                                          : null,
                                      enabled: _installmentCount < (_productData!['MaxInstallments'] ?? 24),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            // Horizontal layout for larger screens
                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'installment_count'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildControlButton(
                                      icon: Icons.remove,
                                      onTap: _installmentCount > (_productData!['MinInstallments'] ?? 6)
                                          ? () {
                                              setState(() {
                                                _installmentCount--;
                                              });
                                            }
                                          : null,
                                      enabled: _installmentCount > (_productData!['MinInstallments'] ?? 6),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Text(
                                        '$_installmentCount',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildControlButton(
                                      icon: Icons.add,
                                      onTap: _installmentCount < (_productData!['MaxInstallments'] ?? 24)
                                          ? () {
                                              setState(() {
                                                _installmentCount++;
                                              });
                                            }
                                          : null,
                                      enabled: _installmentCount < (_productData!['MaxInstallments'] ?? 24),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Payment Information
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('monthly_payment'.tr()),
                                ),
                                Text(
                                  '${_calculateMonthlyPayment().toStringAsFixed(2)} ${'currency'.tr()}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('total'.tr()),
                                ),
                                Text(
                                  '${(_installmentCount * _calculateMonthlyPayment()).toStringAsFixed(2)} ${'currency'.tr()}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _confirmOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B82FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'confirm_and_proceed'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF0B82FF) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}