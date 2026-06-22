import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إدارة العقارات المفضّلة — محفوظة محلياً في المتصفح (من غير تسجيل دخول).
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const _key = 'favorite_property_ids';

  /// مجموعة معرّفات العقارات المفضّلة — الواجهة بتسمع عليها وتتحدّث فوراً.
  final ValueNotifier<Set<String>> ids = ValueNotifier<Set<String>>({});

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    ids.value = (_prefs?.getStringList(_key) ?? const []).toSet();
  }

  bool isFavorite(String id) => ids.value.contains(id);

  void toggle(String id) {
    final next = {...ids.value};
    if (!next.add(id)) next.remove(id); // add بترجّع false لو موجود → نشيله
    ids.value = next;
    _prefs?.setStringList(_key, next.toList());
  }
}
