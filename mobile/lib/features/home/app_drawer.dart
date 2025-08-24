import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // Optional header
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.agriculture)),
                title: const Text('تطبيق محاصيل'),
                subtitle: const Text('سوق المزارعين'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('الملف الشخصي'),
                onTap: () {
                  Navigator.of(context).pop();
                  // TODO: navigate to profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الملف الشخصي غير متوفر بعد')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('تسجيل الخروج'),
                onTap: () {
                  // TODO: implement logout (clear secure storage, etc.)
                  Navigator.of(context).pop();
                  // Show a simple snackbar for now
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل الخروج (تجريبي)')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
