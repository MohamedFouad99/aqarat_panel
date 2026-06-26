import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'widgets/public_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PublicPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('من نحن',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy)),
                const SizedBox(height: 12),
                const Text(
                  'عقاراتي منصة عقارية تجمع العقارات للبيع والإيجار في السعودية في مكان واحد، '
                  'وتسهّل التواصل بين الباحثين عن العقارات والوسطاء العقاريين. '
                  'تصفّح آلاف العقارات، أو اطلب عقارك وتوصلك العروض المناسبة.',
                  style: TextStyle(height: 1.9, fontSize: 15),
                ),
                const SizedBox(height: 28),
                const Text('ليه عقاراتي؟',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy)),
                const SizedBox(height: 12),
                ..._features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(f,
                                  style: const TextStyle(fontSize: 15))),
                        ],
                      ),
                    )),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, AppColors.navyLight]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('اتصل بنا',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _open('https://wa.me/966500000000'),
                            icon: const Icon(Icons.chat),
                            label: const Text('واتساب'),
                          ),
                          FilledButton.icon(
                            onPressed: () =>
                                _open('mailto:info@aqarat.example'),
                            icon: const Icon(Icons.email),
                            label: const Text('إيميل'),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.navy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _features = [
  'آلاف العقارات للبيع والإيجار في مكان واحد',
  'اطلب عقارك ويوصلك أفضل العروض من الوسطاء',
  'بحث وفلترة تفصيلية + خريطة تفاعلية',
  'تواصل مباشر مع المعلن (اتصال/واتساب)',
  'حاسبة تمويل عقاري ومقارنة بين العقارات',
];
