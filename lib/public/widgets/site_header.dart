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
                  _navItem(context, 'الخريطة', '/map', location),
                  _navItem(context, 'اطلب عقارك', '/request', location),
                  _navItem(context, 'حسابي', '/account', location),
                ] else
                  PopupMenuButton<String>(
                    tooltip: 'القائمة',
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onSelected: (path) => context.go(path),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: '/', child: Text('الرئيسية')),
                      PopupMenuItem(value: '/map', child: Text('الخريطة')),
                      PopupMenuItem(
                          value: '/request', child: Text('اطلب عقارك')),
                      PopupMenuItem(value: '/account', child: Text('حسابي')),
                    ],
                  ),
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
                if (wide)
                  IconButton(
                    tooltip: 'الإشعارات',
                    onPressed: () => context.go('/notifications'),
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white),
                  ),
                SizedBox(width: wide ? 8 : 2),
                if (wide)
                  FilledButton.icon(
                    onPressed: () => context.go('/admin'),
                    icon: const Icon(Icons.dashboard_outlined, size: 18),
                    label: const Text('لوحة الوسيط'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'لوحة الوسيط',
                    onPressed: () => context.go('/admin'),
                    icon: const Icon(Icons.dashboard_outlined,
                        color: AppColors.gold),
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
