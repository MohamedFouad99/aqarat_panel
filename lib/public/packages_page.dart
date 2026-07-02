import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'widgets/public_page.dart';

class _Package {
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final bool highlighted;
  const _Package(this.name, this.price, this.period, this.features,
      {this.highlighted = false});
}

const _packages = [
  _Package('مجانية', '0', 'دائمًا', [
    'حتى 3 إعلانات',
    'صور للعقار',
    'ظهور عادي',
  ]),
  _Package('أساسية', '199', 'شهريًا', [
    'حتى 20 إعلان',
    'صور + فيديو',
    'ظهور أعلى في النتائج',
    'دعم فني',
  ], highlighted: true),
  _Package('مميزة', '499', 'شهريًا', [
    'إعلانات غير محدودة',
    'صور + فيديو + خرائط',
    'شارة "مميّز" على إعلاناتك',
    'أولوية في الظهور',
    'دعم فني سريع',
  ]),
];

class PackagesPage extends StatelessWidget {
  const PackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 820;
    return PublicPage(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.navy,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: const Column(
              children: [
                Text('باقات الاشتراك',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('اختر الباقة المناسبة لنشاطك العقاري',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final p in _packages)
                      Expanded(
                        flex: wide ? 1 : 0,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _card(context, p),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, _Package p) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.highlighted ? AppColors.gold : AppColors.border,
          width: p.highlighted ? 2.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (p.highlighted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('الأكثر شيوعًا',
                  style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          const SizedBox(height: 10),
          Text(p.name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(p.price,
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('ريال / ${p.period}',
                    style: const TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ),
          const Divider(height: 28),
          ...p.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/admin'),
              child: const Text('اشترك الآن'),
            ),
          ),
        ],
      ),
    );
  }
}
