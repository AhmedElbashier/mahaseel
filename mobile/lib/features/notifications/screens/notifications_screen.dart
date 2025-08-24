
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/state/settings_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Push Notifications Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'الإشعارات الفورية',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('تفعيل الإشعارات الفورية'),
                    subtitle: const Text('تلقي إشعارات فورية عند وصول طلبات جديدة'),
                    value: settingsState.pushNotificationsEnabled,
                    onChanged: (value) {
                      settingsController.updatePushNotifications(value);
                    },
                    secondary: const Icon(Icons.push_pin),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Crop Notifications Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.agriculture,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إشعارات المحاصيل',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('محاصيل جديدة'),
                    subtitle: const Text('إشعار عند إضافة محاصيل جديدة في منطقتك'),
                    value: settingsState.newCropsNotifications,
                    onChanged: (value) {
                      settingsController.updateNewCropsNotifications(value);
                    },
                    secondary: const Icon(Icons.new_releases),
                  ),
                  SwitchListTile(
                    title: const Text('تحديث الأسعار'),
                    subtitle: const Text('إشعار عند تغيير أسعار المحاصيل المتابعة'),
                    value: settingsState.priceUpdateNotifications,
                    onChanged: (value) {
                      settingsController.updatePriceUpdateNotifications(value);
                    },
                    secondary: const Icon(Icons.trending_up),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Order Notifications Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إشعارات الطلبات',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('طلبات جديدة'),
                    subtitle: const Text('إشعار عند وصول طلبات شراء جديدة'),
                    value: settingsState.newOrdersNotifications,
                    onChanged: (value) {
                      settingsController.updateNewOrdersNotifications(value);
                    },
                    secondary: const Icon(Icons.add_shopping_cart),
                  ),
                  SwitchListTile(
                    title: const Text('تأكيد الطلبات'),
                    subtitle: const Text('إشعار عند تأكيد أو إلغاء الطلبات'),
                    value: settingsState.orderStatusNotifications,
                    onChanged: (value) {
                      settingsController.updateOrderStatusNotifications(value);
                    },
                    secondary: const Icon(Icons.check_circle),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Chat & Messages Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'الرسائل والمحادثات',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('رسائل جديدة'),
                    subtitle: const Text('إشعار عند وصول رسائل جديدة'),
                    value: settingsState.chatNotifications,
                    onChanged: (value) {
                      settingsController.updateChatNotifications(value);
                    },
                    secondary: const Icon(Icons.message),
                  ),
                  SwitchListTile(
                    title: const Text('إشعارات واتساب'),
                    subtitle: const Text('فتح الرسائل في واتساب مباشرة'),
                    value: settingsState.whatsappNotifications,
                    onChanged: (value) {
                      settingsController.updateWhatsappNotifications(value);
                    },
                    secondary: const Icon(Icons.phone),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notification Schedule Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'جدولة الإشعارات',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('أوقات عدم الإزعاج'),
                    subtitle: Text('${settingsState.quietHoursStart} - ${settingsState.quietHoursEnd}'),
                    leading: const Icon(Icons.do_not_disturb),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showQuietHoursDialog(context, settingsController, settingsState);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('تجميع الإشعارات'),
                    subtitle: const Text('تجميع الإشعارات المتشابهة في إشعار واحد'),
                    value: settingsState.groupNotifications,
                    onChanged: (value) {
                      settingsController.updateGroupNotifications(value);
                    },
                    secondary: const Icon(Icons.group_work),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    settingsController.testNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال إشعار تجريبي')),
                    );
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('اختبار الإشعار'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showClearNotificationsDialog(context, settingsController);
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('مسح الإشعارات'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuietHoursDialog(BuildContext context, SettingsController controller, SettingsState state) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TimeOfDay startTime = TimeOfDay(
          hour: int.parse(state.quietHoursStart.split(':')[0]),
          minute: int.parse(state.quietHoursStart.split(':')[1]),
        );
        TimeOfDay endTime = TimeOfDay(
          hour: int.parse(state.quietHoursEnd.split(':')[0]),
          minute: int.parse(state.quietHoursEnd.split(':')[1]),
        );

        return AlertDialog(
          title: const Text('أوقات عدم الإزعاج'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('بداية فترة السكون'),
                subtitle: Text(state.quietHoursStart),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: startTime,
                  );
                  if (time != null) {
                    controller.updateQuietHours(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      state.quietHoursEnd,
                    );
                    Navigator.of(context).pop();
                  }
                },
              ),
              ListTile(
                title: const Text('نهاية فترة السكون'),
                subtitle: Text(state.quietHoursEnd),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: endTime,
                  );
                  if (time != null) {
                    controller.updateQuietHours(
                      state.quietHoursStart,
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    );
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  void _showClearNotificationsDialog(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('مسح الإشعارات'),
          content: const Text('هل أنت متأكد من مسح جميع الإشعارات؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                controller.clearAllNotifications();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم مسح جميع الإشعارات')),
                );
              },
              child: const Text('مسح'),
            ),
          ],
        );
      },
    );
  }
}
