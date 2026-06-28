import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/compare_service.dart';
import '../services/favorites_service.dart';
import '../services/recently_viewed_service.dart';
import '../theme/app_theme.dart';
import 'widgets/public_page.dart';

/// صفحة "حسابي" — مركز سريع للزائر (مفضلة/مقارنة/إشعارات + الدخول كوسيط).
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بطاقة ترحيب
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, AppColors.navyLight]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: const [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.gold,
                        child: Icon(Icons.person, color: AppColors.navy, size: 32),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مرحبًا بك 👋',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('إدارة مفضلتك ومقارناتك ومتابعة عقاراتك',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _tile(context, Icons.favorite, 'المفضلة', '/favorites',
                    listenable: FavoritesService.instance.ids),
                _tile(context, Icons.compare_arrows, 'المقارنة', '/compare',
                    listenable: CompareService.instance.ids),
                _tile(context, Icons.history, 'شاهدت مؤخرًا', '/',
                    listenable: RecentlyViewedService.instance.ids),
                _tile(context, Icons.notifications_none, 'الإشعارات',
                    '/notifications'),
                _tile(context, Icons.add_home_work, 'اطلب عقارك', '/request'),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                // الدخول كوسيط
                Card(
                  color: AppColors.bg,
                  child: ListTile(
                    leading: const Icon(Icons.store, color: AppColors.navy),
                    title: const Text('وسيط عقاري؟'),
                    subtitle: const Text('ادخل لوحة الوسيط لإدارة إعلاناتك'),
                    trailing: FilledButton(
                      onPressed: () => context.go('/admin'),
                      child: const Text('لوحة الوسيط'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, String path,
      {ValueListenable<Iterable<String>>? listenable}) {
    Widget trailing = const Icon(Icons.chevron_left);
    if (listenable != null) {
      trailing = ValueListenableBuilder<Iterable<String>>(
        valueListenable: listenable,
        builder: (_, ids, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ids.isNotEmpty)
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.gold,
                child: Text('${ids.length}',
                    style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            const Icon(Icons.chevron_left),
          ],
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.navy),
        title: Text(label),
        trailing: trailing,
        onTap: () => context.go(path),
      ),
    );
  }
}
