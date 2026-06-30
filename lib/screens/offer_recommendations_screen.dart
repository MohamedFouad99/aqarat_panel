import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../matching/matching_service.dart';
import '../models/app_notification.dart';
import '../models/borrow_request.dart';
import '../models/property.dart';
import '../models/property_request.dart';
import '../services/auth_service.dart';
import '../services/borrow_service.dart';
import '../services/property_service.dart';
import '../services/request_service.dart';
import 'property_form_screen.dart';

/// شاشة الإعلان مع التوصيات (طلبات مطابقة) — المطابقة نظام خفي،
/// اللي بيظهر للوسيط هو التوصيات جوّه إعلانه.
class OfferRecommendationsScreen extends StatelessWidget {
  OfferRecommendationsScreen({super.key, required this.offer});

  final Property offer;
  final _requestService = RequestService();
  final _borrowService = BorrowService();
  final _propertyService = PropertyService();
  final _notifications = NotificationService();
  final _auth = AuthService();
  final _fmt = NumberFormat.decimalPattern('en');

  Future<void> _setStatus(
      BuildContext context, PropertyStatus status) async {
    await _propertyService.setStatus(offer.id, status);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == PropertyStatus.sold
            ? 'تم تعليم العقار كمُنجَز — اختفى من الموقع والمطابقات ✅'
            : status == PropertyStatus.reserved
                ? 'تم الحجز المؤقت ⏸️'
                : 'تمت إعادة التنشيط 🔄')));
    Navigator.of(context).maybePop();
  }

  Future<void> _offerCooperation(
      BuildContext context, PropertyRequest r, double score) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || r.claimedBy == null) return;
    try {
      await _borrowService.create(BorrowRequest(
        id: '',
        offerId: offer.id,
        offerTitle: offer.title,
        offerPrice: offer.price,
        requestId: r.id,
        requestName: r.name,
        fromBrokerId: uid, // صاحب العرض يبادر
        toBrokerId: r.claimedBy!, // الوسيط اللي استلم الطلب
        score: score,
        kind: 'cooperation',
      ));
      await _notifications.send(
        toUid: r.claimedBy!,
        title: 'عرض تعاون جديد',
        body: 'وسيط يعرض عليك عرضه "${offer.title}" لعميلك المطابق.',
        type: 'borrow_request',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم إرسال عرض التعاون للوسيط ✅')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _claim(BuildContext context, PropertyRequest r) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final okClaim = await _requestService.claim(r.id, uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(okClaim
          ? 'تم استلام الطلب ✅ — في تبويب "طلباتي"'
          : 'وسيط آخر سبقك في استلام الطلب 🙏'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعلان والتوصيات'),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'حالة العقار',
              icon: const Icon(Icons.flag_outlined),
              onSelected: (v) {
                if (v == 'sold') _setStatus(context, PropertyStatus.sold);
                if (v == 'reserved') {
                  _setStatus(context, PropertyStatus.reserved);
                }
                if (v == 'available') {
                  _setStatus(context, PropertyStatus.available);
                }
              },
              itemBuilder: (_) => [
                if (offer.status != PropertyStatus.sold)
                  const PopupMenuItem(
                      value: 'sold',
                      child: Text('✅ تمّت الصفقة (بيع/إيجار)')),
                if (offer.status == PropertyStatus.available)
                  const PopupMenuItem(
                      value: 'reserved', child: Text('⏸️ حجز مؤقت')),
                if (offer.status != PropertyStatus.available)
                  const PopupMenuItem(
                      value: 'available', child: Text('🔄 إعادة تنشيط')),
              ],
            ),
            IconButton(
              tooltip: 'تعديل الإعلان',
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PropertyFormScreen(property: offer))),
            ),
          ],
        ),
        body: Column(
          children: [
            // ملخص الإعلان
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF4F6FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(offer.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      if (offer.visibility == OfferVisibility.private)
                        const Chip(
                          label: Text('خاص', style: TextStyle(fontSize: 11)),
                          avatar: Icon(Icons.lock, size: 14),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${offer.type.arabicLabel} · ${offer.listingType.arabicLabel} · '
                      '${offer.city} ${offer.district} · ${_fmt.format(offer.price)} ريال',
                      style: const TextStyle(color: Color(0xFF6B7785))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('توصيات: طلبات عملاء مطابقة لإعلانك'),
                    StreamBuilder<List<PropertyRequest>>(
                      stream: _requestService.watchOpenRequests(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        final recos = MatchingService.requestsForOffer(
                            offer, snap.data!);
                        if (recos.isEmpty) {
                          return _emptyNote(
                              'لا توجد طلبات مطابقة متاحة حالياً');
                        }
                        return Column(
                          children: recos
                              .map((m) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: _recoCard(context, m),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('فرص تعاون: طلبات محجوزة مطابقة لعرضك'),
                    StreamBuilder<List<PropertyRequest>>(
                      stream: _requestService.watchClaimedRequests(),
                      builder: (context, snap) {
                        final uid = _auth.currentUser?.uid;
                        if (!snap.hasData) {
                          return const Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  Center(child: CircularProgressIndicator()));
                        }
                        // طلبات محجوزة من وسطاء آخرين (مش أنا) ومطابقة لعرضي
                        final claimed = snap.data!
                            .where((r) =>
                                r.claimedBy != null && r.claimedBy != uid)
                            .toList();
                        final recos =
                            MatchingService.requestsForOffer(offer, claimed);
                        if (recos.isEmpty) {
                          return _emptyNote(
                              'لا توجد طلبات محجوزة مطابقة حالياً');
                        }
                        return Column(
                          children: recos
                              .map((m) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: _coopCard(context, m),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0A2540))),
      );

  Widget _emptyNote(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t, style: const TextStyle(color: Color(0xFF6B7785))),
      );

  Widget _coopCard(BuildContext context, MatchResult m) {
    final r = m.request;
    final pct = m.score.round();
    final want = [
      if (r.type != null) r.type!.arabicLabel,
      if (r.listingType != null) r.listingType!.arabicLabel,
      r.city,
      if (r.district.isNotEmpty) r.district,
    ].where((e) => e.isNotEmpty).join(' · ');
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFC9A227)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFC9A227),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('$pct%',
                      style: const TextStyle(
                          color: Color(0xFF0A2540),
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('عميل وسيط آخر يطلب: $want',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('عرضك مطابق — اعرض التعاون على الوسيط المستلِم.',
                style: TextStyle(color: Color(0xFF6B7785), fontSize: 13)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _offerCooperation(context, r, m.score),
                icon: const Icon(Icons.handshake, size: 18),
                label: const Text('اعرض تعاون'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A227),
                    foregroundColor: const Color(0xFF0A2540)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recoCard(BuildContext context, MatchResult m) {
    final r = m.request;
    final pct = m.score.round();
    final color = pct >= 85
        ? const Color(0xFF1E8E4E)
        : pct >= 70
            ? const Color(0xFFC9921f)
            : const Color(0xFF6B7785);
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
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text('$pct%',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name.isEmpty ? 'عميل' : r.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('يطلب: $want',
                          style: const TextStyle(color: Color(0xFF6B7785))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _claim(context, r),
                icon: const Icon(Icons.assignment_turned_in, size: 18),
                label: const Text('استلام الطلب'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2540),
                    foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
          ],
        ),
      ),
    );
  }
}
