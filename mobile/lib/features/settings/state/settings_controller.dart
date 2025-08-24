import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ---------- STATE ----------
class SettingsState {
  // Look & feel
  final bool isDarkMode;           // maps to ThemeMode
  final bool isArabic;             // maps to Locale

  // Data & UX
  final bool isVibrationEnabled;
  final bool isDataSaverEnabled;

  // Simple notifications (used in Settings screen)
  final bool isCropNotificationsEnabled;
  final bool isOrderNotificationsEnabled;
  final bool isMessageNotificationsEnabled;
  final bool isSoundEnabled;

  // Privacy (Settings screen)
  final bool isPhoneVisible;

  // Device features
  final bool isLocationEnabled;

  // ---- Detailed notifications (Notifications screen expects these) ----
  final bool pushNotificationsEnabled;
  final bool newCropsNotifications;
  final bool priceUpdateNotifications;
  final bool newOrdersNotifications;
  final bool orderStatusNotifications;
  final bool chatNotifications;
  final bool whatsappNotifications;
  final String quietHoursStart; // "HH:mm"
  final String quietHoursEnd;   // "HH:mm"
  final bool groupNotifications;

  // ---- Profile screen toggles ----
  final bool publicProfile;
  final bool showPhone;            // NOTE: distinct from isPhoneVisible (legacy naming in ProfileScreen)
  final bool allowDirectContact;

  const SettingsState({
    // look & feel
    this.isDarkMode = false,
    this.isArabic = true,

    // data & ux
    this.isVibrationEnabled = true,
    this.isDataSaverEnabled = false,

    // simple notifications (settings screen)
    this.isCropNotificationsEnabled = true,
    this.isOrderNotificationsEnabled = true,
    this.isMessageNotificationsEnabled = true,
    this.isSoundEnabled = true,

    // privacy
    this.isPhoneVisible = true,

    // device
    this.isLocationEnabled = true,

    // detailed notifications (notifications screen)
    this.pushNotificationsEnabled = true,
    this.newCropsNotifications = true,
    this.priceUpdateNotifications = true,
    this.newOrdersNotifications = true,
    this.orderStatusNotifications = true,
    this.chatNotifications = true,
    this.whatsappNotifications = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.groupNotifications = false,

    // profile screen toggles
    this.publicProfile = true,
    this.showPhone = true,
    this.allowDirectContact = true,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? isArabic,
    bool? isVibrationEnabled,
    bool? isDataSaverEnabled,
    bool? isCropNotificationsEnabled,
    bool? isOrderNotificationsEnabled,
    bool? isMessageNotificationsEnabled,
    bool? isSoundEnabled,
    bool? isPhoneVisible,
    bool? isLocationEnabled,

    bool? pushNotificationsEnabled,
    bool? newCropsNotifications,
    bool? priceUpdateNotifications,
    bool? newOrdersNotifications,
    bool? orderStatusNotifications,
    bool? chatNotifications,
    bool? whatsappNotifications,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? groupNotifications,

    bool? publicProfile,
    bool? showPhone,
    bool? allowDirectContact,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isArabic: isArabic ?? this.isArabic,
      isVibrationEnabled: isVibrationEnabled ?? this.isVibrationEnabled,
      isDataSaverEnabled: isDataSaverEnabled ?? this.isDataSaverEnabled,
      isCropNotificationsEnabled:
      isCropNotificationsEnabled ?? this.isCropNotificationsEnabled,
      isOrderNotificationsEnabled:
      isOrderNotificationsEnabled ?? this.isOrderNotificationsEnabled,
      isMessageNotificationsEnabled:
      isMessageNotificationsEnabled ?? this.isMessageNotificationsEnabled,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isPhoneVisible: isPhoneVisible ?? this.isPhoneVisible,
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,

      pushNotificationsEnabled:
      pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      newCropsNotifications:
      newCropsNotifications ?? this.newCropsNotifications,
      priceUpdateNotifications:
      priceUpdateNotifications ?? this.priceUpdateNotifications,
      newOrdersNotifications:
      newOrdersNotifications ?? this.newOrdersNotifications,
      orderStatusNotifications:
      orderStatusNotifications ?? this.orderStatusNotifications,
      chatNotifications: chatNotifications ?? this.chatNotifications,
      whatsappNotifications:
      whatsappNotifications ?? this.whatsappNotifications,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      groupNotifications: groupNotifications ?? this.groupNotifications,

      publicProfile: publicProfile ?? this.publicProfile,
      showPhone: showPhone ?? this.showPhone,
      allowDirectContact: allowDirectContact ?? this.allowDirectContact,
    );
  }
}

/// ---------- CONTROLLER ----------
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<void> _loadSettings() async {
    final p = await _prefs;
    state = SettingsState(
      // look & feel
      isDarkMode: p.getBool('isDarkMode') ?? false,
      isArabic: p.getBool('isArabic') ?? true,

      // data & ux
      isVibrationEnabled: p.getBool('isVibrationEnabled') ?? true,
      isDataSaverEnabled: p.getBool('isDataSaverEnabled') ?? false,

      // simple notifications
      isCropNotificationsEnabled:
      p.getBool('isCropNotificationsEnabled') ?? true,
      isOrderNotificationsEnabled:
      p.getBool('isOrderNotificationsEnabled') ?? true,
      isMessageNotificationsEnabled:
      p.getBool('isMessageNotificationsEnabled') ?? true,
      isSoundEnabled: p.getBool('isSoundEnabled') ?? true,

      // privacy
      isPhoneVisible: p.getBool('isPhoneVisible') ?? true,

      // device
      isLocationEnabled: p.getBool('isLocationEnabled') ?? true,

      // detailed notifications
      pushNotificationsEnabled:
      p.getBool('pushNotificationsEnabled') ?? true,
      newCropsNotifications:
      p.getBool('newCropsNotifications') ?? true,
      priceUpdateNotifications:
      p.getBool('priceUpdateNotifications') ?? true,
      newOrdersNotifications:
      p.getBool('newOrdersNotifications') ?? true,
      orderStatusNotifications:
      p.getBool('orderStatusNotifications') ?? true,
      chatNotifications: p.getBool('chatNotifications') ?? true,
      whatsappNotifications: p.getBool('whatsappNotifications') ?? true,
      quietHoursStart: p.getString('quietHoursStart') ?? '22:00',
      quietHoursEnd: p.getString('quietHoursEnd') ?? '07:00',
      groupNotifications: p.getBool('groupNotifications') ?? false,

      // profile
      publicProfile: p.getBool('publicProfile') ?? true,
      showPhone: p.getBool('showPhone') ?? true,
      allowDirectContact: p.getBool('allowDirectContact') ?? true,
    );
  }

  Future<void> _saveBool(String key, bool value) async {
    final p = await _prefs;
    await p.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final p = await _prefs;
    await p.setString(key, value);
  }

  // ----- Look & feel -----
  Future<void> toggleDarkMode() async {
    final v = !state.isDarkMode;
    state = state.copyWith(isDarkMode: v);
    await _saveBool('isDarkMode', v);
  }

  Future<void> toggleLanguage() async {
    final v = !state.isArabic;
    state = state.copyWith(isArabic: v);
    await _saveBool('isArabic', v);
  }

  // ----- Data & UX -----
  Future<void> toggleVibration() async {
    final v = !state.isVibrationEnabled;
    state = state.copyWith(isVibrationEnabled: v);
    await _saveBool('isVibrationEnabled', v);
  }

  Future<void> toggleDataSaver() async {
    final v = !state.isDataSaverEnabled;
    state = state.copyWith(isDataSaverEnabled: v);
    await _saveBool('isDataSaverEnabled', v);
  }

  // ----- Simple notifications (Settings screen) -----
  Future<void> toggleCropNotifications() async {
    final v = !state.isCropNotificationsEnabled;
    state = state.copyWith(isCropNotificationsEnabled: v);
    await _saveBool('isCropNotificationsEnabled', v);
  }

  Future<void> toggleOrderNotifications() async {
    final v = !state.isOrderNotificationsEnabled;
    state = state.copyWith(isOrderNotificationsEnabled: v);
    await _saveBool('isOrderNotificationsEnabled', v);
  }

  Future<void> toggleMessageNotifications() async {
    final v = !state.isMessageNotificationsEnabled;
    state = state.copyWith(isMessageNotificationsEnabled: v);
    await _saveBool('isMessageNotificationsEnabled', v);
  }

  Future<void> toggleSound() async {
    final v = !state.isSoundEnabled;
    state = state.copyWith(isSoundEnabled: v);
    await _saveBool('isSoundEnabled', v);
  }

  // ----- Privacy & device -----
  Future<void> togglePhoneVisibility() async {
    final v = !state.isPhoneVisible;
    state = state.copyWith(isPhoneVisible: v);
    await _saveBool('isPhoneVisible', v);
  }

  Future<void> toggleLocation() async {
    final v = !state.isLocationEnabled;
    state = state.copyWith(isLocationEnabled: v);
    await _saveBool('isLocationEnabled', v);
  }

  // ----- Detailed notifications (Notifications screen) -----
  Future<void> updatePushNotifications(bool enabled) async {
    state = state.copyWith(pushNotificationsEnabled: enabled);
    await _saveBool('pushNotificationsEnabled', enabled);
  }

  Future<void> updateNewCropsNotifications(bool enabled) async {
    state = state.copyWith(newCropsNotifications: enabled);
    await _saveBool('newCropsNotifications', enabled);
  }

  Future<void> updatePriceUpdateNotifications(bool enabled) async {
    state = state.copyWith(priceUpdateNotifications: enabled);
    await _saveBool('priceUpdateNotifications', enabled);
  }

  Future<void> updateNewOrdersNotifications(bool enabled) async {
    state = state.copyWith(newOrdersNotifications: enabled);
    await _saveBool('newOrdersNotifications', enabled);
  }

  Future<void> updateOrderStatusNotifications(bool enabled) async {
    state = state.copyWith(orderStatusNotifications: enabled);
    await _saveBool('orderStatusNotifications', enabled);
  }

  Future<void> updateChatNotifications(bool enabled) async {
    state = state.copyWith(chatNotifications: enabled);
    await _saveBool('chatNotifications', enabled);
  }

  Future<void> updateWhatsappNotifications(bool enabled) async {
    state = state.copyWith(whatsappNotifications: enabled);
    await _saveBool('whatsappNotifications', enabled);
  }

  Future<void> updateQuietHours(String start, String end) async {
    state = state.copyWith(quietHoursStart: start, quietHoursEnd: end);
    await _saveString('quietHoursStart', start);
    await _saveString('quietHoursEnd', end);
  }

  Future<void> updateGroupNotifications(bool enabled) async {
    state = state.copyWith(groupNotifications: enabled);
    await _saveBool('groupNotifications', enabled);
  }

  // ----- Profile screen toggles -----
  Future<void> updatePublicProfile(bool enabled) async {
    state = state.copyWith(publicProfile: enabled);
    await _saveBool('publicProfile', enabled);
  }

  Future<void> updateShowPhone(bool enabled) async {
    state = state.copyWith(showPhone: enabled);
    await _saveBool('showPhone', enabled);
  }

  Future<void> updateAllowDirectContact(bool enabled) async {
    state = state.copyWith(allowDirectContact: enabled);
    await _saveBool('allowDirectContact', enabled);
  }

  // ----- Additional (used by NotificationsScreen buttons) -----
  void testNotification() {
    // TODO: Hook your local notification service here
    // For now, no-op to satisfy calls from UI.
  }

  void clearAllNotifications() {
    // TODO: Hook your clear-all logic here
    // For now, no-op to satisfy calls from UI.
  }
}

/// ---------- PROVIDERS ----------
final settingsControllerProvider =
StateNotifierProvider<SettingsController, SettingsState>(
      (ref) => SettingsController(),
);

/// ThemeMode for MaterialApp.themeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final isDark = ref.watch(
    settingsControllerProvider.select((s) => s.isDarkMode),
  );
  return isDark ? ThemeMode.dark : ThemeMode.light;
});

/// Locale for MaterialApp.locale
final localeProvider = Provider<Locale>((ref) {
  final isArabic = ref.watch(
    settingsControllerProvider.select((s) => s.isArabic),
  );
  return isArabic ? const Locale('ar') : const Locale('en');
});
