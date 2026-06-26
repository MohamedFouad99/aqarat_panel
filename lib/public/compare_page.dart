import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/property.dart';
import '../services/compare_service.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'widgets/public_page.dart';

/// صفحة مقارنة العقارات جنب بعض.
class ComparePage extends StatelessWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PropertyService();
    return PublicPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.compare_arrows, color: AppColors.navy),
                    const SizedBox(width: 8),
                    const Text('مقارنة العقارات',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => CompareService.instance.clear(),
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('مسح الكل'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<List<String>>(
                  valueListenable: CompareService.instance.ids,
                  builder: (context, ids, _) {
                    if (ids.isEmpty) return _empty(context);
                    return StreamBuilder<List<Property>>(
                      stream: service.watchProperties(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final byId = {
                          for (final p in snapshot.data!) p.id: p
                        };
                        final items = ids
                            .map((id) => byId[id])
                            .whereType<Property>()
                            .toList();
                        if (items.isEmpty) return _empty(context);
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: items
                                .map((p) => _column(context, p))
                                .toList(),
                          ),
                        );
                      },
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

  Widget _empty(BuildContext context) => Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.compare_arrows,
                  size: 64, color: AppColors.border),
              const SizedBox(height: 12),
              const Text('مفيش عقارات للمقارنة',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              const Text('افتح أي عقار واضغط "أضف للمقارنة"',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/properties'),
                child: const Text('تصفّح العقارات'),
              ),
            ],
          ),
        ),
      );

  Widget _column(BuildContext context, Property p) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(left: 12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: p.images.isNotEmpty
                      ? Image.network(p.images.first, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                              color: AppColors.bg,
                              child: const Icon(Icons.apartment)))
                      : Container(
                          color: AppColors.bg,
                          child: const Icon(Icons.apartment)),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => CompareService.instance.remove(p.id),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  _row('السعر', formatPrice(p.price)),
                  _row('النوع', p.type.arabicLabel),
                  _row('العرض', p.listingType.arabicLabel),
                  _row('المساحة', '${p.area} م²'),
                  _row('غرف النوم', '${p.bedrooms}'),
                  _row('الحمامات', '${p.bathrooms}'),
                  _row('المدينة', p.city),
                  _row('المنطقة', p.district),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => context.go('/property/${p.id}'),
                    child: const Text('عرض'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
