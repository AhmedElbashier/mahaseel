import 'package:flutter/material.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المحفظة وطرق الدفع'),
          bottom: TabBar(controller: _tabs, tabs: const [
            Tab(text: 'المعاملات'),
            Tab(text: 'طرق السحب'),
            Tab(text: 'البطاقات'),
          ]),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: const [
                _StatCard(title: 'الرصيد', value: '0.00'),
                SizedBox(width: 8),
                _StatCard(title: 'قيد التحويل', value: '0.00'),
                SizedBox(width: 8),
                _StatCard(title: 'إجمالي الأرباح', value: '0.00'),
              ]),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _TransactionsTab(),
                  _PayoutMethodsTab(),
                  _CardsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  const _StatCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(blurRadius: 8, spreadRadius: -8, offset: Offset(0, 6))],
        ),
        child: Column(children: [
          Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        ]),
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();
  @override
  Widget build(BuildContext context) {
    final txns = <Map<String, dynamic>>[]; // TODO: bind
    if (txns.isEmpty) {
      return const Center(child: Text('لا توجد معاملات بعد'));
    }
    return ListView.separated(
      itemCount: txns.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (_, i) {
        final t = txns[i];
        return ListTile(
          leading: CircleAvatar(backgroundColor: Colors.grey.shade100, child: const Icon(Icons.swap_vert)),
          title: Text(t['title']),
          subtitle: Text(t['date']),
          trailing: Text('${t['amount']} ج.س', style: const TextStyle(fontWeight: FontWeight.w700)),
        );
      },
    );
  }
}

class _PayoutMethodsTab extends StatelessWidget {
  const _PayoutMethodsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.account_balance_outlined),
          title: const Text('إضافة حساب بنكي/IBAN'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAddPayout(context),
        ),
      ],
    );
  }

  void _showAddPayout(BuildContext context) {
    final bank = TextEditingController();
    final name = TextEditingController();
    final iban = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('إضافة طريقة سحب', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(controller: bank, decoration: const InputDecoration(labelText: 'اسم البنك')),
            const SizedBox(height: 8),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم صاحب الحساب')),
            const SizedBox(height: 8),
            TextField(controller: iban, decoration: const InputDecoration(labelText: 'IBAN')),
            const SizedBox(height: 16),
            FilledButton(onPressed: () { Navigator.pop(context); /* TODO: call /wallet/payout-methods */ }, child: const Text('حفظ')),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

class _CardsTab extends StatelessWidget {
  const _CardsTab();
  @override
  Widget build(BuildContext context) {
    return ListView(children: const [
      ListTile(
        leading: Icon(Icons.credit_card),
        title: Text('إضافة بطاقة جديدة'),
        trailing: Icon(Icons.chevron_right),
      ),
    ]);
  }
}
