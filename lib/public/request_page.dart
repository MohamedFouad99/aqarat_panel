import 'package:flutter/material.dart';

import '../models/property.dart';
import '../models/property_request.dart';
import '../services/request_service.dart';
import '../theme/app_theme.dart';
import 'widgets/public_page.dart';

/// صفحة "اطلب عقارك" — العميل بيكتب اللي بيدوّر عليه والوسطاء يردّوا.
class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = RequestService();

  final _city = TextEditingController();
  final _district = TextEditingController();
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();
  final _bedrooms = TextEditingController();
  final _notes = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  PropertyType? _type;
  ListingType _listing = ListingType.sale;
  bool _saving = false;
  bool _done = false;

  @override
  void dispose() {
    for (final c in [
      _city,
      _district,
      _minPrice,
      _maxPrice,
      _bedrooms,
      _notes,
      _name,
      _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.create(PropertyRequest(
        id: '',
        type: _type,
        listingType: _listing,
        city: _city.text.trim(),
        district: _district.text.trim(),
        minPrice: num.tryParse(_minPrice.text),
        maxPrice: num.tryParse(_maxPrice.text),
        bedrooms: int.tryParse(_bedrooms.text),
        notes: _notes.text.trim(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      ));
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذّر إرسال الطلب: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicPage(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _done ? _success() : _form(),
          ),
        ),
      ),
    );
  }

  Widget _success() => Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 64),
              const SizedBox(height: 16),
              const Text('تم إرسال طلبك بنجاح! 🎉',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'الوسطاء العقاريون بيشوفون طلبك ويتواصلون معك بأفضل العروض.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => setState(() {
                  _done = false;
                  _formKey.currentState?.reset();
                }),
                child: const Text('إرسال طلب آخر'),
              ),
            ],
          ),
        ),
      );

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هيدر تعريفي
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.navy, AppColors.navyLight]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اطلب عقارك',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(
                  'بدل ما تدوّر، اكتب اللي تبيه والوسطاء يوصلونه لك. مجاناً!',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<PropertyType?>(
                          initialValue: _type,
                          decoration:
                              const InputDecoration(labelText: 'نوع العقار'),
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('أي نوع')),
                            ...PropertyType.values.map((t) => DropdownMenuItem(
                                value: t, child: Text(t.arabicLabel))),
                          ],
                          onChanged: (v) => setState(() => _type = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<ListingType>(
                          initialValue: _listing,
                          decoration:
                              const InputDecoration(labelText: 'الغرض'),
                          items: ListingType.values
                              .map((t) => DropdownMenuItem(
                                  value: t, child: Text(t.arabicLabel)))
                              .toList(),
                          onChanged: (v) => setState(() => _listing = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _field(_city, 'المدينة', required: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_district, 'المنطقة')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _field(_minPrice, 'أقل سعر', number: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field(_maxPrice, 'أعلى سعر', number: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field(_bedrooms, 'غرف', number: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_notes, 'تفاصيل إضافية (اختياري)', maxLines: 3),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(child: _field(_name, 'اسمك', required: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _field(_phone, 'رقم الموبايل',
                              required: true, number: true)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                      label: const Text('إرسال الطلب'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
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
        return null;
      },
    );
  }
}
