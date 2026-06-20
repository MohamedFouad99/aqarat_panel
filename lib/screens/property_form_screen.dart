import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/property.dart';
import '../services/property_service.dart';

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
  final _picker = ImagePicker();

  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _area;
  late final TextEditingController _bedrooms;
  late final TextEditingController _bathrooms;
  late final TextEditingController _city;
  late final TextEditingController _district;
  late final TextEditingController _description;

  late PropertyType _type;
  late ListingType _listingType;
  late PropertyStatus _status;
  late bool _featured;

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
    _description = TextEditingController(text: p?.description ?? '');
    _type = p?.type ?? PropertyType.apartment;
    _listingType = p?.listingType ?? ListingType.sale;
    _status = p?.status ?? PropertyStatus.available;
    _featured = p?.featured ?? false;
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
                        child: _text(_price, 'السعر (ج.م)',
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
                      Expanded(child: _text(_city, 'المدينة', required: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _text(_district, 'المنطقة', required: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _text(_description, 'الوصف', maxLines: 4),
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

  Widget _text(
    TextEditingController c,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return 'مطلوب';
        if (number && v != null && v.isNotEmpty && num.tryParse(v) == null) {
          return 'رقم غير صحيح';
        }
        return null;
      },
    );
  }
}
