import 'package:flutter/material.dart';

class CatalogHomeScreen extends StatelessWidget {
  final bool isArabic;
  final String userName;
  const CatalogHomeScreen({super.key, this.isArabic = true, this.userName = 'خالد'});

  @override
  Widget build(BuildContext context) {
    final bool isAr = isArabic;
    final TextDirection direction = isAr ? TextDirection.rtl : TextDirection.ltr;
    final String hello = isAr ? 'مرحبا $userName' : 'Hello $userName';
    final String subHello = isAr ? 'عمان، الأردن' : 'Amman, Jordan';
    final String chooseUnavailable = isAr ? 'اشترِ منتج غير متوفر في التطبيق' : 'Buy a product not in the app';
    final String categories = isAr ? 'الأصناف' : 'Categories';
    final String iphoneSection = isAr ? 'آيفون' : 'iPhone';
    final String more = isAr ? 'اختر' : 'Choose';

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
                    _Header(hello: hello, subHello: subHello),
                    const SizedBox(height: 12),
                    _SearchBar(),
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
                    _ChipsRow(isArabic: isAr),
                    const SizedBox(height: 10),
                    _TitleRow(title: categories),
                    const SizedBox(height: 12),
                    _BrandRow(isArabic: isAr),
                    const SizedBox(height: 16),
                    _TitleRow(title: iphoneSection),
                    const SizedBox(height: 12),
                    _ProductGrid(moreText: more),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNav(isArabic: isAr),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String hello;
  final String subHello;
  const _Header({required this.hello, required this.subHello});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hello,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                subHello,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        const CircleAvatar(radius: 18, backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF0B82FF))),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '....',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final bool isArabic;
  const _ChipsRow({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final a = isArabic ? 'تصنيف الأقساط' : 'Installment';
    final b = isArabic ? 'تصنيف العلامة التجارية' : 'Brand';
    return Row(
      children: [
        _Chip(text: a, icon: Icons.check_circle),
        const SizedBox(width: 8),
        _Chip(text: b, icon: Icons.label),
        const Spacer(),
        const _FilterButton(),
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
      child: Row(children: [Icon(icon, size: 16, color: const Color(0xFF0B82FF)), const SizedBox(width: 6), Text(text)]),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: const Icon(Icons.tune, color: Color(0xFF0B82FF)),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String title;
  const _TitleRow({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0B2A5B))),
      ],
    );
  }
}

class _BrandRow extends StatelessWidget {
  final bool isArabic;
  const _BrandRow({required this.isArabic});
  @override
  Widget build(BuildContext context) {
    final items = [
      _BrandItem(label: isArabic ? 'هواوي' : 'Huawei', color: const Color(0xFFF5FBFF), icon: Icons.public, count: 360),
      _BrandItem(label: isArabic ? 'سامسونج' : 'Samsung', color: const Color(0xFFF5FBFF), icon: Icons.blur_circular, count: 24),
      _BrandItem(label: isArabic ? 'آيفون' : 'Apple', color: const Color(0xFFE1F0FF), icon: Icons.apple, count: 109, highlighted: true),
    ];
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) => items[i],
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }
}

class _BrandItem extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final int count;
  final bool highlighted;
  const _BrandItem({required this.label, required this.color, required this.icon, required this.count, this.highlighted = false});

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
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: highlighted ? const Color(0xFF0B82FF) : Colors.black87, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final String moreText;
  const _ProductGrid({required this.moreText});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => _ProductCard(moreText: moreText),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String moreText;
  const _ProductCard({required this.moreText});
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
              child: const Icon(Icons.phone_iphone, size: 60, color: Color(0xFF0B82FF)),
            ),
          ),
          const SizedBox(height: 8),
          const Text('آبل آيفون 13 برو ماكس', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF0B82FF)),
              SizedBox(width: 6),
              Text('10+'),
              Spacer(),
              Text('أقساط', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('دينار 1000', style: TextStyle(color: Colors.black87, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('قيمة القسط الشهري 100', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          const Text('المجموع 1100', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

class _BottomNav extends StatelessWidget {
  final bool isArabic;
  const _BottomNav({required this.isArabic});
  @override
  Widget build(BuildContext context) {
    final i1 = isArabic ? 'الرئيسية' : 'Home';
    final i2 = isArabic ? 'طلباتي' : 'Orders';
    final i3 = isArabic ? 'أقساطي' : 'Installments';
    final i4 = isArabic ? 'حسابي' : 'Account';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, -2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomItem(icon: Icons.home, label: i1, selected: true),
          _BottomItem(icon: Icons.assignment, label: i2),
          _BottomItem(icon: Icons.credit_card, label: i3),
          _BottomItem(icon: Icons.person, label: i4),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  const _BottomItem({required this.icon, required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? const Color(0xFF0B82FF) : Colors.grey),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: selected ? const Color(0xFF0B82FF) : Colors.grey, fontSize: 12)),
      ],
    );
  }
}


