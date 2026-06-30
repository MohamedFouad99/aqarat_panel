/// قواعد وأوزان المطابقة — وثيقة مستقلة قابلة للتعديل بدون تغيير باقي النظام.
/// المجموع = 100. لاحقاً ممكن تتسجّل في Firestore عشان الأدمن يعدّلها.
class MatchingRules {
  static const int wListingType = 15; // نوع العملية (بيع/إيجار)
  static const int wType = 15; // نوع العقار
  static const int wCity = 25; // المدينة
  static const int wDistrict = 15; // الحي
  static const int wPrice = 20; // السعر/الميزانية
  static const int wBedrooms = 10; // غرف النوم

  /// الحد الأدنى لنسبة المطابقة لإظهار النتيجة.
  static const double minScore = 60;
}
