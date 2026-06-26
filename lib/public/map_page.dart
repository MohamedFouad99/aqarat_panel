import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'widgets/site_header.dart';

/// خريطة بكل العقارات اللي ليها موقع — اضغط على السعر يفتح العقار.
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PropertyService();
    return Scaffold(
      appBar: const SiteHeader(),
      body: StreamBuilder<List<Property>>(
        stream: service.watchProperties(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final located = snapshot.data!
              .where((p) =>
                  p.status == PropertyStatus.available &&
                  p.latitude != null &&
                  p.longitude != null)
              .toList();

          if (located.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'لا توجد عقارات على الخريطة بعد.\nأضف موقع للعقار من لوحة التحكم.',
                    textAlign: TextAlign.center),
              ),
            );
          }

          final center = LatLng(located.first.latitude!, located.first.longitude!);
          return FlutterMap(
            options: MapOptions(
              initialCenter: located.length == 1 ? center : const LatLng(26.8, 30.8),
              initialZoom: located.length == 1 ? 14 : 6,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aqarat.panel',
              ),
              MarkerLayer(
                markers: located
                    .map((p) => Marker(
                          point: LatLng(p.latitude!, p.longitude!),
                          width: 110,
                          height: 40,
                          child: _PricePin(property: p),
                        ))
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PricePin extends StatelessWidget {
  const _PricePin({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/property/${property.id}'),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          formatPriceShort(property.price),
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          maxLines: 1,
        ),
      ),
    );
  }
}
