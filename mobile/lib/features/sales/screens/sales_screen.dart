import 'package:flutter/material.dart';

enum SalesStatus { all, neww, confirmed, shipped, delivered, canceled }
extension SalesStatusX on SalesStatus {
  String get label => switch (this) {
        SalesStatus.all => 'All',
        SalesStatus.neww => 'New',
        SalesStatus.confirmed => 'Confirmed',
        SalesStatus.shipped => 'Shipped',
        SalesStatus.delivered => 'Delivered',
        SalesStatus.canceled => 'Canceled',
      };
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  SalesStatus filter = SalesStatus.all;

  @override
  Widget build(BuildContext context) {
    final sales = <Map<String, dynamic>>[]; // TODO: repo
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('Sales')),
        body: Column(
          children: [
            _StatusChips(current: filter, onChanged: (s) => setState(() => filter = s)),
            const Divider(height: 0),
            Expanded(
              child: sales.isEmpty
                  ? const _Empty()
                  : ListView.separated(
                      itemBuilder: (_, i) => _SaleRow(order: sales[i]),
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemCount: sales.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final SalesStatus current;
  final ValueChanged<SalesStatus> onChanged;
  const _StatusChips({required this.current, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SalesStatus.values
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(label: Text(s.label), selected: s == current, onSelected: (_) => onChanged(s)),
                ))
            .toList(),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final Map<String, dynamic> order;
  const _SaleRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.shade50,
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.green),
      ),
      title: const Text('Sale to John Doe'),
      subtitle: const Text('3 items • 800 SDG'),
      trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: const [
        _Badge(text: 'New', color: Colors.orange),
        Icon(Icons.chevron_right),
      ]),
      onTap: () {/* TODO: details + status actions */},
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
          Icon(Icons.storefront_outlined, size: 64, color: Colors.black26),
          SizedBox(height: 12),
          Text('No sales yet', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Your sales will show up here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ]),
      ),
    );
  }
}

