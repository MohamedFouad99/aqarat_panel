import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/property.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import 'favorite_button.dart';

/// كرت عرض عقار في الشبكة.
class PropertyCard extends StatelessWidget {
  const PropertyCard({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final p = property;
    return Card(
      child: InkWell(
        onTap: () => context.go('/property/${p.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة + الشارات
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: p.images.isNotEmpty
                      ? Image.network(
                          p.images.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => _imgPlaceholder(),
                        )
                      : _imgPlaceholder(),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _chip(p.listingType.arabicLabel,
                          bg: AppColors.navy, fg: Colors.white),
                      if (_isNew(p)) ...[
                        const SizedBox(height: 6),
                        _chip('🆕 جديد',
                            bg: AppColors.success, fg: Colors.white),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: FavoriteButton(propertyId: p.id),
                ),
                if (p.featured)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: _chip(
                      '⭐ مميّز',
                      bg: AppColors.gold,
                      fg: AppColors.navy,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatPrice(p.price),
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${p.city} · ${p.district}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _spec(Icons.straighten, '${p.area} م²'),
                      if (p.bedrooms > 0)
                        _spec(Icons.king_bed_outlined, '${p.bedrooms}'),
                      if (p.bathrooms > 0)
                        _spec(Icons.bathtub_outlined, '${p.bathrooms}'),
                      _chip(p.type.arabicLabel,
                          bg: AppColors.bg, fg: AppColors.navy),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spec(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      );

  // "جديد" لو اتضاف خلال آخر 7 أيام
  bool _isNew(Property p) {
    final c = p.createdAt;
    if (c == null) return false;
    return DateTime.now().difference(c).inDays < 7;
  }

  Widget _chip(String text, {required Color bg, required Color fg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );

  Widget _imgPlaceholder() => Container(
        color: AppColors.bg,
        alignment: Alignment.center,
        child: const Icon(Icons.apartment, size: 48, color: AppColors.border),
      );
}
