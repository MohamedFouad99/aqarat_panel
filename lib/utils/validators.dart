/// تحققات مشتركة عبر الموقع.
class Validators {
  /// رقم جوال سعودي: 05xxxxxxxx أو +9665xxxxxxxx.
  static String? saudiPhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final ok = RegExp(r'^05\d{8}$').hasMatch(digits) ||
        RegExp(r'^9665\d{8}$').hasMatch(digits);
    return ok ? null : 'أدخل رقم سعودي صحيح (مثال: 05xxxxxxxx)';
  }
}
