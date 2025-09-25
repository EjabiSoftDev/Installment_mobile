import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/search_bar.dart';
import '../widgets/chips_row.dart';
import '../widgets/brand_row.dart';
import '../widgets/product_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';
import '../api/api_client.dart';
import '../models/product.dart';

class CatalogHomeScreen extends StatefulWidget {
  final bool isArabic;
  final String userName=user;
  const CatalogHomeScreen({super.key});

  @override
  State<CatalogHomeScreen> createState() => _CatalogHomeScreenState();
}

class _CatalogHomeScreenState extends State<CatalogHomeScreen> {
  final _api = ApiClient.instance;
  late Future<List<Product>> _future;
  final _searchCtrl = TextEditingController(text: 'Sam');

  String? _minPrice;
  String? _maxPrice = '3500';
  String? _brandId;
  String? _mainGroupId = '1';
  String? _subGroupId = '1';
  String? _sortBy;
  String? _sortOrder;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Product>> _load() => _api.fetchProducts(
        search: _searchCtrl.text,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        brandId: _brandId,
        mainGroupId: _mainGroupId,
        subGroupId: _subGroupId,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

  void _applyFilters() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    final direction = isAr ? TextDirection.rtl : TextDirection.ltr;
    final hello = isAr ? 'مرحبا ${widget.userName}' : 'Hello ${widget.userName}';
    final subHello = isAr ? 'عمان، الأردن' : 'Amman, Jordan';
    final chooseUnavailable =
        isAr ? 'اشترِ منتج غير متوفر في التطبيق' : 'Buy a product not in the app';
    final categories = isAr ? 'الأصناف' : 'Categories';
    final iphoneSection = isAr ? 'آيفون' : 'iPhone';
    final more = isAr ? 'اختر' : 'Choose';

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FF),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/images/bg_main.png', fit: BoxFit.cover),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Header(hello: hello, subHello: subHello),
                    const SizedBox(height: 12),
                    SearchBarBox(controller: _searchCtrl, onSubmitted: (_) => _applyFilters()),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B82FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(chooseUnavailable),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ChipsRow(
                      isArabic: isAr,
                      onFilterTap: () {
                        _minPrice = null;
                        _maxPrice = '3500';
                        _brandId = null;
                        _mainGroupId = '1';
                        _subGroupId = '1';
                        _sortBy = null;
                        _sortOrder = null;
                        _applyFilters();
                      },
                    ),
                    const SizedBox(height: 10),
                    TitleRow(title: categories),
                    const SizedBox(height: 12),
                    BrandRow(
                      isArabic: isAr,
                      onBrandSelected: (id) {
                        _brandId = id?.toString();
                        _applyFilters();
                      },
                    ),
                    const SizedBox(height: 16),
                    TitleRow(title: iphoneSection),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Product>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return ErrorBox(
                            message: isAr
                                ? 'حدث خطأ أثناء تحميل المنتجات'
                                : 'Failed to load products',
                            onRetry: _applyFilters,
                          );
                        }
                        final items = snap.data ?? [];
                        if (items.isEmpty) {
                          return EmptyBox(text: isAr ? 'لا توجد نتائج' : 'No results');
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, i) => ProductCard.fromProduct(
                            p: items[i],
                            isArabic: isAr,
                            moreText: more,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNav(isArabic: isAr),
      ),
    );
  }
}
