import 'package:cloud_firestore/cloud_firestore.dart';

/// نوع العقار
enum PropertyType {
  apartment, // شقة
  villa, // فيلا
  land, // أرض
  shop, // محل
  office, // مكتب
  building; // مبنى

  String get arabicLabel {
    switch (this) {
      case PropertyType.apartment:
        return 'شقة';
      case PropertyType.villa:
        return 'فيلا';
      case PropertyType.land:
        return 'أرض';
      case PropertyType.shop:
        return 'محل';
      case PropertyType.office:
        return 'مكتب';
      case PropertyType.building:
        return 'مبنى';
    }
  }

  static PropertyType fromString(String? value) {
    return PropertyType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PropertyType.apartment,
    );
  }
}

/// نوع العرض: بيع أو إيجار
enum ListingType {
  sale, // بيع
  rent; // إيجار

  String get arabicLabel => this == ListingType.sale ? 'بيع' : 'إيجار';

  static ListingType fromString(String? value) {
    return ListingType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ListingType.sale,
    );
  }
}

/// حالة العقار
enum PropertyStatus {
  available, // متاح
  reserved, // محجوز
  sold; // مباع/مؤجَّر

  String get arabicLabel {
    switch (this) {
      case PropertyStatus.available:
        return 'متاح';
      case PropertyStatus.reserved:
        return 'محجوز';
      case PropertyStatus.sold:
        return 'تم';
    }
  }

  static PropertyStatus fromString(String? value) {
    return PropertyStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PropertyStatus.available,
    );
  }
}

/// نموذج العقار — هو الأساس اللي بيشترك فيه الـ Web Panel والـ WhatsApp Bot
class Property {
  final String id;
  final String title;
  final PropertyType type;
  final ListingType listingType;
  final num price;
  final num area; // المساحة بالمتر المربع
  final int bedrooms;
  final int bathrooms;
  final String city;
  final String district;
  final String description;
  final List<String> images;
  final PropertyStatus status;
  final bool featured;
  // وسائط إضافية (اختيارية)
  final String? videoUrl; // رابط فيديو (YouTube مثلاً)
  final double? latitude;
  final double? longitude;
  // بيانات المعلن
  final String? advertiserName;
  final String? advertiserPhone;
  /// مالك الإعلان — uid في Firebase Auth.
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Property({
    required this.id,
    required this.title,
    required this.type,
    required this.listingType,
    required this.price,
    required this.area,
    required this.bedrooms,
    required this.bathrooms,
    required this.city,
    required this.district,
    required this.description,
    required this.images,
    required this.status,
    this.featured = false,
    this.videoUrl,
    this.latitude,
    this.longitude,
    this.advertiserName,
    this.advertiserPhone,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  /// قراءة عقار من Firestore document
  factory Property.fromMap(String id, Map<String, dynamic> map) {
    return Property(
      id: id,
      title: map['title'] as String? ?? '',
      type: PropertyType.fromString(map['type'] as String?),
      listingType: ListingType.fromString(map['listingType'] as String?),
      price: map['price'] as num? ?? 0,
      area: map['area'] as num? ?? 0,
      bedrooms: (map['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (map['bathrooms'] as num?)?.toInt() ?? 0,
      city: map['city'] as String? ?? '',
      district: map['district'] as String? ?? '',
      description: map['description'] as String? ?? '',
      images: (map['images'] as List<dynamic>?)?.cast<String>() ?? const [],
      status: PropertyStatus.fromString(map['status'] as String?),
      featured: map['featured'] as bool? ?? false,
      videoUrl: map['videoUrl'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      advertiserName: map['advertiserName'] as String?,
      advertiserPhone: map['advertiserPhone'] as String?,
      ownerId: map['ownerId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Property.fromDoc(DocumentSnapshot doc) {
    return Property.fromMap(doc.id, doc.data() as Map<String, dynamic>? ?? {});
  }

  /// تحويل العقار لـ Map قبل الحفظ في Firestore.
  /// التواريخ بتتسجَّل من السيرفر تلقائياً.
  Map<String, dynamic> toMap({bool isNew = false}) {
    return {
      'title': title,
      'type': type.name,
      'listingType': listingType.name,
      'price': price,
      'area': area,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'city': city,
      'district': district,
      'description': description,
      'images': images,
      'status': status.name,
      'featured': featured,
      'videoUrl': videoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'advertiserName': advertiserName,
      'advertiserPhone': advertiserPhone,
      if (ownerId != null) 'ownerId': ownerId,
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Property copyWith({
    String? title,
    PropertyType? type,
    ListingType? listingType,
    num? price,
    num? area,
    int? bedrooms,
    int? bathrooms,
    String? city,
    String? district,
    String? description,
    List<String>? images,
    PropertyStatus? status,
    bool? featured,
    String? videoUrl,
    double? latitude,
    double? longitude,
    String? advertiserName,
    String? advertiserPhone,
    String? ownerId,
  }) {
    return Property(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      listingType: listingType ?? this.listingType,
      price: price ?? this.price,
      area: area ?? this.area,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      city: city ?? this.city,
      district: district ?? this.district,
      description: description ?? this.description,
      images: images ?? this.images,
      status: status ?? this.status,
      featured: featured ?? this.featured,
      videoUrl: videoUrl ?? this.videoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      advertiserName: advertiserName ?? this.advertiserName,
      advertiserPhone: advertiserPhone ?? this.advertiserPhone,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
