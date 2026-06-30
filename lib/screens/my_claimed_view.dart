import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../matching/matching_service.dart';
import '../models/app_notification.dart';
import '../models/borrow_request.dart';
import '../models/deal.dart';
import '../models/property.dart';
import '../models/property_request.dart';
import '../services/auth_service.dart';
import '../services/borrow_service.dart';
import '../services/deal_service.dart';
import '../services/property_service.dart';
import '../services/request_service.dart';

/// "طلباتي" — الطلبات اللي استلمها الوسيط + التوصيات (عروض مطابقة من الكل).
class MyClaimedView extends StatelessWidget {
  MyClaimedView({super.key});

  final _requestService = RequestService();
  final _propertyService = PropertyService();
  final _borrowService = BorrowService();
  final _dealService = DealService();
  final _notifications = NotificationService();
  final _auth = AuthService();
  final _fmt = NumberFormat.decimalPattern('en');

  Future<void> _logDeal(
      BuildContext context, PropertyRequest r, String uid) async {
    final valueCtrl = TextEditingController();
    final commCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('توثيق صفقة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valueCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'قيمة الصفقة (ريال)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: commCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'العمولة (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('توثيق')),
        ],
      ),
    );
    if (ok == true) {
      // لو الصفقة تمت عبر عرض مُستعار، تروح "بانتظار تأكيد" صاحب العرض
      final borrows = await _borrowService.acceptedForRequest(r.id);
      final lender = borrows.isNotEmpty ? borrows.first : null;
      await _dealService.create(Deal(
        id: '',
        brokerId: uid,
        clientName: r.name,
        offerTitle: lender != null
            ? lender.offerTitle
            : '${r.type?.arabicLabel ?? "عقار"} - ${r.city}',
        type: r.listingType?.name ?? 'sale',
        value: num.tryParse(valueCtrl.text) ?? 0,
        commission: num.tryParse(commCtrl.text) ?? 0,
        viaBorrow: lender != null,
        counterpartyId: lender?.toBrokerId,
        offerId: lender?.offerId,
        status: lender != null ? 'pending' : 'verified',
      ));
      if (lender != null) {
        await _notifications.send(
          toUid: lender.toBrokerId,
          title: 'صفقة بانتظار تأكيدك',
          body:
              'سُجّلت صفقة على عرضك المُستعار "${lender.offerTitle}". أكّدها من تقاريرك.',
          type: 'deal',
        );
      }
      await _requestService.close(r.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(lender != null
                ? 'تم تسجيل الصفقة وأُرسلت لصاحب العرض للتأكيد ⏳'
                : 'تم توثيق الصفقة وإضافتها لسجلك ✅')));
      }
    }
    valueCtrl.dispose();
    commCtrl.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _borrow(
      BuildContext context, PropertyRequest r, MatchResult m, String uid) async {
    try {
      await _borrowService.create(BorrowRequest(
        id: '',
        offerId: m.offer.id,
        offerTitle: m.offer.title,
        offerPrice: m.offer.price,
        requestId: r.id,
        requestName: r.name,
        fromBrokerId: uid,
        toBrokerId: m.offer.ownerId ?? '',
        score: m.score,
      ));
      await _notifications.send(
        toUid: m.offer.ownerId ?? '',
        title: 'طلب استعارة جديد',
        body: 'وسيط يطلب استعارة عرضك "${m.offer.title}" لعميل مطابق.',
        type: 'borrow_request',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم إرسال طلب الاستعارة لصاحب العرض ✅')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<List<PropertyRequest>>(
      stream: _requestService.watchClaimedBy(uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final mine = snap.data!.where((r) => r.status != 'closed').toList();
        if (mine.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('لسه ماستلمتش أي طلب — استلم من "الفرص" أو من توصيات إعلاناتك',
                  textAlign: TextAlign.center),
            ),
          );
        }
        return StreamBuilder<List<Property>>(
          stream: _propertyService.watchProperties(),
          builder: (context, offersSnap) {
            final allOffers = (offersSnap.data ?? [])
                .where((o) => o.status == PropertyStatus.available)
                .toList();
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: mine.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) =>
                  _card(context, mine[i], allOffers, uid),
            );
          },
        );
      },
    );
  }

  Widget _card(BuildContext context, PropertyRequest r,
      List<Property> allOffers, String uid) {
    final recos = MatchingService.offersForRequest(r, allOffers);
    final want = [
      if (r.type != null) r.type!.arabicLabel,
      if (r.listingType != null) r.listingType!.arabicLabel,
      r.city,
      if (r.district.isNotEmpty) r.district,
    ].where((e) => e.isNotEmpty).join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_ind, color: Color(0xFF0A2540)),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(r.name.isEmpty ? 'عميل' : r.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      if (r.targetBrokerId != null) ...[
                        const SizedBox(width: 6),
                        const Tooltip(
                          message: 'طلب خاص موجّه إليك',
                          child: Icon(Icons.lock, size: 16, color: Color(0xFFC9A227)),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _logDeal(context, r, uid),
                  icon: const Icon(Icons.verified, size: 16),
                  label: const Text('توثيق صفقة'),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => _requestService.close(r.id),
                ),
              ],
            ),
            Text('يطلب: $want',
                style: const TextStyle(color: Color(0xFF6B7785))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _open('tel:${r.phone}'),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('اتصال'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _open(
                        'https://wa.me/${r.phone.replaceAll(RegExp(r"[^0-9]"), "")}'),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('واتساب'),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('التوصيات (${recos.length} عرض مطابق)',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
            const SizedBox(height: 6),
            if (recos.isEmpty)
              const Text('لا توجد عروض مطابقة حالياً',
                  style: TextStyle(color: Color(0xFF6B7785)))
            else
              ...recos.take(5).map((m) => _recoTile(context, r, m, uid)),
          ],
        ),
      ),
    );
  }

  Widget _recoTile(
      BuildContext context, PropertyRequest r, MatchResult m, String uid) {
    final o = m.offer;
    final mineOffer = o.ownerId == uid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: const Color(0xFF0A2540),
                borderRadius: BorderRadius.circular(6)),
            child: Text('${m.score.round()}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${o.title} · ${_fmt.format(o.price)} ريال',
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (mineOffer)
            const Chip(
              label: Text('عرضك', style: TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            )
          else
            TextButton(
              onPressed:
                  o.allowBorrow ? () => _borrow(context, r, m, uid) : null,
              child: Text(o.allowBorrow ? 'طلب استعارة' : 'غير متاح',
                  style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
