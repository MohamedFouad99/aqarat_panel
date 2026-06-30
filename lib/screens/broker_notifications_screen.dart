import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/auth_service.dart';

/// شاشة إشعارات الوسيط داخل التطبيق.
class BrokerNotificationsScreen extends StatelessWidget {
  BrokerNotificationsScreen({super.key});

  final _service = NotificationService();
  final _auth = AuthService();

  IconData _icon(String type) {
    switch (type) {
      case 'borrow_request':
        return Icons.swap_horiz;
      case 'borrow_accepted':
        return Icons.check_circle;
      case 'borrow_rejected':
        return Icons.cancel;
      case 'deal':
        return Icons.verified;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإشعارات')),
        body: StreamBuilder<List<AppNotification>>(
          stream: _service.watchFor(uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data!;
            if (items.isEmpty) {
              return const Center(child: Text('لا توجد إشعارات'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = items[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: n.read
                        ? const Color(0xFFE3E8EF)
                        : const Color(0xFF0A2540),
                    child: Icon(_icon(n.type),
                        color: n.read ? const Color(0xFF6B7785) : Colors.white,
                        size: 20),
                  ),
                  title: Text(n.title,
                      style: TextStyle(
                          fontWeight:
                              n.read ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text(n.body),
                  trailing: n.read
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: Color(0xFFC9A227),
                              shape: BoxShape.circle)),
                  onTap: () => _service.markRead(n.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
