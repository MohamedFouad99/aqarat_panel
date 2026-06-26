import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مقارنة العقارات — قائمة معرّفات (حد أقصى 4) محفوظة بالمتصفح.
class CompareService {
  CompareService._();
  static final CompareService instance = CompareService._();

  static const _key = 'compare_ids';
  static const max = 4;

  final ValueNotifier<List<String>> ids = ValueNotifier<List<String>>([]);
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    ids.value = _prefs?.getStringList(_key) ?? const [];
  }

  bool contains(String id) => ids.value.contains(id);

  /// بترجّع false لو القائمة وصلت الحد الأقصى ومقدرش يضيف.
  bool toggle(String id) {
    final list = [...ids.value];
    if (list.contains(id)) {
      list.remove(id);
    } else {
      if (list.length >= max) return false;
      list.add(id);
    }
    _save(list);
    return true;
  }

  void remove(String id) => _save([...ids.value]..remove(id));
  void clear() => _save([]);

  void _save(List<String> list) {
    ids.value = list;
    _prefs?.setStringList(_key, list);
  }
}
