import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

/// خريطة تفاعلية لموقع العقار باستخدام OpenStreetMap — مجانية تماماً
/// (بدون مفتاح API ولا فوترة) + زر لفتح الموقع في خرائط جوجل.
class StaticMap extends StatelessWidget {
  const StaticMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.zoom = 15,
    this.height = 300,
  });

  final double latitude;
  final double longitude;
  final double zoom;
  final double height;

  Future<void> _openInGoogleMaps() async {
    final uri = Uri.parse('https://www.google.com/maps?q=$latitude,$longitude');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.aqarat.panel',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on,
                          color: AppColors.gold, size: 44),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _openInGoogleMaps,
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('فتح الموقع في خرائط جوجل'),
        ),
      ],
    );
  }
}
