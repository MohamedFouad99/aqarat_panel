import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/property.dart';
import '../services/auth_service.dart';
import '../services/property_service.dart';
import '../services/user_service.dart';
import '../utils/saudi_cities.dart';
import '../utils/validators.dart';

class PropertyFormScreen extends StatefulWidget {
  /// لو null يبقى إضافة جديدة، غير كده تعديل.
  const PropertyFormScreen({super.key, this.property});

  final Property? property;

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PropertyService();
  final _users = UserService();
  final _auth = AuthService();
  final _picker = ImagePicker();

  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _area;
  late final TextEditingController _bedrooms;
  late final TextEditingController _bathrooms;
  late final TextEditingController _city;
  late final TextEditingController _district;
  late final TextEditingController _description;
  late final TextEditingController _advertiserName;
  late final TextEditingController _advertiserPhone;
  late final TextEditingController _videoUrl;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _mapsLink;
  String? _cityValue;

  Future<void> _prefillFromProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final profile = await _users.get(uid);
    if (profile == null || !mounted) return;
    setState(() {
      if (_advertiserName.text.isEmpty) _advertiserName.text = profile.name;
      if (_advertiserPhone.text.isEmpty) _advertiserPhone.text = profile.phone;
    });
  }

  /// استخراج إحداثيات من رابط Google Maps بأشكاله المختلفة.
  void _parseMapsLink() {
    final url = _mapsLink.text.trim();
    if (url.isEmpty) {
      _snack('الصق رابط الخريطة الأول');
      return;
    }

    // نجرّب أكتر من شكل بالترتيب:
    final patterns = <RegExp>[
      RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)'), // .../@30.04,31.23,15z
      RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)'), // ...!3d30.04!4d31.23
      RegExp(r'[?&]q(?:uery)?=(-?\d+\.\d+),(-?\d+\.\d+)'), // ?q=30.04,31.23
      RegExp(r'(-?\d+\.\d+),\s*(-?\d+\.\d+)'), // أي رقمين بفاصلة
    ];

    for (final re in patterns) {
      final m = re.firstMatch(url);
      if (m != null) {
        setState(() {
          _latitude.text = m.group(1)!;
          _longitude.text = m.group(2)!;
          _mapsLink.clear();
        });
        _snack('تم استخراج الإحداثيات ✅ (${m.group(1)}, ${m.group(2)})');
        return;
      }
    }

    _snack(
        'الرابط ده مفيهوش إحداثيات. لو رابط مختصر (goo.gl) افتحه الأول وانسخ الرابط الكامل، أو دخّل الإحداثيات يدوياً.');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  late PropertyType _type;
  late ListingType _listingType;
  late PropertyStatus _status;
  late bool _featured;
  late bool _furnished;
  late final TextEditingController _floor;
  late final TextEditingController _finishing;
  late Set<String> _amenities;
  late OfferVisibility _visibility;
  late bool _receiveRequests;
  late bool _allowBorrow;

  static const _amenityOptions = [
    'مصعد',
    'جراج',
    'أمن وحراسة',
    'حديقة',
    'مسبح',
    'شرفة',
    'تكييف مركزي',
    'مطبخ راكب',
  ];

  /// روابط الصور المرفوعة بالفعل (في حالة التعديل).
  late List<String> _images;

  /// صور جديدة مختارة لسه ما اترفعتش.
  final List<({Uint8List bytes, String name})> _pendingImages = [];

  bool _saving = false;

  bool get _isEdit => widget.property != null;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _title = TextEditingController(text: p?.title ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _area = TextEditingController(text: p?.area.toString() ?? '');
    _bedrooms = TextEditingController(text: p?.bedrooms.toString() ?? '0');
    _bathrooms = TextEditingController(text: p?.bathrooms.toString() ?? '0');
    _city = TextEditingController(text: p?.city ?? '');
    _district = TextEditingController(text: p?.district ?? '');
    _cityValue = (p?.city ?? '').isNotEmpty ? p!.city : null;
    _description = TextEditingController(text: p?.description ?? '');
    _advertiserName = TextEditingController(text: p?.advertiserName ?? '');
    _advertiserPhone = TextEditingController(text: p?.advertiserPhone ?? '');
    _videoUrl = TextEditingController(text: p?.videoUrl ?? '');
    _latitude = TextEditingController(text: p?.latitude?.toString() ?? '');
    _longitude = TextEditingController(text: p?.longitude?.toString() ?? '');
    _mapsLink = TextEditingController();
    // في حالة الإضافة الجديدة، نملا بيانات المعلن من ملفه التعريفي تلقائياً.
    if (!_isEdit) _prefillFromProfile();
    _type = p?.type ?? PropertyType.apartment;
    _listingType = p?.listingType ?? ListingType.sale;
    _status = p?.status ?? PropertyStatus.available;
    _featured = p?.featured ?? false;
    _furnished = p?.furnished ?? false;
    _floor = TextEditingController(text: p?.floor?.toString() ?? '');
    _finishing = TextEditingController(text: p?.finishing ?? '');
    _amenities = {...(p?.amenities ?? const [])};
    _visibility = p?.visibility ?? OfferVisibility.public;
    _receiveRequests = p?.receiveRequests ?? true;
    _allowBorrow = p?.allowBorrow ?? true;
    _images = List<String>.from(p?.images ?? const []);
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _price,
      _area,
      _bedrooms,
      _bathrooms,
      _city,
      _district,
      _description,
      _advertiserName,
      _advertiserPhone,
      _videoUrl,
      _latitude,
      _longitude,
      _mapsLink,
      _floor,
      _finishing,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    for (final x in picked) {
      final bytes = await x.readAsBytes();
      _pendingImages.add((bytes: bytes, name: x.name));
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // نتأكد إن بيانات المعلن اتحمّلت من الملف التعريفي.
      if (!_isEdit) await _prefillFromProfile();
      // ارفع الصور الجديدة الأول واجمع روابطها.
      final uploaded = <String>[];
      for (var i = 0; i < _pendingImages.length; i++) {
        final img = _pendingImages[i];
        final url = await _service.uploadImage(
          img.bytes,
          fileName:
              '${DateTime.now().millisecondsSinceEpoch}_${i}_${img.name}',
        );
        uploaded.add(url);
      }

      final property = Property(
        id: widget.property?.id ?? '',
        title: _title.text.trim(),
        type: _type,
        listingType: _listingType,
        price: num.tryParse(_price.text) ?? 0,
        area: num.tryParse(_area.text) ?? 0,
        bedrooms: int.tryParse(_bedrooms.text) ?? 0,
        bathrooms: int.tryParse(_bathrooms.text) ?? 0,
        city: _city.text.trim(),
        district: _district.text.trim(),
        description: _description.text.trim(),
        images: [..._images, ...uploaded],
        status: _status,
        featured: _featured,
        advertiserName: _advertiserName.text.trim().isEmpty
            ? null
            : _advertiserName.text.trim(),
        advertiserPhone: _advertiserPhone.text.trim().isEmpty
            ? null
            : _advertiserPhone.text.trim(),
        videoUrl:
            _videoUrl.text.trim().isEmpty ? null : _videoUrl.text.trim(),
        latitude: double.tryParse(_latitude.text.trim()),
        longitude: double.tryParse(_longitude.text.trim()),
        ownerId: widget.property?.ownerId ?? _auth.currentUser?.uid,
        furnished: _furnished,
        floor: int.tryParse(_floor.text.trim()),
        finishing:
            _finishing.text.trim().isEmpty ? null : _finishing.text.trim(),
        amenities: _amenities.toList(),
        visibility: _visibility,
        receiveRequests: _receiveRequests,
        allowBorrow: _allowBorrow,
      );

      if (_isEdit) {
        await _service.update(property);
      } else {
        await _service.create(property);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'تعديل عقار' : 'إضافة عقار'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _text(_title, 'عنوان العقار', required: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PropertyType>(
                          initialValue: _type,
                          decoration: const InputDecoration(labelText: 'النوع'),
                          items: PropertyType.values
                              .map((t) => DropdownMenuItem(
                                  value: t, child: Text(t.arabicLabel)))
                              .toList(),
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ListingType>(
                          initialValue: _listingType,
                          decoration:
                              const InputDecoration(labelText: 'العرض'),
                          items: ListingType.values
                              .map((t) => DropdownMenuItem(
                                  value: t, child: Text(t.arabicLabel)))
                              .toList(),
                          onChanged: (v) => setState(() => _listingType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _text(_price, 'السعر (ريال)',
                            required: true, number: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _text(_area, 'المساحة (م²)',
                            required: true, number: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _text(_bedrooms, 'غرف النوم', number: true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _text(_bathrooms, 'الحمامات', number: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _cityDropdown()),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _text(_district, 'المنطقة', required: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _text(_description, 'الوصف', maxLines: 4),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('تفاصيل إضافية',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _text(_floor, 'الدور', number: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child:
                              _text(_finishing, 'التشطيب (سوبر لوكس...)')),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('مفروش'),
                    value: _furnished,
                    onChanged: (v) => setState(() => _furnished = v),
                  ),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('المميزات',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _amenityOptions.map((a) {
                      final sel = _amenities.contains(a);
                      return FilterChip(
                        label: Text(a),
                        selected: sel,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _amenities.add(a);
                          } else {
                            _amenities.remove(a);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('بيانات المعلن والوسائط',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'بتتعبّى تلقائيًا من ملفك — تقدر تعدّلها لو حبيت.',
                    style: TextStyle(color: Color(0xFF6B7785), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _text(_advertiserName, 'اسم المعلن')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _text(_advertiserPhone, 'جوال المعلن (سعودي)',
                              validator: Validators.saudiPhone)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _text(_videoUrl, 'رابط فيديو (YouTube) — اختياري'),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('موقع العقار على الخريطة',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _mapsLink,
                          decoration: const InputDecoration(
                            labelText: 'الصق رابط من Google Maps',
                            hintText:
                                'https://maps.google.com/?q=30.0444,31.2357',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _parseMapsLink,
                        icon: const Icon(Icons.my_location),
                        label: const Text('استخراج'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _text(_latitude, 'خط العرض (lat)',
                              number: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _text(_longitude, 'خط الطول (lng)',
                              number: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PropertyStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'الحالة'),
                    items: PropertyStatus.values
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s.arabicLabel)))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                  SwitchListTile(
                    title: const Text('عقار مميّز'),
                    value: _featured,
                    onChanged: (v) => setState(() => _featured = v),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('نوع العرض وإعداداته',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<OfferVisibility>(
                    segments: const [
                      ButtonSegment(
                          value: OfferVisibility.public,
                          icon: Icon(Icons.public),
                          label: Text('عام')),
                      ButtonSegment(
                          value: OfferVisibility.private,
                          icon: Icon(Icons.lock_outline),
                          label: Text('خاص (مخفي)')),
                    ],
                    selected: {_visibility},
                    onSelectionChanged: (s) =>
                        setState(() => _visibility = s.first),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _visibility == OfferVisibility.public
                        ? 'العرض العام يظهر للجميع في السوق ويدخل المطابقة.'
                        : 'العرض الخاص لا يظهر في السوق، لكنه يدخل المطابقة الذكية فقط.',
                    style: const TextStyle(
                        color: Color(0xFF6B7785), fontSize: 12),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('استقبال الطلبات والتواصل'),
                    value: _receiveRequests,
                    onChanged: (v) => setState(() => _receiveRequests = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('السماح باستعارة العرض من وسطاء آخرين'),
                    value: _allowBorrow,
                    onChanged: (v) => setState(() => _allowBorrow = v),
                  ),
                  const SizedBox(height: 12),
                  _buildImagesSection(),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة العقار'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('الصور'),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('إضافة صور'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _images.length; i++)
              _thumb(
                child: Image.network(_images[i], fit: BoxFit.cover),
                onRemove: () => setState(() => _images.removeAt(i)),
              ),
            for (var i = 0; i < _pendingImages.length; i++)
              _thumb(
                child: Image.memory(_pendingImages[i].bytes, fit: BoxFit.cover),
                onRemove: () => setState(() => _pendingImages.removeAt(i)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _thumb({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 90, height: 90, child: child),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cityDropdown() {
    // ندعم قيمة قديمة مش في القائمة (إعلانات سابقة)
    final items = <String>[
      ...kSaudiCities,
      if (_cityValue != null && !kSaudiCities.contains(_cityValue))
        _cityValue!,
    ];
    return DropdownButtonFormField<String>(
      initialValue: _cityValue,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'المدينة'),
      items: items
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
      onChanged: (v) => setState(() {
        _cityValue = v;
        _city.text = v ?? '';
      }),
    );
  }

  Widget _text(
    TextEditingController c,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: validator ??
          (v) {
            if (required && (v == null || v.trim().isEmpty)) return 'مطلوب';
            if (number &&
                v != null &&
                v.isNotEmpty &&
                num.tryParse(v) == null) {
              return 'رقم غير صحيح';
            }
            return null;
          },
    );
  }
}
