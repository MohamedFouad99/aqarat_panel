import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/property.dart';
import '../models/property_request.dart';
import '../services/property_service.dart';
import '../services/recently_viewed_service.dart';
import '../services/request_service.dart';
import '../services/views_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
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
  final _requestService = RequestService();
  final _viewsService = ViewsService();
  late final TextEditingController _q;

  // وضع السوق: requests | sale | rent
  String _mode = 'sale';
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

  void _setMode(String m) {
    setState(() {
      _mode = m;
      _listing = m == 'sale'
          ? ListingType.sale
          : m == 'rent'
              ? ListingType.rent
              : null;
      if (m == 'requests') _showDetailed = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _q.clear();
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
      final l = ListingType.fromString(widget.initialListing);
      _listing = l;
      _mode = l == ListingType.rent ? 'rent' : 'sale';
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
      if (p.visibility != OfferVisibility.public) return false; // الخاص لا يظهر
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

  List<PropertyRequest> _filterRequests(List<PropertyRequest> items) {
    final q = _q.text.trim().toLowerCase();
    return items.where((r) {
      if (_type != null && r.type != null && r.type != _type) return false;
      if (q.isNotEmpty) {
        final hay = '${r.city} ${r.district} ${r.notes}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PublicPage(
      child: Column(
        children: [
          _hero(context),
          _statsBand(),
          _resultsSection(),
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
      padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 16, vertical: 44),
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
              Text('ابحث عن عقارك المثالي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: wide ? 34 : 26,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('سوق الطلبات وإعلانات البيع والإيجار في مكان واحد',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _modeToggle(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _q,
                            decoration: InputDecoration(
                              hintText: 'المدينة أو المنطقة...',
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              suffixIcon: _q.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () =>
                                          setState(() => _q.clear()),
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_mode != 'requests') ...[
                          const SizedBox(width: 8),
                          _detailedButton(wide),
                        ],
                      ],
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

  Widget _detailedButton(bool wide) {
    final active = _showDetailed;
    return Material(
      color: active ? AppColors.navy : AppColors.bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _showDetailed = !_showDetailed),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 16 : 12, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune,
                  size: 20, color: active ? AppColors.gold : AppColors.navy),
              if (wide) ...[
                const SizedBox(width: 6),
                Text('فلتر تفصيلي',
                    style: TextStyle(
                        color: active ? Colors.white : AppColors.navy,
                        fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeToggle() {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _modeSegment('requests', 'سوق الطلبات', Icons.campaign),
          _modeSegment('sale', 'إعلانات البيع', Icons.sell),
          _modeSegment('rent', 'إعلانات الإيجار', Icons.vpn_key),
        ],
      ),
    );
  }

  Widget _modeSegment(String value, String label, IconData icon) {
    final selected = _mode == value;
    return Expanded(
      child: InkWell(
        onTap: () => _setMode(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20, color: selected ? AppColors.gold : AppColors.navy),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : AppColors.navy)),
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: StreamBuilder<List<Property>>(
            stream: _service.watchProperties(),
            builder: (context, snapshot) {
              final all = (snapshot.data ?? [])
                  .where((p) =>
                      p.status == PropertyStatus.available &&
                      p.visibility == OfferVisibility.public)
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

  // ===== النتائج (تتبدّل حسب الوضع) =====
  Widget _resultsSection() {
    final wide = MediaQuery.of(context).size.width > 700;
    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 12, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showDetailed && _mode != 'requests') ...[
                _detailedFilter(),
                const SizedBox(height: 16),
              ],
              if (_mode == 'requests')
                _requestsMarket()
              else
                _listingsResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listingsResults() {
    return StreamBuilder<List<Property>>(
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
                Flexible(
                  child: Text('${results.length} عقار',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.navy)),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    initialValue: _sort,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'ترتيب', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('الأحدث')),
                      DropdownMenuItem(
                          value: 'priceAsc', child: Text('الأقل سعراً')),
                      DropdownMenuItem(
                          value: 'priceDesc', child: Text('الأعلى سعراً')),
                      DropdownMenuItem(
                          value: 'mostViewed', child: Text('الأكثر مشاهدة')),
                    ],
                    onChanged: (v) => setState(() => _sort = v ?? 'newest'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('لا توجد عقارات مطابقة')),
              )
            else
              PropertyGrid(results),
          ],
        );
      },
    );
  }

  // ===== سوق الطلبات (طلبات العملاء العامة) =====
  Widget _requestsMarket() {
    return StreamBuilder<List<PropertyRequest>>(
      stream: _requestService.watchOpenRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = _filterRequests(snapshot.data ?? []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, color: AppColors.navy),
                const SizedBox(width: 8),
                Text('${all.length} طلب من عملاء يبحثون عن عقار',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.navy)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
                'هؤلاء عملاء يطلبون عقارات — سجّل الدخول كوسيط للرد والتواصل.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 14),
            if (all.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('لا توجد طلبات مطابقة حالياً')),
              )
            else
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 1000
                      ? 3
                      : c.maxWidth > 640
                          ? 2
                          : 1;
                  final gap = 14.0;
                  final w = (c.maxWidth - gap * (cols - 1)) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: all
                        .map((r) => SizedBox(
                            width: cols == 1 ? c.maxWidth : w,
                            child: _requestCard(r)))
                        .toList(),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _requestCard(PropertyRequest r) {
    final want = [
      if (r.type != null) r.type!.arabicLabel,
      if (r.listingType != null) r.listingType!.arabicLabel,
      r.city,
      if (r.district.isNotEmpty) r.district,
      if (r.bedrooms != null) '${r.bedrooms}+ غرف',
    ].where((e) => e.isNotEmpty).join(' · ');
    final budget = (r.minPrice == null && r.maxPrice == null)
        ? 'أي ميزانية'
        : 'من ${r.minPrice != null ? formatPrice(r.minPrice!) : "—"} '
            'إلى ${r.maxPrice != null ? formatPrice(r.maxPrice!) : "—"}';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.bg,
                  child: Icon(Icons.person_search, color: AppColors.navy),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('عميل يطلب عقار',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(r.listingType?.arabicLabel ?? 'طلب',
                      style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(want, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.payments,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(budget,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ),
              ],
            ),
            if (r.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('رُدّ كوسيط'),
              ),
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
            Row(
              children: [
                const Text('الفلتر التفصيلي',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.navy)),
                const Spacer(),
                if (_hasFilters)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.filter_alt_off, size: 18),
                    label: const Text('مسح'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PropertyType?>(
              initialValue: _type,
              isExpanded: true,
              decoration:
                  const InputDecoration(labelText: 'نوع العقار', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('كل الأنواع')),
                ...PropertyType.values.map(
                    (t) => DropdownMenuItem(value: t, child: Text(t.arabicLabel))),
              ],
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 12),
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
      margin: EdgeInsets.symmetric(horizontal: wide ? 24 : 12, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            padding: const EdgeInsets.all(24),
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
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.navy,
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
                      // استبعد المُباع/المؤجَّر والمخفي
                      .where((p) =>
                          p.status == PropertyStatus.available &&
                          p.visibility == OfferVisibility.public)
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
