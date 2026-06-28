import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/property.dart';
import '../services/favorites_service.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import 'widgets/property_grid.dart';
import 'widgets/public_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

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
                  children: const [
                    Icon(Icons.favorite, color: Colors.red),
                    SizedBox(width: 8),
                    Text('المفضلة',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy)),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Property>>(
                  stream: service.watchProperties(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final all = snapshot.data!;
                    return ValueListenableBuilder<Set<String>>(
                      valueListenable: FavoritesService.instance.ids,
                      builder: (context, favIds, _) {
                        final favs =
                            all.where((p) => favIds.contains(p.id)).toList();
                        if (favs.isEmpty) return _empty(context);
                        return PropertyGrid(favs);
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
              const Icon(Icons.favorite_border,
                  size: 64, color: AppColors.border),
              const SizedBox(height: 12),
              const Text('لسه مفيش عقارات في المفضلة',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('تصفّح العقارات'),
              ),
            ],
          ),
        ),
      );
}
