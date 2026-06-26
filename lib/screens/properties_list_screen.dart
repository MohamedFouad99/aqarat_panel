import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/property.dart';
import '../models/property_request.dart';
import '../services/auth_service.dart';
import '../services/property_service.dart';
import '../services/request_service.dart';
import '../services/views_service.dart';
import 'property_form_screen.dart';
import 'requests_view.dart';

class PropertiesListScreen extends StatefulWidget {
  const PropertiesListScreen({super.key});

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  final _service = PropertyService();
  final _auth = AuthService();
  final _viewsService = ViewsService();
  final _requestService = RequestService();
  final _priceFormat = NumberFormat.decimalPattern('ar');

  String _search = '';
  PropertyType? _typeFilter;
  ListingType? _listingFilter;

  List<Property> _applyFilters(List<Property> items) {
    return items.where((p) {
      if (_typeFilter != null && p.type != _typeFilter) return false;
      if (_listingFilter != null && p.listingType != _listingFilter) {
        return false;
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final haystack =
            '${p.title} ${p.city} ${p.district} ${p.description}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openForm([Property? property]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyFormScreen(property: property),
      ),
    );
  }

  Future<void> _confirmDelete(Property p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العقار'),
        content: Text('متأكد من حذف "${p.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.delete(p.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('لوحة المعلن'),
            actions: [
              IconButton(
                tooltip: 'تسجيل الخروج',
                icon: const Icon(Icons.logout),
                onPressed: _auth.signOut,
              ),
            ],
            bottom: const TabBar(
              indicatorColor: Color(0xFFC9A227),
              indicatorWeight: 3,
              labelColor: Color(0xFFE3C766),
              unselectedLabelColor: Colors.white,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: TextStyle(fontSize: 14),
              tabs: [
                Tab(text: 'إعلاناتي', icon: Icon(Icons.home_work)),
                Tab(text: 'طلبات العملاء', icon: Icon(Icons.person_search)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('إضافة عقار'),
          ),
          body: TabBarView(
            children: [
              _myListingsTab(),
              RequestsView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _myListingsTab() {
    return StreamBuilder<List<Property>>(
      stream: _auth.currentUser != null
          ? _service.watchByOwner(_auth.currentUser!.uid)
          : _service.watchProperties(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final owned = snapshot.data!;
        final items = _applyFilters(owned);
        return Column(
          children: [
            _statsCard(owned),
            _buildFilters(),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('لا توجد عقارات مطابقة'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _buildTile(items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _statsCard(List<Property> owned) {
    final ids = owned.map((p) => p.id).toSet();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          _stat('إعلاناتي', '${owned.length}', Icons.home_work_outlined),
          const SizedBox(width: 10),
          FutureBuilder<Map<String, int>>(
            future: _viewsService.fetchAll(),
            builder: (_, snap) {
              final total = (snap.data ?? {})
                  .entries
                  .where((e) => ids.contains(e.key))
                  .fold<int>(0, (s, e) => s + e.value);
              return _stat('المشاهدات', '$total', Icons.visibility_outlined);
            },
          ),
          const SizedBox(width: 10),
          StreamBuilder<List<PropertyRequest>>(
            stream: _requestService.watchOpenRequests(),
            builder: (_, snap) => _stat('طلبات مفتوحة',
                '${snap.data?.length ?? 0}', Icons.person_search_outlined),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A2540),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC9A227), size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'بحث بالعنوان أو المدينة أو المنطقة...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<PropertyType?>(
                  initialValue: _typeFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'النوع',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل')),
                    ...PropertyType.values.map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.arabicLabel),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _typeFilter = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<ListingType?>(
                  initialValue: _listingFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'العرض',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('الكل')),
                    ...ListingType.values.map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.arabicLabel),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _listingFilter = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Property p) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: p.images.isNotEmpty
              ? Image.network(
                  p.images.first,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholderImage(),
                )
              : _placeholderImage(),
        ),
        title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${p.type.arabicLabel} · ${p.listingType.arabicLabel} · '
          '${p.city} ${p.district}\n'
          '${_priceFormat.format(p.price)} ريال · ${p.area} م² · ${p.status.arabicLabel}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _openForm(p);
            if (v == 'delete') _confirmDelete(p);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('تعديل')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
        onTap: () => _openForm(p),
      ),
    );
  }

  Widget _placeholderImage() => Container(
        width: 56,
        height: 56,
        color: Colors.grey.shade200,
        child: const Icon(Icons.home_outlined, color: Colors.grey),
      );
}
