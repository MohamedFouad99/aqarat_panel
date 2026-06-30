import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../models/borrow_request.dart';
import '../services/auth_service.dart';
import '../services/borrow_service.dart';
import '../services/user_service.dart';

/// تبويب الاستعارات: الطلبات الواردة لصاحب العرض + الصادرة من الوسيط الطالب.
class BorrowView extends StatelessWidget {
  BorrowView({super.key});

  final _borrow = BorrowService();
  final _auth = AuthService();
  final _users = UserService();
  final _fmt = NumberFormat.decimalPattern('en');

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header('طلبات واردة على عروضك', Icons.call_received),
          StreamBuilder<List<BorrowRequest>>(
            stream: _borrow.watchIncoming(uid),
            builder: (_, snap) => _list(
                context, snap.data ?? [], incoming: true),
          ),
          const SizedBox(height: 20),
          _header('طلباتك للاستعارة', Icons.call_made),
          StreamBuilder<List<BorrowRequest>>(
            stream: _borrow.watchOutgoing(uid),
            builder: (_, snap) =>
                _list(context, snap.data ?? [], incoming: false),
          ),
        ],
      ),
    );
  }

  Widget _header(String t, IconData i) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(children: [
          Icon(i, size: 18, color: const Color(0xFF0A2540)),
          const SizedBox(width: 6),
          Text(t,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF0A2540))),
        ]),
      );

  Widget _list(BuildContext context, List<BorrowRequest> items,
      {required bool incoming}) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('لا يوجد', style: TextStyle(color: Color(0xFF6B7785))),
      );
    }
    return Column(
      children: items.map((b) => _card(context, b, incoming)).toList(),
    );
  }

  Widget _card(BuildContext context, BorrowRequest b, bool incoming) {
    final statusLabel = {
      'pending': '⏳ بانتظار الرد',
      'accepted': '✅ مقبول',
      'rejected': '❌ مرفوض',
    }[b.status]!;
    // عند القبول نكشف بيانات الطرف الآخر
    final otherUid = incoming ? b.fromBrokerId : b.toBrokerId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${b.offerTitle} · ${_fmt.format(b.offerPrice)} ريال',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFF0A2540),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('${b.score.round()}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('لعميل: ${b.requestName.isEmpty ? "—" : b.requestName}',
                style: const TextStyle(color: Color(0xFF6B7785))),
            const SizedBox(height: 6),
            Text(statusLabel),
            // أزرار القبول/الرفض للوارد المعلّق
            if (incoming && b.status == 'pending') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _borrow.accept(b.id),
                      child: const Text('قبول'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _borrow.reject(b.id),
                      child: const Text('رفض'),
                    ),
                  ),
                ],
              ),
            ],
            // عند القبول: كشف تواصل الطرف الآخر
            if (b.status == 'accepted') ...[
              const SizedBox(height: 8),
              FutureBuilder<UserProfile?>(
                future: _users.get(otherUid),
                builder: (_, us) {
                  final p = us.data;
                  if (p == null) return const SizedBox.shrink();
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                            '${incoming ? "الطالب" : "صاحب العرض"}: ${p.name}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, color: Color(0xFF1E8E4E)),
                        onPressed: () => _open('tel:${p.phone}'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                        onPressed: () => _open(
                            'https://wa.me/${p.phone.replaceAll(RegExp(r"[^0-9]"), "")}'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
