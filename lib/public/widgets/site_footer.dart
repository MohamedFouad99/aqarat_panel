import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// فوتر الموقع.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 700;
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.apartment, color: AppColors.gold, size: 24),
                      SizedBox(width: 8),
                      Text('عقاراتي',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(
                    width: 280,
                    child: Text(
                      'منصة عقارية لعرض وتصفّح العقارات للبيع والإيجار في مصر.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (!wide) const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('روابط',
                      style: TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _link(context, 'الرئيسية', '/'),
                  _link(context, 'العقارات', '/properties'),
                  _link(context, 'الباقات', '/packages'),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 40),
          const Text(
            '© 2026 عقاراتي — جميع الحقوق محفوظة',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, String label, String path) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: InkWell(
          onTap: () => context.go(path),
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
      );
}
