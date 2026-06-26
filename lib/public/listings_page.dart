import 'package:flutter/material.dart';

import '../models/property.dart';
import '../services/property_service.dart';
import '../services/views_service.dart';
import '../theme/app_theme.dart';
import 'widgets/property_card.dart';
import 'widgets/public_page.dart';

class ListingsPage extends StatefulWidget {
  const ListingsPage({
    super.key,
    this.initialListing,
    this.initialType,
    this.initialQuery,
  });

  final String? initialListing;
  final String? initialType;
  final String? initialQuery;

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  final _service = PropertyService();
  final _viewsService = ViewsService();
  Map<String, int> _views = {};
  late final TextEditingController _q;

  ListingType? _listing;
  PropertyType? _type;
  double? _minPrice;
  double? _maxPrice;
  int _minBeds = 0;
  double? _minArea;
  bool _showDetailed = false;
  String _sort = 'newest'; // newest | priceAsc | priceDesc

  List<Property> _sortResults(List<Property> items) {
    final list = [...items];
    switch (_sort) {
      case 'priceAsc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'priceDesc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'mostViewed':
        list.sort((a, b) =>
            (_views[b.id] ?? 0).compareTo(_views[a.id] ?? 0));
        break;
      // newest: محفوظ ترتيبه من Firestore (الأحدث أولاً)
    }
    return list;
  }

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

  List<Property> _filter(List<Property> items) {
    return items.where((p) {
      if (p.status != PropertyStatus.available) return false;
      if (_listing != null && p.listingType != _listing) return false;
      if (_type != null && p.type != _type) return false;
      if (_minPrice != null && p.price < _minPrice!) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      if (_minBeds > 0 && p.bedrooms < _minBeds) return false;
      if (_minArea != null && p.area < _minArea!) return false;
      final q = _q.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final hay =
            '${p.title} ${p.city} ${p.district} ${p.description}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PublicPage(
      child: Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _quickFilter(),
                  if (_showDetailed) _detailedFilter(),
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
                      final results =
                          _sortResults(_filter(snapshot.data ?? []));
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
                                width: 180,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _sort,
                                  decoration: const InputDecoration(
                                      labelText: 'ترتيب', isDense: true),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'newest',
                                        child: Text('الأحدث')),
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
                          const SizedBox(height: 12),
                          if (results.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                  child: Text('لا توجد عقارات مطابقة')),
                            )
                          else
                            _grid(context, results),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
            ),
      );
  }

  // الفلتر المختصر
  Widget _quickFilter() {
    final wide = MediaQuery.of(context).size.width > 760;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              children: [
                Expanded(
                  flex: wide ? 3 : 0,
                  child: TextField(
                    controller: _q,
                    decoration: const InputDecoration(
                      hintText: 'ابحث بالمدينة أو المنطقة...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(width: wide ? 10 : 0, height: wide ? 0 : 10),
                Expanded(
                  flex: wide ? 2 : 0,
                  child: DropdownButtonFormField<ListingType?>(
                    initialValue: _listing,
                    decoration: const InputDecoration(hintText: 'العرض'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('بيع وإيجار')),
                      ...ListingType.values.map((t) => DropdownMenuItem(
                          value: t, child: Text(t.arabicLabel))),
                    ],
                    onChanged: (v) => setState(() => _listing = v),
                  ),
                ),
                SizedBox(width: wide ? 10 : 0, height: wide ? 0 : 10),
                Expanded(
                  flex: wide ? 2 : 0,
                  child: DropdownButtonFormField<PropertyType?>(
                    initialValue: _type,
                    decoration: const InputDecoration(hintText: 'النوع'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('كل الأنواع')),
                      ...PropertyType.values.map((t) => DropdownMenuItem(
                          value: t, child: Text(t.arabicLabel))),
                    ],
                    onChanged: (v) => setState(() => _type = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => _showDetailed = !_showDetailed),
                icon: Icon(_showDetailed
                    ? Icons.expand_less
                    : Icons.tune),
                label: Text(_showDetailed ? 'إخفاء الفلتر التفصيلي' : 'فلتر تفصيلي'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // الفلتر التفصيلي
  Widget _detailedFilter() {
    final wide = MediaQuery.of(context).size.width > 760;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('فلتر تفصيلي',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 12),
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 1 : 0,
                  child: _numField('أقل سعر',
                      (v) => setState(() => _minPrice = v)),
                ),
                SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 12),
                Expanded(
                  flex: wide ? 1 : 0,
                  child: _numField('أعلى سعر',
                      (v) => setState(() => _maxPrice = v)),
                ),
                SizedBox(width: wide ? 12 : 0, height: wide ? 0 : 12),
                Expanded(
                  flex: wide ? 1 : 0,
                  child: _numField('أقل مساحة (م²)',
                      (v) => setState(() => _minArea = v)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('غرف النوم (الأدنى): '),
                const SizedBox(width: 8),
                ...List.generate(5, (i) {
                  final n = i; // 0..4 (0 = الكل)
                  final selected = _minBeds == n;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(n == 0 ? 'الكل' : '+$n'),
                      selected: selected,
                      onSelected: (_) => setState(() => _minBeds = n),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String hint, ValueChanged<double?> onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(hintText: hint),
      onChanged: (v) => onChanged(v.isEmpty ? null : double.tryParse(v)),
    );
  }
}

Widget _grid(BuildContext context, List<Property> items) {
  final width = MediaQuery.of(context).size.width;
  final cols = width > 1100
      ? 3
      : width > 760
          ? 2
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
      childAspectRatio: 0.8,
    ),
    itemCount: items.length,
    itemBuilder: (_, i) => PropertyCard(property: items[i]),
  );
}
