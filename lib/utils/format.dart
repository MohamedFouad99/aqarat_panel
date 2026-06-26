import 'package:intl/intl.dart';

final _priceFormat = NumberFormat.decimalPattern('en');

/// تنسيق السعر: 2500000 -> "2,500,000 ريال"
String formatPrice(num value) => '${_priceFormat.format(value)} ريال';

/// سعر مختصر: 2500000 -> "2.5 مليون"
String formatPriceShort(num value) {
  if (value >= 1000000) {
    final m = value / 1000000;
    return '${m % 1 == 0 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)} مليون';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)} ألف';
  }
  return _priceFormat.format(value);
}
