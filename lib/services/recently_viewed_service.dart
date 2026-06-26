import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "آخر ما شاهدت" — قائمة معرّفات آخر العقارات اللي اتفتحت، محفوظة بالمتصفح.
class RecentlyViewedService {
  RecentlyViewedService._();
  static final RecentlyViewedService instance = RecentlyViewedService._();

  static const _key = 'recently_viewed_ids';
  static const _max = 10;

  final ValueNotifier<List<String>> ids = ValueNotifier<List<String>>([]);
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    ids.value = _prefs?.getStringList(_key) ?? const [];
  }

  void add(String id) {
    final next = [id, ...ids.value.where((e) => e != id)];
    if (next.length > _max) next.removeRange(_max, next.length);
    ids.value = next;
    _prefs?.setStringList(_key, next);
  }
}
