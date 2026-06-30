import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/saudi_cities.dart';
import '../utils/validators.dart';

/// شاشة الملف التعريفي للوسيط — البيانات + الاختصاص الجغرافي (مدينة + حتى 5 أحياء).
class BrokerProfileScreen extends StatefulWidget {
  const BrokerProfileScreen({super.key});

  @override
  State<BrokerProfileScreen> createState() => _BrokerProfileScreenState();
}

class _BrokerProfileScreenState extends State<BrokerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _users = UserService();
  final _auth = AuthService();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _districtInput = TextEditingController();
  final List<String> _districts = [];
  String? _cityValue;
  UserRole _role = UserRole.broker;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final p = await _users.get(uid);
      if (p != null && mounted) {
        _name.text = p.name;
        _phone.text = p.phone;
        _city.text = p.city;
        _cityValue = p.city.isNotEmpty ? p.city : null;
        _districts.addAll(p.districts);
        _role = p.role;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _city, _districtInput]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addDistrict() {
    final d = _districtInput.text.trim();
    if (d.isEmpty) return;
    if (_districts.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الحد الأقصى 5 أحياء')));
      return;
    }
    if (!_districts.contains(d)) setState(() => _districts.add(d));
    _districtInput.clear();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await _users.updateProfile(
        uid: uid,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        city: _city.text.trim(),
        districts: _districts,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ ملفك ✅')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
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
        appBar: AppBar(title: const Text('ملفي التعريفي')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Center(
                          child: Chip(
                            avatar: const Icon(Icons.badge, size: 18),
                            label: Text('الدور: ${_role.arabicLabel}'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _name,
                          decoration:
                              const InputDecoration(labelText: 'الاسم'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              labelText: 'رقم الموبايل (سعودي)',
                              hintText: '05xxxxxxxx'),
                          validator: Validators.saudiPhone,
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text('الاختصاص الجغرافي',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'تستقبل الطلبات والفرص في منطقتك فقط.',
                          style: TextStyle(
                              color: Color(0xFF6B7785), fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _cityValue,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'مدينة الاختصاص'),
                          items: <String>[
                            ...kSaudiCities,
                            if (_cityValue != null &&
                                !kSaudiCities.contains(_cityValue))
                              _cityValue!,
                          ]
                              .map((c) => DropdownMenuItem(
                                  value: c, child: Text(c)))
                              .toList(),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'مطلوب'
                              : null,
                          onChanged: (v) => setState(() {
                            _cityValue = v;
                            _city.text = v ?? '';
                          }),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _districtInput,
                                decoration: const InputDecoration(
                                    labelText: 'أضف حي (حتى 5)'),
                                onSubmitted: (_) => _addDistrict(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _addDistrict,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _districts
                              .map((d) => Chip(
                                    label: Text(d),
                                    onDeleted: () =>
                                        setState(() => _districts.remove(d)),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.save),
                          label: const Text('حفظ'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
