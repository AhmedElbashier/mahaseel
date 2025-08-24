
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/settings_controller.dart';
import '../../auth/state/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final authController = ref.read(authControllerProvider.notifier);
    final authState = ref.watch(authControllerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'الإعدادات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.green[700],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              _buildProfileCardFromState(authState),
              const SizedBox(height: 20),

              // App Settings
              _buildSettingsSection(
                'إعدادات التطبيق',
                Icons.settings,
                [
                  _buildSwitchTile(
                    'الوضع الليلي',
                    'تفعيل المظهر المظلم',
                    Icons.dark_mode,
                    settings.isDarkMode,
                        (value) => settingsController.toggleDarkMode(),
                  ),
                  _buildSwitchTile(
                    'اللغة العربية',
                    'استخدام اللغة العربية كافتراضية',
                    Icons.language,
                    settings.isArabic,
                        (value) => settingsController.toggleLanguage(),
                  ),
                  _buildSwitchTile(
                    'الاهتزاز',
                    'اهتزاز الجهاز عند التنبيهات',
                    Icons.vibration,
                    settings.isVibrationEnabled,
                        (value) => settingsController.toggleVibration(),
                  ),
                  _buildSwitchTile(
                    'حفظ البيانات',
                    'تقليل استهلاك البيانات',
                    Icons.data_saver_on,
                    settings.isDataSaverEnabled,
                        (value) => settingsController.toggleDataSaver(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notifications
              _buildSettingsSection(
                'الإشعارات',
                Icons.notifications,
                [
                  _buildSwitchTile(
                    'إشعارات المحاصيل',
                    'تنبيهات عند إضافة محاصيل جديدة',
                    Icons.agriculture,
                    settings.isCropNotificationsEnabled,
                        (value) => settingsController.toggleCropNotifications(),
                  ),
                  _buildSwitchTile(
                    'إشعارات الطلبات',
                    'تنبيهات عند وصول طلبات جديدة',
                    Icons.shopping_cart,
                    settings.isOrderNotificationsEnabled,
                        (value) => settingsController.toggleOrderNotifications(),
                  ),
                  _buildSwitchTile(
                    'إشعارات الرسائل',
                    'تنبيهات عند وصول رسائل جديدة',
                    Icons.message,
                    settings.isMessageNotificationsEnabled,
                        (value) => settingsController.toggleMessageNotifications(),
                  ),
                  _buildSwitchTile(
                    'الإشعارات الصوتية',
                    'تشغيل الأصوات مع الإشعارات',
                    Icons.volume_up,
                    settings.isSoundEnabled,
                        (value) => settingsController.toggleSound(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Privacy & Security
              _buildSettingsSection(
                'الخصوصية والأمان',
                Icons.security,
                [
                  _buildNavigationTile(
                    'كلمة المرور',
                    'تغيير كلمة المرور الخاصة بك',
                    Icons.lock,
                        () => _showChangePasswordDialog(),
                  ),
                  _buildSwitchTile(
                    'إظهار الهاتف',
                    'إظهار رقم الهاتف في الملف الشخصي',
                    Icons.phone,
                    settings.isPhoneVisible,
                        (value) => settingsController.togglePhoneVisibility(),
                  ),
                  _buildSwitchTile(
                    'الموقع الجغرافي',
                    'مشاركة الموقع في المحاصيل',
                    Icons.location_on,
                    settings.isLocationEnabled,
                        (value) => settingsController.toggleLocation(),
                  ),
                  _buildNavigationTile(
                    'بيانات الحساب',
                    'إدارة وتنزيل بياناتك',
                    Icons.download,
                        () => _showDataManagementDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Account Management
              _buildSettingsSection(
                'إدارة الحساب',
                Icons.account_circle,
                [
                  _buildNavigationTile(
                    'تحديث الملف الشخصي',
                    'تعديل اسمك ومعلوماتك',
                    Icons.edit,
                        () => _showEditProfileDialog(),
                  ),
                  _buildNavigationTile(
                    'التقييمات',
                    'عرض وإدارة تقييماتك',
                    Icons.star,
                        () => context.push('/ratings'),
                  ),
                  _buildNavigationTile(
                    'حذف الحساب',
                    'حذف حسابك نهائياً',
                    Icons.delete_forever,
                        () => _showDeleteAccountDialog(),
                    isDestructive: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // App Info
              _buildSettingsSection(
                'حول التطبيق',
                Icons.info,
                [
                  _buildNavigationTile(
                    'الدعم',
                    'تواصل مع فريق الدعم',
                    Icons.help,
                        () => context.push('/support'),
                  ),
                  _buildNavigationTile(
                    'شروط الخدمة',
                    'قراءة شروط استخدام التطبيق',
                    Icons.description,
                        () => _showTermsDialog(),
                  ),
                  _buildNavigationTile(
                    'سياسة الخصوصية',
                    'كيف نحمي بياناتك',
                    Icons.privacy_tip,
                        () => _showPrivacyDialog(),
                  ),
                  _buildInfoTile(
                    'إصدار التطبيق',
                    'v1.0.0',
                    Icons.info_outline,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Logout Button
              _buildLogoutButton(authController),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildProfileCard(Map user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.green[100],
            child: Icon(Icons.person, size: 30, color: Colors.green[700]),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  user['phone'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user['role'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCardFromState(dynamic state) {
    // Try to read fields safely
    final name = state?.user?.name ?? state?.name ?? 'المستخدم';
    final phone = state?.user?.phone ?? state?.phone ?? '';
    final role = state?.user?.role ?? state?.role ?? 'مستخدم';

    return _buildProfileCard({
      'name': name,
      'phone': phone,
      'role': role,
    });
  }


  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          ...children.map((child) => child).toList(),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[600]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green[700],
      ),
    );
  }

  Widget _buildNavigationTile(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red[600] : Colors.green[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red[600] : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[600]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildLogoutButton(dynamic authController) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(authController),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout),
            SizedBox(width: 8),
            Text(
              'تسجيل الخروج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(dynamic authController) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                authController.logout();
                context.go('/welcome');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تحديث الملف الشخصي'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إدارة البيانات'),
          content: const Text('يمكنك تنزيل نسخة من بياناتك أو طلب حذفها'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تنزيل البيانات'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الحساب'),
          content: const Text(
            'تحذير: هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع بياناتك ومحاصيلك نهائياً.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف الحساب'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('شروط الخدمة'),
          content: const SingleChildScrollView(
            child: Text(
              'هنا نص شروط الخدمة...\n\nيرجى قراءة الشروط بعناية قبل استخدام التطبيق.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('سياسة الخصوصية'),
          content: const SingleChildScrollView(
            child: Text(
              'نحن نحترم خصوصيتك ونحمي بياناتك...\n\nلا نشارك معلوماتك مع أطراف ثالثة.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }
}
