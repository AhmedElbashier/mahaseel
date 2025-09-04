import 'package:flutter/material.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool twoFactor = false;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(height: 1, color: Colors.grey.shade200);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الأمان')),
        body: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text('تغيير كلمة المرور'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showChangePasswordSheet(context);
              },
            ),
            divider,
            SwitchListTile(
              value: twoFactor,
              onChanged: (v) => setState(() => twoFactor = v),
              secondary: const Icon(Icons.verified_user_outlined),
              title: const Text('تفعيل التحقق بخطوتين'),
              subtitle: const Text('حماية إضافية لحسابك'),
            ),
            divider,
            ListTile(
              leading: const Icon(Icons.devices_other_outlined),
              title: const Text('الأجهزة النشطة'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: show active sessions */},
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final old = TextEditingController();
    final n1 = TextEditingController();
    final n2 = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('تغيير كلمة المرور', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(controller: old, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الحالية')),
            const SizedBox(height: 8),
            TextField(controller: n1, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة')),
            const SizedBox(height: 8),
            TextField(controller: n2, obscureText: true, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                // TODO: call /auth/change-password
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
