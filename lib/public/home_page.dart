import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import '../services/recently_viewed_service.dart';
import '../services/views_service.dart';
import '../theme/app_theme.dart';
import 'widgets/property_grid.dart';
import 'widgets/public_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.initialListing,
    this.initialType,
    this.initialQuery,
  });

  final String? initialListing;
  final String? initialType;
  final String? initialQuery;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = PropertyService();
  final _viewsService = ViewsService();
  late final TextEditingController _q;

  ListingType? _listing;
  PropertyType? _type;
  double? _minPrice;
  double? _maxPrice;
  int _minBeds = 0;
  int _minBaths = 0;
  double? _minArea;
  bool _furnishedOnly = false;
  String _sort = 'newest';
  bool _showDetailed = false;
  Map<String, int> _views = {};

  void _clearFilters() {
    setState(() {
      _q.clear();
      _listing = null;
      _type = null;
      _minPrice = null;
      _maxPrice = null;
      _minBeds = 0;
      _minBaths = 0;
      _minArea = null;
      _furnishedOnly = false;
      _sort = 'newest';
    });
  }

  bool get _hasFilters =>
      _q.text.isNotEmpty ||
      _listing != null ||
      _type != null ||
      _minPrice != null ||
      _maxPrice != null ||
      _minBeds > 0 ||
      _minBaths > 0 ||
      _minArea != null ||
      _furnishedOnly;

  @override
  void initState() {
    super.initState();
    _q = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialListing != null) {
      _listing = ListingType.fromString(widget.initialListing);
    }
    if (widget.initialType != null) {
      _type = PropertyType.fromString(widget.initialType);
    }
    _viewsService.fetchAll().then((v) {
      if (mounted) setState(() => _views = v);
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Property> _filterAndSort(List<Property> items) {
    final filtered = items.where((p) {
      if (p.status != PropertyStatus.available) return false;
      if (_listing != null && p.listingType != _listing) return false;
      if (_type != null && p.type != _type) return false;
      if (_minPrice != null && p.price < _minPrice!) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      if (_minBeds > 0 && p.bedrooms < _minBeds) return false;
      if (_minBaths > 0 && p.bathrooms < _minBaths) return false;
      if (_minArea != null && p.area < _minArea!) return false;
      if (_furnishedOnly && !p.furnished) return false;
      final q = _q.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final hay =
            '${p.title} ${p.city} ${p.district} ${p.description}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case 'priceAsc':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'priceDesc':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'mostViewed':
        filtered
            .sort((a, b) => (_views[b.id] ?? 0).compareTo(_views[a.id] ?? 0));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return PublicPage(
      child: Column(
        children: [
          _hero(context),
          _statsBand(),
          _categories(context),
          _filterAndResults(),
          _requestCta(context),
          _recentlyViewed(),
        ],
      ),
    );
  }

  // ===== Hero =====
  Widget _hero(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 760;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
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
              const Text('ابحث عن عقارك المثالي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('آلاف العقارات للبيع والإيجار في مكان واحد',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  children: [
                    Expanded(
                      flex: wide ? 2 : 0,
                      child: SegmentedButton<ListingType?>(
                        segments: const [
                          ButtonSegment(value: null, label: Text('الكل')),
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
                    SizedBox(width: wide ? 10 : 0, height: wide ? 0 : 10),
                    Expanded(
                      flex: wide ? 4 : 0,
                      child: TextField(
                        controller: _q,
                        decoration: const InputDecoration(
                          hintText: 'المدينة أو المنطقة...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (_) => setState(() {}),
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

  // ===== شريط إحصائيات =====
  Widget _statsBand() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: StreamBuilder<List<Property>>(
            stream: _service.watchProperties(),
            builder: (context, snapshot) {
              final all = (snapshot.data ?? [])
                  .where((p) => p.status == PropertyStatus.available)
                  .toList();
              final cities = all.map((p) => p.city).toSet()..remove('');
              final agents = all
                  .map((p) => p.advertiserName ?? '')
                  .where((e) => e.isNotEmpty)
                  .toSet();
              return Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 24,
                runSpacing: 20,
                children: [
                  _statItem('${all.length}', 'عقار متاح', Icons.home_work),
                  _statItem('${cities.length}', 'مدينة', Icons.location_city),
                  _statItem('${agents.length}', 'وسيط', Icons.groups),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 30),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.navy)),
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
      ],
    );
  }

  // ===== تصفّح حسب النوع =====
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                spacing: 12,
                runSpacing: 12,
                children: [
                  _categoryCard(null, 'الكل', Icons.grid_view),
                  ...PropertyType.values.map(
                      (t) => _categoryCard(t, t.arabicLabel, icons[t]!)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(PropertyType? t, String label, IconData icon) {
    final selected = _type == t;
    return InkWell(
      onTap: () => setState(() => _type = t),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.navy : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32, color: selected ? AppColors.gold : AppColors.gold),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.navy)),
          ],
        ),
      ),
    );
  }

  // ===== الفلتر + النتائج =====
  Widget _filterAndResults() {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _filterBar(),
              if (_showDetailed) _detailedFilter(),
              const SizedBox(height: 16),
              StreamBuilder<List<Property>>(
                stream: _service.watchProperties(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final results = _filterAndSort(snapshot.data ?? []);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${results.length} عقار',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.navy)),
                          SizedBox(
                            width: 170,
                            child: DropdownButtonFormField<String>(
                              initialValue: _sort,
                              decoration: const InputDecoration(
                                  labelText: 'ترتيب', isDense: true),
                              items: const [
                                DropdownMenuItem(
                                    value: 'newest', child: Text('الأحدث')),
                                DropdownMenuItem(
                                    value: 'priceAsc',
                                    child: Text('الأقل سعراً')),
                                DropdownMenuItem(
                                    value: 'priceDesc',
                                    child: Text('الأعلى سعراً')),
                                DropdownMenuItem(
                                    value: 'mostViewed',
                                    child: Text('الأكثر مشاهدة')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _sort = v ?? 'newest'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (results.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child:
                              Center(child: Text('لا توجد عقارات مطابقة')),
                        )
                      else
                        PropertyGrid(results),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterBar() {
    final wide = MediaQuery.of(context).size.width > 700;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _q,
              decoration: InputDecoration(
                hintText: 'ابحث بالمدينة أو المنطقة أو العنوان...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _q.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _q.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              children: [
                Expanded(
                  flex: wide ? 1 : 0,
                  child: DropdownButtonFormField<ListingType?>(
                    initialValue: _listing,
                    decoration: const InputDecoration(
                        labelText: 'العرض', isDense: true),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('بيع وإيجار')),
                      ...ListingType.values.map((t) => DropdownMenuItem(
                          value: t, child: Text(t.arabicLabel))),
                    ],
                    onChanged: (v) => setState(() => _listing = v),
                  ),
                ),
                SizedBox(width: wide ? 10 : 0, height: wide ? 0 : 10),
                Expanded(
                  flex: wide ? 1 : 0,
                  child: DropdownButtonFormField<PropertyType?>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                        labelText: 'النوع', isDense: true),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('كل الأنواع')),
                      ...PropertyType.values.map((t) => DropdownMenuItem(
                          value: t, child: Text(t.arabicLabel))),
                    ],
                    onChanged: (v) => setState(() => _type = v),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showDetailed = !_showDetailed),
                  icon: Icon(_showDetailed ? Icons.expand_less : Icons.tune),
                  label: Text(
                      _showDetailed ? 'إخفاء الفلتر التفصيلي' : 'فلتر تفصيلي'),
                ),
                const Spacer(),
                if (_hasFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off, size: 18),
                    label: const Text('مسح الفلاتر'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailedFilter() {
    final wide = MediaQuery.of(context).size.width > 700;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              children: [
                Expanded(
                  flex: wide ? 1 : 0,
                  child: _numField(
                      'أقل سعر', (v) => setState(() => _minPrice = v)),
                ),
                SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 12),
                Expanded(
                  flex: wide ? 1 : 0,
                  child: _numField(
                      'أعلى سعر', (v) => setState(() => _maxPrice = v)),
                ),
                SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 12),
                Expanded(
                  flex: wide ? 1 : 0,
                  child: _numField('أقل مساحة (م²)',
                      (v) => setState(() => _minArea = v)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Text('غرف النوم: '),
                ...List.generate(5, (i) {
                  return ChoiceChip(
                    label: Text(i == 0 ? 'الكل' : '+$i'),
                    selected: _minBeds == i,
                    onSelected: (_) => setState(() => _minBeds = i),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Text('الحمامات: '),
                ...List.generate(4, (i) {
                  return ChoiceChip(
                    label: Text(i == 0 ? 'الكل' : '+$i'),
                    selected: _minBaths == i,
                    onSelected: (_) => setState(() => _minBaths = i),
                  );
                }),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilterChip(
                label: const Text('مفروش فقط'),
                selected: _furnishedOnly,
                onSelected: (v) => setState(() => _furnishedOnly = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String hint, ValueChanged<double?> onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: hint, isDense: true),
      onChanged: (v) => onChanged(v.isEmpty ? null : double.tryParse(v)),
    );
  }

  // ===== بانر اطلب عقارك =====
  Widget _requestCta(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 720;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldLight]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 1 : 0,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ما لقيت اللي تدوّر عليه؟',
                          style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('اكتب طلبك ويوصلك أفضل العروض من الوسطاء — مجاناً.',
                          style:
                              TextStyle(color: AppColors.navy, fontSize: 15)),
                    ],
                  ),
                ),
                SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                FilledButton.icon(
                  onPressed: () => context.go('/request'),
                  icon: const Icon(Icons.add_home_work),
                  label: const Text('اطلب عقارك الآن'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== شاهدت مؤخراً =====
  Widget _recentlyViewed() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: RecentlyViewedService.instance.ids,
      builder: (context, ids, _) {
        if (ids.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: StreamBuilder<List<Property>>(
                stream: _service.watchProperties(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final byId = {for (final p in snapshot.data!) p.id: p};
                  final items = ids
                      .map((id) => byId[id])
                      .whereType<Property>()
                      .take(4)
                      .toList();
                  if (items.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('شاهدت مؤخرًا',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy)),
                      const SizedBox(height: 16),
                      PropertyGrid(items),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
