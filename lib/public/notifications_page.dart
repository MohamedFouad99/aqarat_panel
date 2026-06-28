import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'widgets/public_page.dart';

/// صفحة الإشعارات — أحدث العقارات المضافة كإشعارات.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PropertyService();
    return PublicPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.notifications, color: AppColors.gold),
                    SizedBox(width: 8),
                    Text(
                      'الإشعارات',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Property>>(
                  stream: service.watchProperties(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final latest = snapshot.data!
                        .where((p) => p.status == PropertyStatus.available)
                        .take(15)
                        .toList();
                    if (latest.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('لا توجد إشعارات')),
                      );
                    }
                    return Column(
                      children: latest.map((p) => _tile(context, p)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, Property p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.bg,
          child: Icon(Icons.home_work_outlined, color: AppColors.navy),
        ),
        title: Text(
          '${p.type.arabicLabel} جديدة في ${p.city}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${p.title} · ${formatPrice(p.price)}'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.navy),
        onTap: () => context.go('/property/${p.id}'),
      ),
    );
  }
}
