import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import 'widgets/property_card.dart';
import 'widgets/public_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = PropertyService();
  final _city = TextEditingController();
  ListingType _listing = ListingType.sale;
  PropertyType? _type;

  void _search() {
    final params = <String, String>{
      'listingType': _listing.name,
      if (_type != null) 'type': _type!.name,
      if (_city.text.trim().isNotEmpty) 'q': _city.text.trim(),
    };
    context.go(Uri(path: '/properties', queryParameters: params).toString());
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PublicPage(
      child: Column(
        children: [
          _hero(context),
          _categories(context),
          _featured(),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 760;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              const Text(
                'ابحث عن عقارك المثالي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'آلاف العقارات للبيع والإيجار في مكان واحد',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 17),
              ),
              const SizedBox(height: 32),
              // صندوق البحث المختصر
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  children: [
                    // بيع / إيجار
                    Expanded(
                      flex: wide ? 2 : 0,
                      child: SegmentedButton<ListingType>(
                        segments: const [
                          ButtonSegment(
                              value: ListingType.sale, label: Text('بيع')),
                          ButtonSegment(
                              value: ListingType.rent, label: Text('إيجار')),
                        ],
                        selected: {_listing},
                        onSelectionChanged: (s) =>
                            setState(() => _listing = s.first),
                      ),
                    ),
                    SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 12),
                    Expanded(
                      flex: wide ? 3 : 0,
                      child: DropdownButtonFormField<PropertyType?>(
                        initialValue: _type,
                        decoration: const InputDecoration(hintText: 'النوع'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('كل الأنواع')),
                          ...PropertyType.values.map((t) => DropdownMenuItem(
                              value: t, child: Text(t.arabicLabel))),
                        ],
                        onChanged: (v) => setState(() => _type = v),
                      ),
                    ),
                    SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 12),
                    Expanded(
                      flex: wide ? 4 : 0,
                      child: TextField(
                        controller: _city,
                        decoration: const InputDecoration(
                          hintText: 'المدينة أو المنطقة',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 12),
                    SizedBox(
                      width: wide ? null : double.infinity,
                      child: FilledButton(
                        onPressed: _search,
                        child: const Text('بحث'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تصفّح حسب النوع
  Widget _categories(BuildContext context) {
    const icons = {
      PropertyType.apartment: Icons.apartment,
      PropertyType.villa: Icons.villa,
      PropertyType.land: Icons.landscape,
      PropertyType.shop: Icons.storefront,
      PropertyType.office: Icons.business_center,
      PropertyType.building: Icons.location_city,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تصفّح حسب النوع',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: PropertyType.values.map((t) {
                  return InkWell(
                    onTap: () => context.go('/properties?type=${t.name}'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(icons[t], size: 34, color: AppColors.gold),
                          const SizedBox(height: 8),
                          Text(t.arabicLabel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featured() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'عقارات مميّزة',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy),
                  ),
                  TextButton(
                    onPressed: () => context.go('/properties'),
                    child: const Text('عرض الكل ←'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<Property>>(
                stream: _service.watchProperties(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final all = snapshot.data ?? [];
                  final available = all
                      .where((p) => p.status == PropertyStatus.available)
                      .toList();
                  // المميّزة أولاً، وإلا الأحدث
                  final featured =
                      available.where((p) => p.featured).toList();
                  final list =
                      (featured.isNotEmpty ? featured : available).take(8).toList();

                  if (list.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('لا توجد عقارات حالياً')),
                    );
                  }
                  return _grid(context, list);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شبكة كروت متجاوبة.
Widget _grid(BuildContext context, List<Property> items) {
  final width = MediaQuery.of(context).size.width;
  final cols = width > 1100
      ? 4
      : width > 800
          ? 3
          : width > 520
              ? 2
              : 1;
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.78,
    ),
    itemCount: items.length,
    itemBuilder: (_, i) => PropertyCard(property: items[i]),
  );
}
