import 'package:flutter/material.dart';

import '../../services/favorites_service.dart';
import '../../theme/app_theme.dart';

/// زر القلب لإضافة/إزالة عقار من المفضلة.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.propertyId, this.filledBg = true});

  final String propertyId;
  final bool filledBg;

  @override
  Widget build(BuildContext context) {
    final fav = FavoritesService.instance;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: fav.ids,
      builder: (context, ids, _) {
        final active = ids.contains(propertyId);
        final icon = Icon(
          active ? Icons.favorite : Icons.favorite_border,
          color: active ? Colors.red : (filledBg ? AppColors.navy : Colors.white),
          size: 20,
        );
        return Material(
          color: filledBg ? Colors.white : Colors.transparent,
          shape: const CircleBorder(),
          elevation: filledBg ? 1 : 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => fav.toggle(propertyId),
            child: Padding(padding: const EdgeInsets.all(8), child: icon),
          ),
        );
      },
    );
  }
}
