import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// فوتر الموقع — تصميم مرتّب ومتوسّط.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  static const _links = [
    ('الرئيسية', '/'),
    ('العقارات', '/properties'),
    ('الخريطة', '/map'),
    ('اطلب عقارك', '/request'),
    ('دليل الوسطاء', '/agents'),
    ('حاسبة التمويل', '/mortgage'),
    ('الباقات', '/packages'),
    ('من نحن', '/about'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          // الشعار
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.apartment, color: AppColors.gold, size: 28),
              SizedBox(width: 8),
              Text('عقاراتي',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const SizedBox(
            width: 360,
            child: Text(
              'منصة عقارية لعرض وتصفّح العقارات للبيع والإيجار في السعودية.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          // الروابط في صف متوسّط ومتباعد
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final l in _links) _LinkChip(label: l.$1, path: l.$2),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            '© 2026 عقاراتي — جميع الحقوق محفوظة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label, required this.path});
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(path),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 14, color: Colors.white)),
    );
  }
}
