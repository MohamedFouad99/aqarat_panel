import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.onSwitchToLogin});

  final VoidCallback onSwitchToLogin;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  final _users = UserService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = await _auth.signUp(_email.text, _password.text);
      // نخزّن بيانات المعلن في users/{uid}
      await _users.createOrUpdate(
        uid: uid,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
      );
      // الـ AuthGate هينقل تلقائياً للوحة بعد نجاح التسجيل.
    } catch (e) {
      setState(() => _error = AuthService.arabicError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_alt_1, size: 52),
                        const SizedBox(height: 8),
                        Text('تسجيل معلن جديد',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'الاسم بالكامل',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 3)
                                  ? 'أدخل اسماً صحيحاً'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الموبايل',
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '01xxxxxxxxx',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 10)
                                  ? 'أدخل رقم موبايل صحيح'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'الإيميل',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) =>
                              (v == null || !v.contains('@'))
                                  ? 'أدخل إيميل صحيح'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'كلمة المرور 6 أحرف على الأقل'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('إنشاء الحساب'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: widget.onSwitchToLogin,
                          child: const Text('عندك حساب بالفعل؟ تسجيل دخول'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
