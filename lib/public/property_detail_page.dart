import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/property.dart';
import '../services/compare_service.dart';
import '../services/property_service.dart';
import '../services/recently_viewed_service.dart';
import '../services/report_service.dart';
import '../services/views_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'widgets/favorite_button.dart';
import 'widgets/property_grid.dart';
import 'widgets/public_page.dart';
import 'widgets/static_map.dart';

class PropertyDetailPage extends StatefulWidget {
  const PropertyDetailPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  final _service = PropertyService();
  final _reportService = ReportService();
  final _viewsService = ViewsService();
  late Future<Property?> _future;
  int _activeImage = 0;

  @override
  void initState() {
    super.initState();
    _future = _service.getById(widget.propertyId);
    // تسجيل المشاهدة + إضافته لـ "آخر ما شاهدت"
    _viewsService.increment(widget.propertyId);
    RecentlyViewedService.instance.add(widget.propertyId);
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// مشاركة الإعلان: نسخ الرابط + خيار واتساب.
  Future<void> _share(BuildContext context, Property p) async {
    final url = Uri.base.resolve('/property/${p.id}').toString();
    final text = '${p.title} - $url';
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('نسخ الرابط'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الرابط ✅')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: const Text('مشاركة عبر واتساب'),
              onTap: () {
                Navigator.pop(ctx);
                _open('https://wa.me/?text=${Uri.encodeComponent(text)}');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PublicPage(
      child: FutureBuilder<Property?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(80),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final p = snapshot.data;
          if (p == null) {
            return Padding(
              padding: const EdgeInsets.all(80),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('العقار غير موجود'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('عودة للعقارات'),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _content(context, p),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBanner(BuildContext context, Property p) {
    final isRent = p.listingType == ListingType.rent;
    final label = p.status == PropertyStatus.reserved
        ? 'هذا العقار محجوز مؤقتاً'
        : isRent
            ? 'تم تأجير هذا العقار'
            : 'تم بيع هذا العقار';
    final color = p.status == PropertyStatus.reserved
        ? const Color(0xFFC9921f)
        : const Color(0xFFD9534F);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
              p.status == PropertyStatus.reserved
                  ? Icons.lock_clock
                  : Icons.do_not_disturb_on,
              color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('تصفّح المتاح'),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, Property p) {
    final wide = MediaQuery.of(context).size.width > 900;
    final gallery = _gallery(p);
    final info = _infoPanel(context, p);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // breadcrumb
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
                onPressed: () => context.go('/'),
                child: const Text('الرئيسية')),
            const Icon(Icons.chevron_left, size: 18),
            TextButton(
                onPressed: () => context.go('/'),
                child: const Text('العقارات')),
            const Icon(Icons.chevron_left, size: 18),
            Text(p.title,
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
        if (p.status != PropertyStatus.available) ...[
          _statusBanner(context, p),
          const SizedBox(height: 12),
        ],
        Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: wide ? 3 : 0, child: gallery),
            SizedBox(width: wide ? 24 : 0, height: wide ? 0 : 20),
            Expanded(flex: wide ? 2 : 0, child: info),
          ],
        ),
        const SizedBox(height: 28),
        _section('الوصف', Text(p.description.isEmpty ? '—' : p.description,
            style: const TextStyle(height: 1.8, fontSize: 15))),
        if (p.amenities.isNotEmpty) ...[
          const SizedBox(height: 20),
          _section(
            'المميزات',
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.amenities
                  .map((a) => Chip(
                        avatar: const Icon(Icons.check_circle,
                            size: 16, color: AppColors.success),
                        label: Text(a),
                      ))
                  .toList(),
            ),
          ),
        ],
        if (p.videoUrl != null && p.videoUrl!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _section(
            'جولة بالفيديو',
            OutlinedButton.icon(
              onPressed: () => _open(p.videoUrl!),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('مشاهدة الفيديو'),
            ),
          ),
        ],
        if (p.latitude != null && p.longitude != null) ...[
          const SizedBox(height: 20),
          _section(
            'الموقع على الخريطة',
            StaticMap(latitude: p.latitude!, longitude: p.longitude!),
          ),
        ],
        const SizedBox(height: 24),
        Center(child: _reportButton(context, p)),
        const SizedBox(height: 28),
        _similarSection(context, p),
        const SizedBox(height: 28),
      ],
    );
  }

  // زر الإبلاغ عن الإعلان
  Widget _reportButton(BuildContext context, Property p) {
    return OutlinedButton.icon(
      onPressed: () => _showReportDialog(context, p),
      icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.red),
      label:
          const Text('إبلاغ عن الإعلان', style: TextStyle(color: Colors.red)),
      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
    );
  }

  // إعلانات مشابهة (نفس المدينة أو النوع)
  Widget _similarSection(BuildContext context, Property current) {
    return StreamBuilder<List<Property>>(
      stream: _service.watchProperties(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final similar = snapshot.data!
            .where((p) =>
                p.id != current.id &&
                p.status == PropertyStatus.available &&
                p.visibility == OfferVisibility.public &&
                (p.city == current.city || p.type == current.type))
            .take(4)
            .toList();
        if (similar.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إعلانات مشابهة',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy)),
            const SizedBox(height: 12),
            PropertyGrid(similar),
          ],
        );
      },
    );
  }

  Future<void> _showReportDialog(BuildContext context, Property p) async {
    const reasons = [
      'محتال / نصب',
      'بيانات غير صحيحة',
      'العقار تم بيعه أو تأجيره',
      'صور مضللة',
      'سبب آخر',
    ];
    var selected = reasons.first;
    final noteCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('إبلاغ عن الإعلان'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('سبب البلاغ:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  isExpanded: true,
                  items: reasons
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setLocal(() => selected = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      hintText: 'تفاصيل إضافية (اختياري)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('إرسال البلاغ')),
          ],
        ),
      ),
    );

    if (submitted == true) {
      try {
        await _reportService.submit(
          propertyId: p.id,
          propertyTitle: p.title,
          reason: selected,
          note: noteCtrl.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم إرسال البلاغ، شكراً لك 🙏')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تعذّر إرسال البلاغ: $e')));
        }
      }
    }
    noteCtrl.dispose();
  }

  // معرض الصور
  Widget _gallery(Property p) {
    if (p.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.apartment, size: 64, color: AppColors.border),
        ),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              p.images[_activeImage],
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: AppColors.bg),
            ),
          ),
        ),
        if (p.images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: p.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => InkWell(
                onTap: () => setState(() => _activeImage = i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 96,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: i == _activeImage
                            ? AppColors.gold
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.network(p.images[i], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // لوحة المعلومات
  Widget _infoPanel(BuildContext context, Property p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _tag(p.listingType.arabicLabel, AppColors.navy, Colors.white),
                const SizedBox(width: 6),
                _tag(p.type.arabicLabel, AppColors.bg, AppColors.navy),
                const Spacer(),
                IconButton(
                  tooltip: 'مشاركة',
                  onPressed: () => _share(context, p),
                  icon: const Icon(Icons.share_outlined, color: AppColors.navy),
                ),
                FavoriteButton(propertyId: p.id),
              ],
            ),
            const SizedBox(height: 14),
            Text(formatPrice(p.price),
                style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(p.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(child: Text('${p.city} · ${p.district}')),
              ],
            ),
            const SizedBox(height: 6),
            StreamBuilder<int>(
              stream: _viewsService.watch(widget.propertyId),
              builder: (_, s) => Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${s.data ?? 0} مشاهدة',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                _spec(Icons.straighten, '${p.area} م²', 'المساحة'),
                if (p.bedrooms > 0)
                  _spec(Icons.king_bed_outlined, '${p.bedrooms}', 'غرف'),
                if (p.bathrooms > 0)
                  _spec(Icons.bathtub_outlined, '${p.bathrooms}', 'حمامات'),
                if (p.floor != null)
                  _spec(Icons.stairs, '${p.floor}', 'الدور'),
                _spec(p.furnished ? Icons.chair : Icons.chair_outlined,
                    p.furnished ? 'مفروش' : 'غير مفروش', 'الفرش'),
                if (p.finishing != null && p.finishing!.isNotEmpty)
                  _spec(Icons.brush, p.finishing!, 'التشطيب'),
              ],
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<List<String>>(
              valueListenable: CompareService.instance.ids,
              builder: (context, ids, _) {
                final inList = ids.contains(p.id);
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final ok = CompareService.instance.toggle(p.id);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'الحد الأقصى ${CompareService.max} عقارات للمقارنة')));
                      }
                    },
                    icon: Icon(inList ? Icons.check_circle : Icons.compare_arrows,
                        size: 18),
                    label: Text(inList ? 'في المقارنة ✓' : 'أضف للمقارنة'),
                  ),
                );
              },
            ),
            const Divider(height: 28),
            // المعلن
            Text('المُعلِن',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.navy,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: p.advertiserName?.isNotEmpty == true
                      ? InkWell(
                          onTap: () => context.go(
                              '/advertiser/${Uri.encodeComponent(p.advertiserName!)}'),
                          child: Text(
                            p.advertiserName!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                                decoration: TextDecoration.underline),
                          ),
                        )
                      : const Text('معلن عقاري',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (p.advertiserPhone?.isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _open('tel:${p.advertiserPhone}'),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('اتصال'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(
                          'https://wa.me/${p.advertiserPhone!.replaceAll(RegExp(r"[^0-9]"), "")}'),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('واتساب'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy)),
          const SizedBox(height: 10),
          child,
        ],
      );

  Widget _spec(IconData icon, String value, String label) => Column(
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
        ],
      );

  Widget _tag(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
      );
}
