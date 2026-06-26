import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/compare_service.dart';
import '../../theme/app_theme.dart';

/// هيدر الموقع العام (شعار + قائمة + زر دخول).
class SiteHeader extends StatelessWidget implements PreferredSizeWidget {
  const SiteHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 820;
    final location = GoRouterState.of(context).uri.path;

    return Material(
      color: AppColors.navy,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // الشعار
                InkWell(
                  onTap: () => context.go('/'),
                  child: Row(
                    children: [
                      const Icon(Icons.apartment, color: AppColors.gold, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'عقاراتي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: const [],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (wide) ...[
                  _navItem(context, 'الرئيسية', '/', location),
                  _navItem(context, 'العقارات', '/properties', location),
                  _navItem(context, 'الخريطة', '/map', location),
                  _navItem(context, 'اطلب عقارك', '/request', location),
                  _navItem(context, 'الوسطاء', '/agents', location),
                  _navItem(context, 'الباقات', '/packages', location),
                ],
                ValueListenableBuilder<List<String>>(
                  valueListenable: CompareService.instance.ids,
                  builder: (context, ids, _) => IconButton(
                    tooltip: 'المقارنة',
                    onPressed: () => context.go('/compare'),
                    icon: Badge(
                      isLabelVisible: ids.isNotEmpty,
                      label: Text('${ids.length}'),
                      child: const Icon(Icons.compare_arrows,
                          color: Colors.white),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'المفضلة',
                  onPressed: () => context.go('/favorites'),
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                ),
                IconButton(
                  tooltip: 'الإشعارات',
                  onPressed: () => context.go('/notifications'),
                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => context.go('/admin'),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('دخول المعلنين'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      BuildContext context, String label, String path, String current) {
    final active = current == path;
    return TextButton(
      onPressed: () => context.go(path),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.gold : Colors.white,
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }
}
