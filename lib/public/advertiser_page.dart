import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'widgets/property_grid.dart';
import 'widgets/public_page.dart';

/// صفحة الملف التعريفي للمعلن — بياناته وكل إعلاناته.
class AdvertiserPage extends StatelessWidget {
  const AdvertiserPage({super.key, required this.name});

  final String name;

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final service = PropertyService();
    return PublicPage(
      child: StreamBuilder<List<Property>>(
        stream: service.watchProperties(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final listings = snapshot.data!
              .where((p) =>
                  (p.advertiserName ?? '').trim() == name.trim() &&
                  p.status == PropertyStatus.available &&
                  p.visibility == OfferVisibility.public)
              .toList();
          final phone = listings.map((p) => p.advertiserPhone).firstWhere(
              (p) => (p ?? '').isNotEmpty,
              orElse: () => null);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<UserProfile?>(
                      future: listings.isNotEmpty &&
                              listings.first.ownerId != null
                          ? UserService().get(listings.first.ownerId!)
                          : Future<UserProfile?>.value(null),
                      builder: (_, us) => _profileCard(context, phone,
                          listings.length, us.data?.verified ?? false),
                    ),
                    if (listings.isNotEmpty &&
                        (listings.first.ownerId ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.go(
                              '/request?broker=${listings.first.ownerId}'
                              '&bname=${Uri.encodeComponent(name)}'),
                          icon: const Icon(Icons.add_home_work),
                          label: const Text('اطلب عقار عبر هذا الوسيط'),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.navy),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text('إعلانات ${name.isEmpty ? "المعلن" : name}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                    const SizedBox(height: 16),
                    if (listings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child:
                            Center(child: Text('لا توجد إعلانات لهذا المعلن')),
                      )
                    else
                      PropertyGrid(listings),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileCard(
      BuildContext context, String? phone, int count, bool verified) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.gold,
            child: Icon(Icons.person, size: 40, color: AppColors.navy),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name.isEmpty ? 'معلن عقاري' : name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          color: AppColors.goldLight, size: 22),
                    ],
                  ],
                ),
                if (verified)
                  const Text('معلن موثّق',
                      style: TextStyle(
                          color: AppColors.goldLight, fontSize: 12)),
                const SizedBox(height: 4),
                Text('$count إعلان منشور',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          if ((phone ?? '').isNotEmpty) ...[
            IconButton.filled(
              onPressed: () => _open('tel:$phone'),
              icon: const Icon(Icons.call),
              style: IconButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _open(
                  'https://wa.me/${phone!.replaceAll(RegExp(r"[^0-9]"), "")}'),
              icon: const Icon(Icons.chat),
              style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy),
            ),
          ],
        ],
      ),
    );
  }
}
