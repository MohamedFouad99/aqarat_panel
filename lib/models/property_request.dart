import 'package:cloud_firestore/cloud_firestore.dart';

import 'property.dart';

/// طلب عقار من عميل (سوق عكسي): العميل بيكتب اللي بيدوّر عليه،
/// والوسطاء بيشوفوا الطلب ويتواصلوا معاه.
class PropertyRequest {
  final String id;
  final PropertyType? type;
  final ListingType? listingType;
  final String city;
  final String district;
  final num? minPrice;
  final num? maxPrice;
  final int? bedrooms;
  final String notes;
  final String name;
  final String phone;
  final String status; // open | claimed | closed
  final String? claimedBy; // uid الوسيط اللي استلم الطلب
  final String? targetBrokerId; // طلب خاص موجّه لوسيط معيّن
  final DateTime? createdAt;

  PropertyRequest({
    required this.id,
    this.type,
    this.listingType,
    required this.city,
    this.district = '',
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.notes = '',
    required this.name,
    required this.phone,
    this.status = 'open',
    this.claimedBy,
    this.targetBrokerId,
    this.createdAt,
  });

  factory PropertyRequest.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return PropertyRequest(
      id: doc.id,
      type: m['type'] != null ? PropertyType.fromString(m['type']) : null,
      listingType: m['listingType'] != null
          ? ListingType.fromString(m['listingType'])
          : null,
      city: m['city'] as String? ?? '',
      district: m['district'] as String? ?? '',
      minPrice: m['minPrice'] as num?,
      maxPrice: m['maxPrice'] as num?,
      bedrooms: (m['bedrooms'] as num?)?.toInt(),
      notes: m['notes'] as String? ?? '',
      name: m['name'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      status: m['status'] as String? ?? 'open',
      claimedBy: m['claimedBy'] as String?,
      targetBrokerId: m['targetBrokerId'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type?.name,
        'listingType': listingType?.name,
        'city': city,
        'district': district,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'bedrooms': bedrooms,
        'notes': notes,
        'name': name,
        'phone': phone,
        'status': status,
        if (claimedBy != null) 'claimedBy': claimedBy,
        if (targetBrokerId != null) 'targetBrokerId': targetBrokerId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
