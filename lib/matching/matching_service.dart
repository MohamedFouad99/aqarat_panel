import '../models/property.dart';
import '../models/property_request.dart';
import 'matching_rules.dart';

/// نتيجة مطابقة بين طلب وعرض.
class MatchResult {
  final PropertyRequest request;
  final Property offer;
  final double score; // 0..100

  MatchResult({required this.request, required this.offer, required this.score});
}

/// محرك المطابقة الذكية (نسخة client-side للتجربة — تنتقل للسيرفر عند النشر).
class MatchingService {
  static bool _contains(String haystack, String needle) {
    final h = haystack.trim().toLowerCase();
    final n = needle.trim().toLowerCase();
    if (n.isEmpty) return true;
    return h.contains(n) || n.contains(h);
  }

  /// نسبة المطابقة بين طلب وعرض (0..100) — نطابق فقط العناصر اللي حدّدها الطلب.
  static double score(PropertyRequest r, Property o) {
    int total = 0;
    int got = 0;

    if (r.listingType != null) {
      total += MatchingRules.wListingType;
      if (o.listingType == r.listingType) got += MatchingRules.wListingType;
    }
    if (r.type != null) {
      total += MatchingRules.wType;
      if (o.type == r.type) got += MatchingRules.wType;
    }
    if (r.city.trim().isNotEmpty) {
      total += MatchingRules.wCity;
      if (_contains(o.city, r.city)) got += MatchingRules.wCity;
    }
    if (r.district.trim().isNotEmpty) {
      total += MatchingRules.wDistrict;
      if (_contains(o.district, r.district)) got += MatchingRules.wDistrict;
    }
    if (r.minPrice != null || r.maxPrice != null) {
      total += MatchingRules.wPrice;
      final okMin = r.minPrice == null || o.price >= r.minPrice!;
      final okMax = r.maxPrice == null || o.price <= r.maxPrice!;
      if (okMin && okMax) got += MatchingRules.wPrice;
    }
    if (r.bedrooms != null && r.bedrooms! > 0) {
      total += MatchingRules.wBedrooms;
      if (o.bedrooms >= r.bedrooms!) got += MatchingRules.wBedrooms;
    }

    if (total == 0) return 0;
    return got / total * 100;
  }

  /// أفضل عرض من قائمة عروض يطابق طلباً معيناً.
  static MatchResult? bestOfferForRequest(
      PropertyRequest r, List<Property> offers) {
    MatchResult? best;
    for (final o in offers) {
      if (o.status != PropertyStatus.available) continue;
      final s = score(r, o);
      if (s < MatchingRules.minScore) continue;
      if (best == null || s > best.score) {
        best = MatchResult(request: r, offer: o, score: s);
      }
    }
    return best;
  }

  /// كل العروض المطابقة لطلب، مرتّبة تنازلياً.
  static List<MatchResult> offersForRequest(
      PropertyRequest r, List<Property> offers) {
    final results = <MatchResult>[];
    for (final o in offers) {
      if (o.status != PropertyStatus.available) continue;
      final s = score(r, o);
      if (s >= MatchingRules.minScore) {
        results.add(MatchResult(request: r, offer: o, score: s));
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// كل الطلبات المطابقة لعرض، مرتّبة تنازلياً.
  static List<MatchResult> requestsForOffer(
      Property o, List<PropertyRequest> requests) {
    final results = <MatchResult>[];
    for (final r in requests) {
      final s = score(r, o);
      if (s >= MatchingRules.minScore) {
        results.add(MatchResult(request: r, offer: o, score: s));
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}
