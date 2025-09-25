import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/header.dart';
import '../widgets/search_bar.dart';
// import '../widgets/chips_row.dart';
// import '../widgets/brand_row.dart';
import '../widgets/product_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/common.dart';
import '../api/api_client.dart';
import '../models/product.dart';
import '../models/GroupName.dart';

class CatalogHomeScreen extends StatefulWidget {
  final bool isArabic;
  final String userName;
  const CatalogHomeScreen({super.key, this.isArabic = true, required this.userName});

  @override
  State<CatalogHomeScreen> createState() => _CatalogHomeScreenState();
}

class _CatalogHomeScreenState extends State<CatalogHomeScreen> {
  final _api = ApiClient.instance;

  // One future powers both the sections AND the full list below
  late Future<List<Product>> _future;
  late Future<List<GroupName>> _groupsFuture;

  final _searchCtrl = TextEditingController(text: '');
  Timer? _debounce;

  String? _minPrice;
  String? _maxPrice;
  // Single brand selection (tap to toggle). Keep others visible.
  String? _selectedBrandId;
  String? _mainGroupId;
  String? _subGroupId;
  String? _sortBy;
  String? _sortOrder;
  bool _showBrands = false; // first time: show sections

  @override
  void initState() {
    super.initState();
    _future = _load();
    _groupsFuture = _api.fetchMainGroups();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<List<Product>> _load() => _api.fetchProducts(
        search: _searchCtrl.text,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        brandId: _selectedBrandId,
        mainGroupId: _mainGroupId,
        subGroupId: _subGroupId,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

  void _applyFilters() => setState(() => _future = _load());

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  Future<void> _showFilterDialog() async {
    final TextEditingController minCtrl = TextEditingController(text: _minPrice ?? '');
    final TextEditingController maxCtrl = TextEditingController(text: _maxPrice ?? '');
    String? sortLocal = _sortOrder; // 'asc' | 'desc' | null

    final bool isAr = widget.isArabic;
    final String title = isAr ? 'تصفية المنتجات' : 'Filter products';
    final String min = isAr ? 'أقل سعر' : 'Min price';
    final String max = isAr ? 'أعلى سعر' : 'Max price';
    final String sort = isAr ? 'الترتيب' : 'Sort';
    final String lowHigh = isAr ? 'الأدنى إلى الأعلى' : 'Lowest to Highest';
    final String highLow = isAr ? 'الأعلى إلى الأدنى' : 'Highest to Lowest';
    final String apply = isAr ? 'تطبيق' : 'Apply';
    final String clear = isAr ? 'مسح' : 'Clear';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: min),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: max),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(sort, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: 'asc',
                groupValue: sortLocal,
                onChanged: (v) => setState(() => sortLocal = v),
                title: Text(lowHigh),
                dense: true,
              ),
              RadioListTile<String>(
                value: 'desc',
                groupValue: sortLocal,
                onChanged: (v) => setState(() => sortLocal = v),
                title: Text(highLow),
                dense: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _minPrice = null;
                  _maxPrice = null;
                  _sortBy = null;
                  _sortOrder = null;
                });
                Navigator.of(ctx).pop();
                _applyFilters();
              },
              child: Text(clear),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _minPrice = minCtrl.text.trim().isEmpty ? null : minCtrl.text.trim();
                  _maxPrice = maxCtrl.text.trim().isEmpty ? null : maxCtrl.text.trim();
                  _sortBy = 'price';
                  _sortOrder = sortLocal;
                });
                Navigator.of(ctx).pop();
                _applyFilters();
              },
              child: Text(apply),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    final direction = isAr ? TextDirection.rtl : TextDirection.ltr;
    final hello = isAr ? 'مرحبا ${widget.userName}' : 'Hello ${widget.userName}';
    final subHello = isAr ? 'عمان، الأردن' : 'Amman, Jordan';
    final chooseUnavailable =
        isAr ? 'اشترِ منتج غير متوفر في التطبيق' : 'Buy a product not in the app';
    final categories = isAr ? 'الأصناف' : 'Categories';
    final brandsTitle = isAr ? 'الماركات' : 'Brands';
    final more = isAr ? 'اختر' : 'Choose';
    final allResults = isAr ? 'كل النتائج' : 'All Results';

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
                    // Submit (keyboard search) triggers the API fetch
                    SearchBarBox(
                      controller: _searchCtrl,
                      onChanged: (_) => _onSearchChanged(),
                      onSubmitted: (_) => _applyFilters(),
                      onSearchTap: _applyFilters,
                    ),
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
                    Align(
                      alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                      child: InkWell(
                        onTap: _showFilterDialog,
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
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Toggle between Sections and Brands
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text(categories),
                          selected: !_showBrands,
                          onSelected: (_) {
                            setState(() {
                              _showBrands = false;
                              _selectedBrandId = null; // only section filter applies
                            });
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(brandsTitle),
                          selected: _showBrands,
                          onSelected: (_) {
                            setState(() {
                              _showBrands = true;
                              _mainGroupId = null; // only brand filter applies
                            });
                            _applyFilters();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Show Brands row only when Brands tab is active
                    if (_showBrands) ...[
                      TitleRow(title: brandsTitle),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Product>>(
                        future: _future,
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox.shrink();
                          final items = snap.data!;
                          final byId = <int, Map<String, String?>>{}; // id -> {name, logo}
                          for (final p in items) {
                            final b = p.brand;
                            byId[b.id] = {
                              'name': b.name,
                              'logo': b.logo,
                            };
                          }
                          if (byId.isEmpty) return const SizedBox.shrink();
                          return SizedBox(
                            height: 116,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              scrollDirection: Axis.horizontal,
                              itemCount: byId.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final id = byId.keys.elementAt(i);
                                final data = byId[id]!;
                                final selected = _selectedBrandId == id.toString();
                                final label = data['name'] ?? '';
                                final logo = data['logo'];
                                return _BrandCard(
                                  label: label,
                                  logoUrl: _api.toAbsolute(logo ?? ''),
                                  selected: selected,
                                  onTap: () {
                                    setState(() {
                                      _showBrands = true; // keep brands visible
                                      final key = id.toString();
                                      if (_selectedBrandId == key) {
                                        _selectedBrandId = null; // toggle off
                                      } else {
                                        _selectedBrandId = key; // select exclusively
                                      }
                                    });
                                    _applyFilters();
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Show Sections row only when Sections tab is active
                    if (!_showBrands) ...[
                      TitleRow(title: categories),
                      const SizedBox(height: 10),
                    ],
                    // Categories from API: /api/Products/main-groups
                    if (!_showBrands) FutureBuilder<List<GroupName>>(
                      future: _groupsFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        final items = snap.data ?? [];
                        if (items.isEmpty) return const SizedBox.shrink();
                        return SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final g = items[i];
                              final String id = g.id.toString();
                              final String label = isAr ? g.nameAr : g.nameEn;
                               final bool selected = _mainGroupId == id;
                              return ChoiceChip(
                                label: Text(label),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    if (_mainGroupId == id) {
                                      _mainGroupId = null; // toggle off
                                    } else {
                                      _mainGroupId = id; // toggle on
                                    }
                                  });
                                  _applyFilters();
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Product>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return ErrorBox(
                            message: isAr ? 'حدث خطأ أثناء تحميل المنتجات' : 'Failed to load products',
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

/// Groups products by MainGroup and renders a horizontal scroller per section.
/// If you prefer grouping by SubGroup or Brand, switch the key below.
class DynamicSections extends StatelessWidget {
  final List<Product> products;
  final bool isArabic;
  final String moreText;

  const DynamicSections({
    super.key,
    required this.products,
    required this.isArabic,
    required this.moreText,
  });

  @override
  Widget build(BuildContext context) {
    // Group by MainGroup name (localized)
    final Map<String, List<Product>> groups = {};
    for (final p in products) {
      final groupName = _mainGroupName(p);
      groups.putIfAbsent(groupName, () => []).add(p);
    }

    // Optional: stable section order (alphabetical)
    final sectionKeys = groups.keys.toList()..sort((a, b) => a.compareTo(b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final key in sectionKeys) ...[
          TitleRow(title: key),
          const SizedBox(height: 10),
          SizedBox(
            height: 260, // fits typical ProductCard height; tune as needed
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: groups[key]!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final p = groups[key]![i];
                return SizedBox(
                  width: 180, // card width for horizontal layout
                  child: ProductCard.fromProduct(
                    p: p,
                    isArabic: isArabic,
                    moreText: moreText,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ]
      ],
    );
  }

  String _mainGroupName(Product p) {
    final String? ar = p.mainGroup?.nameAr;
    final String? en = p.mainGroup?.nameEn;
    if (isArabic) return ar ?? en ?? 'غير مصنف';
    return en ?? ar ?? 'Uncategorized';
  }
}

class _BrandCard extends StatelessWidget {
  final String label;
  final String logoUrl;
  final bool selected;
  final VoidCallback onTap;
  const _BrandCard({required this.label, required this.logoUrl, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0B82FF) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF5FBFF),
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 6, offset: Offset(0, 3))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  width: 36,
                  height: 36,
                  cacheWidth: 144,
                  cacheHeight: 144,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
