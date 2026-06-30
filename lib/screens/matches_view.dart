import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../matching/matching_service.dart';
import '../models/property.dart';
import '../models/property_request.dart';
import '../services/auth_service.dart';
import '../services/property_service.dart';
import '../services/request_service.dart';

/// تبويب المطابقات الذكية في لوحة الوسيط:
/// بيطابق طلبات العملاء المفتوحة مع عروض الوسيط ويعرض أعلى نسبة لكل طلب.
class MatchesView extends StatelessWidget {
  MatchesView({super.key});

  final _propertyService = PropertyService();
  final _requestService = RequestService();
  final _auth = AuthService();
  final _fmt = NumberFormat.decimalPattern('en');

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _claim(BuildContext context, PropertyRequest r) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final ok = await _requestService.claim(r.id, uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'تم استلام الطلب ✅ — اتحوّل لـ "طلباتي"'
            : 'وسيط آخر سبقك في استلام الطلب 🙏'),
      ));
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
    final offersStream = uid != null
        ? _propertyService.watchByOwner(uid)
        : _propertyService.watchProperties();

    return StreamBuilder<List<Property>>(
      stream: offersStream,
      builder: (context, offersSnap) {
        if (!offersSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final offers = offersSnap.data!
            .where((o) => o.status == PropertyStatus.available)
            .toList();
        if (offers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('أضف عروضك الأول عشان نطابقها مع طلبات العملاء',
                  textAlign: TextAlign.center),
            ),
          );
        }

        return StreamBuilder<List<PropertyRequest>>(
          stream: _requestService.watchOpenRequests(),
          builder: (context, reqSnap) {
            if (!reqSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // لكل طلب، أفضل عرض مطابق من عروض الوسيط
            final matches = <MatchResult>[];
            for (final r in reqSnap.data!) {
              final best = MatchingService.bestOfferForRequest(r, offers);
              if (best != null) matches.add(best);
            }
            matches.sort((a, b) => b.score.compareTo(a.score));

            if (matches.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد طلبات مطابقة لعروضك حالياً',
                      textAlign: TextAlign.center),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _matchCard(context, matches[i]),
            );
          },
        );
      },
    );
  }

  Widget _matchCard(BuildContext context, MatchResult m) {
    final r = m.request;
    final o = m.offer;
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
                // دائرة النسبة
                Container(
                  width: 54,
                  height: 54,
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
                          fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name.isEmpty ? 'عميل' : r.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('يطلب: $want',
                          style: const TextStyle(color: Color(0xFF6B7785))),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.home_work_outlined,
                    size: 18, color: Color(0xFF0A2540)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('عرضك المطابق: ${o.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('${_fmt.format(o.price)} ريال',
                    style: const TextStyle(
                        color: Color(0xFF0A2540), fontWeight: FontWeight.bold)),
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
