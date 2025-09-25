

import 'brand.DART';
import 'GroupName.dart';

class Product {
  final int id;
  final String nameAr;
  final String nameEn;
  final String descAr;
  final String descEn;
  final double cost;
  final double minSalePrice;
  final double maxSalePrice;
  final int minInstallments;
  final int maxInstallments;
  final Brand brand;
  final GroupName? mainGroup;
  final GroupName? subGroup;
  final List<String> imageUrls;
  final int reviewsCount;

  const Product({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descAr,
    required this.descEn,
    required this.cost,
    required this.minSalePrice,
    required this.maxSalePrice,
    required this.minInstallments,
    required this.maxInstallments,
    required this.brand,
    required this.mainGroup,
    required this.subGroup,
    required this.imageUrls,
    required this.reviewsCount,
  });

  factory Product.fromJson(Map<String, dynamic> j) {
    double _toD(v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0);
    int _toI(v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

    final imgs = (j['Images'] as List? ?? [])
        .map((x) {
          if (x == null) return null;
          if (x is String) return x;
          if (x is Map && x['Url'] != null) return x['Url'] as String;
          if (x is Map && x['Path'] != null) return x['Path'] as String;
          return null;
        })
        .whereType<String>()
        .toList();

    return Product(
      id: _toI(j['Id']),
      nameAr: (j['Name_ar'] ?? '').toString(),
      nameEn: (j['Name_eng'] ?? '').toString(),
      descAr: (j['Description_ar'] ?? '').toString(),
      descEn: (j['Description_eng'] ?? '').toString(),
      cost: _toD(j['Cost']),
      minSalePrice: _toD(j['MinSalePrice']),
      maxSalePrice: _toD(j['MaxSalePrice']),
      minInstallments: _toI(j['MinInstallments']),
      maxInstallments: _toI(j['MaxInstallments']),
      brand: Brand.fromJson(j['Brand'] ?? const {}),
      mainGroup: j['MainGroup'] == null ? null : GroupName.fromJson(j['MainGroup']),
      subGroup: j['SubGroup'] == null ? null : GroupName.fromJson(j['SubGroup']),
      imageUrls: imgs,
      reviewsCount: _toI(j['ReviewsCount']),
    );
  }
}
