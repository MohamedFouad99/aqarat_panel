import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../models/property_request.dart';
import '../services/request_service.dart';

/// تبويب طلبات العملاء في لوحة المعلن — الوسيط يشوف الطلبات ويتواصل.
class RequestsView extends StatelessWidget {
  RequestsView({super.key});

  final _service = RequestService();
  final _priceFormat = NumberFormat.decimalPattern('en');

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _budget(PropertyRequest r) {
    if (r.minPrice == null && r.maxPrice == null) return 'أي ميزانية';
    final min = r.minPrice != null ? _priceFormat.format(r.minPrice) : '—';
    final max = r.maxPrice != null ? _priceFormat.format(r.maxPrice) : '—';
    return 'من $min إلى $max ريال';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PropertyRequest>>(
      stream: _service.watchOpenRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const Center(child: Text('لا توجد طلبات حالياً'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _card(context, requests[i]),
        );
      },
    );
  }

  Widget _card(BuildContext context, PropertyRequest r) {
    final wantParts = [
      if (r.type != null) r.type!.arabicLabel else 'أي نوع',
      if (r.listingType != null) r.listingType!.arabicLabel,
      r.city,
      if (r.district.isNotEmpty) r.district,
      if (r.bedrooms != null) '${r.bedrooms}+ غرف',
    ];
    return Card(
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
                IconButton(
                  tooltip: 'تم التعامل',
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _service.close(r.id),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(wantParts.join(' · '),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_budget(r),
                style: const TextStyle(color: Color(0xFF6B7785))),
            if (r.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.notes),
            ],
            const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }
}
