import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'widgets/public_page.dart';

/// صفحة "اشتراكي" — الباقة الحالية + رابط لباقي الباقات.
class MySubscriptionPage extends StatelessWidget {
  const MySubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اشتراكي',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, AppColors.navyLight]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الباقة الحالية',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('الباقة المجانية',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(20)),
                            child: const Text('نشطة',
                                style: TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _usageRow('الإعلانات المستخدمة', '0 من 3'),
                      const SizedBox(height: 6),
                      _usageRow('تاريخ التجديد', 'غير محدود'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.upgrade, color: AppColors.gold),
                    title: const Text('عايز إمكانيات أكتر؟'),
                    subtitle: const Text(
                        'رقّي باقتك لإعلانات أكتر وظهور أعلى وفيديو وخرائط'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.go('/packages'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _usageRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      );
}
