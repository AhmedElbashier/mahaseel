// lib/features/menu/data/menu_items.dart
import 'package:flutter/material.dart';
import '../models/menu_item.dart';

List<MenuSection> buildMenuSections({
  required String city,
  required String language,
  required void Function() onCityTap,
  required void Function() onLanguageTap,
}) {
  return [
    // Profile / settings — unchanged
    MenuSection([
      const MenuItemModel(icon: Icons.person_outline, title: 'الملف الشخصي', route: '/profile'),
      const MenuItemModel(icon: Icons.manage_accounts_outlined, title: 'إعدادات الحساب', route: '/account'),
      const MenuItemModel(icon: Icons.notifications_none, title: 'إعدادات الإشعارات', route: '/notifications'),
      const MenuItemModel(icon: Icons.lock_outline, title: 'الأمان', route: '/security'),
    ]),

    // 🔄 Marketplace section — UPDATED for Mahaseel
    MenuSection(const [
      MenuItemModel(
        icon: Icons.receipt_long_outlined,
        title: 'طلباتي',                   // Buyer orders
        route: '/orders',
      ),
      MenuItemModel(
        icon: Icons.storefront_outlined,
        title: 'مبيعاتي',                  // Seller orders / sales
        route: '/sales',
      ),
      MenuItemModel(
        icon: Icons.account_balance_wallet_outlined,
        title: 'المحفظة وطرق الدفع',        // Wallet, payouts, cards
        route: '/wallet',
      ),
    ]),

    // City / Language — unchanged (right values injected by screen)
    MenuSection([
      MenuItemModel(icon: Icons.apartment_outlined, title: 'المدينة', onTap: onCityTap),
      MenuItemModel(icon: Icons.translate_outlined, title: 'اللغة', onTap: onLanguageTap),
    ]),

    // Info & support — unchanged
    MenuSection(const [
      MenuItemModel(icon: Icons.article_outlined, title: 'المدونة', route: '/blogs'),
      MenuItemModel(icon: Icons.support_agent_outlined, title: 'الدعم', route: '/support'),
      MenuItemModel(icon: Icons.call_outlined, title: 'اتصل بنا', route: '/call-us'),
      MenuItemModel(icon: Icons.gavel_outlined, title: 'اللوائح القانونية', route: '/legal'),
      MenuItemModel(icon: Icons.campaign_outlined, title: 'الإعلانات', route: '/advertising'),
    ]),
  ];
}
