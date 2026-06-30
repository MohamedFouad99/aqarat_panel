import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../models/property_request.dart';
import '../services/auth_service.dart';
import '../services/request_service.dart';
import '../services/user_service.dart';

/// "الفرص المفتوحة" — كل الطلبات المتاحة للوسطاء، وطلبات اختصاصك في الأعلى.
class OpportunitiesView extends StatelessWidget {
  OpportunitiesView({super.key});

  final _requestService = RequestService();
  final _userService = UserService();
  final _auth = AuthService();
  final _fmt = NumberFormat.decimalPattern('en');

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _claim(BuildContext context, PropertyRequest r) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ok = await _requestService.claim(r.id, uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'تم استلام الفرصة ✅ — في تبويب "طلباتي"'
          : 'وسيط آخر سبقك في الاستلام 🙏'),
    ));
  }

  bool _inSpecialty(PropertyRequest r, UserProfile? me) {
    if (me == null || me.city.isEmpty) return false;
    if (r.city.trim() != me.city.trim()) return false;
    if (me.districts.isEmpty || r.district.isEmpty) return true;
    return me.districts
        .map((d) => d.trim())
        .contains(r.district.trim());
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';
    return FutureBuilder<UserProfile?>(
      future: _userService.get(uid),
      builder: (context, meSnap) {
        final me = meSnap.data;
        return StreamBuilder<List<PropertyRequest>>(
          stream: _requestService.watchOpenRequests(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // الطلبات الموجّهة لوسطاء معيّنين مستبعدة (status != open أصلاً)
            final all = snap.data!;
            if (all.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد فرص مفتوحة حالياً',
                      textAlign: TextAlign.center),
                ),
              );
            }
            final specialty =
                all.where((r) => _inSpecialty(r, me)).toList();
            final others =
                all.where((r) => !_inSpecialty(r, me)).toList();

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (specialty.isNotEmpty) ...[
                  _sectionHeader('⭐ فرص في اختصاصك (${me?.city ?? ""})'),
                  ...specialty.map((r) => _card(context, r, true)),
                  const SizedBox(height: 16),
                ],
                _sectionHeader(specialty.isEmpty
                    ? 'كل الفرص المفتوحة'
                    : 'فرص أخرى'),
                ...others.map((r) => _card(context, r, false)),
                if (me != null && me.city.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'حدّد مدينة اختصاصك من "ملفي" عشان نظهّر فرص منطقتك أولاً.',
                      style: TextStyle(color: Color(0xFF6B7785), fontSize: 13),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF0A2540))),
      );

  Widget _card(BuildContext context, PropertyRequest r, bool specialty) {
    final want = [
      if (r.type != null) r.type!.arabicLabel,
      if (r.listingType != null) r.listingType!.arabicLabel,
      r.city,
      if (r.district.isNotEmpty) r.district,
      if (r.bedrooms != null) '${r.bedrooms}+ غرف',
    ].where((e) => e.isNotEmpty).join(' · ');
    final budget = (r.minPrice == null && r.maxPrice == null)
        ? 'أي ميزانية'
        : 'من ${r.minPrice != null ? _fmt.format(r.minPrice) : "—"} '
            'إلى ${r.maxPrice != null ? _fmt.format(r.maxPrice) : "—"} ريال';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: specialty
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFC9A227), width: 1.5))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_search, color: Color(0xFF0A2540)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.name.isEmpty ? 'عميل' : r.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (specialty)
                  const Icon(Icons.star, color: Color(0xFFC9A227), size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text('يطلب: $want',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(budget, style: const TextStyle(color: Color(0xFF6B7785))),
            if (r.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.notes),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _claim(context, r),
                icon: const Icon(Icons.assignment_turned_in, size: 18),
                label: const Text('استلام الفرصة'),
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
