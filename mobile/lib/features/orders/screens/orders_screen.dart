import 'package:flutter/material.dart';

enum OrderStatus { all, pending, confirmed, shipped, delivered, canceled }
extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.all => 'الكل',
    OrderStatus.pending => 'قيد المعالجة',
    OrderStatus.confirmed => 'مؤكد',
    OrderStatus.shipped => 'تم الشحن',
    OrderStatus.delivered => 'تم التسليم',
    OrderStatus.canceled => 'أُلغي',
  };
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus filter = OrderStatus.all;

  @override
  Widget build(BuildContext context) {
    final orders = <Map<String, dynamic>>[]; // TODO: bind to repo
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلباتي')),
        body: Column(
          children: [
            _StatusChips(
              current: filter,
              onChanged: (s) => setState(() => filter = s),
            ),
            const Divider(height: 0),
            Expanded(
              child: orders.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                itemBuilder: (_, i) => _OrderTile(order: orders[i]),
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemCount: orders.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final OrderStatus current;
  final ValueChanged<OrderStatus> onChanged;
  const _StatusChips({required this.current, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: OrderStatus.values.map((s) {
          final sel = s == current;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(s.label), selected: sel,
              onSelected: (_) => onChanged(s),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    // placeholder
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 56, height: 56, color: Colors.grey.shade200,
          child: const Icon(Icons.image, color: Colors.black26),
        ),
      ),
      title: const Text('طلب #12345'),
      subtitle: const Text('3 عناصر • 1200 ج.س'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {/* TODO: go to details */},
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.black26),
          SizedBox(height: 12),
          Text('لا توجد طلبات بعد', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('عند طلب أي منتج سيظهر هنا تتبع الحالة', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ]),
      ),
    );
  }
}
