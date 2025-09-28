import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import '../widgets/header.dart';
import '../widgets/common.dart';
import '../api/api_client.dart';
import '../models/order.dart';

class OrdersScreen extends StatefulWidget {
  final bool isArabic;
  final String userName;
  final bool showHeader;
  const OrdersScreen({
    super.key, 
    this.isArabic = true, 
    required this.userName,
    this.showHeader = true,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _api = ApiClient.instance;
  late Future<List<Order>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;
    final direction = isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final hello = 'hello_name'.tr(namedArgs: {'name': widget.userName});
    final subHello = 'orders'.tr();

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.showHeader) ...[
                      Header(hello: hello, subHello: subHello),
                      const SizedBox(height: 16),
                    ],
                    FutureBuilder<List<Order>>(
                      future: _future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return ErrorBox(
                            message: 'order_error'.tr(),
                            onRetry: () => setState(() => _future = _api.fetchOrders()),
                          );
                        }
                        final items = snap.data ?? [];
                        if (items.isEmpty) {
                          return EmptyBox(text: 'no_orders_found'.tr());
                        }
                        return Column(
                          children: [
                            for (final o in items) _OrderCard(isArabic: isAr, order: o),
                          ],
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
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final bool isArabic;
  final Order order;
  const _OrderCard({required this.isArabic, required this.order});

  @override
  Widget build(BuildContext context) {
    final title = order.productName;
    final status = order.statusName;
    final created = order.createdDate;
    final total = order.totalAmount;
    final months = order.numberOfMonths;
    final installment = order.installmentAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag, color: Color(0xFF0B82FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip(text: status, color: const Color(0xFF0B82FF)),
                    const SizedBox(width: 8),
                    _Chip(text: '${months}m', color: const Color(0xFF4CAF50)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic
                      ? '${'installment'.tr()}: ${installment.toStringAsFixed(0)} | ${'total'.tr()}: ${total.toStringAsFixed(0)}'
                      : '${'installment'.tr()}: ${installment.toStringAsFixed(0)} | ${'total'.tr()}: ${total.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? '${'created'.tr()}: ${created.toString().split('T').first}'
                      : '${'created'.tr()}: ${created.toString().split('T').first}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  const _Chip({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}


