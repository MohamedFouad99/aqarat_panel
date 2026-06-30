import 'package:cloud_firestore/cloud_firestore.dart';

/// صفقة موثّقة في سجل الصفقات العقارية.
class Deal {
  final String id;
  final String brokerId;
  final String clientName;
  final String offerTitle;
  final String type; // sale | rent | ...
  final num value; // قيمة الصفقة
  final num commission; // العمولة
  final bool viaBorrow; // تمت عبر عرض مُستعار؟
  final String? counterpartyId; // الوسيط الآخر اللي لازم يأكّد الصفقة
  final String? offerId; // العرض المرتبط بالصفقة (للتعليم كـ"تم")
  final String status; // verified | pending | rejected
  final DateTime? createdAt;

  Deal({
    required this.id,
    required this.brokerId,
    required this.clientName,
    required this.offerTitle,
    required this.type,
    required this.value,
    this.commission = 0,
    this.viaBorrow = false,
    this.counterpartyId,
    this.offerId,
    this.status = 'verified',
    this.createdAt,
  });

  factory Deal.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return Deal(
      id: doc.id,
      brokerId: m['brokerId'] as String? ?? '',
      clientName: m['clientName'] as String? ?? '',
      offerTitle: m['offerTitle'] as String? ?? '',
      type: m['type'] as String? ?? 'sale',
      value: m['value'] as num? ?? 0,
      commission: m['commission'] as num? ?? 0,
      viaBorrow: m['viaBorrow'] as bool? ?? false,
      counterpartyId: m['counterpartyId'] as String?,
      offerId: m['offerId'] as String?,
      status: m['status'] as String? ?? 'verified',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'brokerId': brokerId,
        'clientName': clientName,
        'offerTitle': offerTitle,
        'type': type,
        'value': value,
        'commission': commission,
        'viaBorrow': viaBorrow,
        if (counterpartyId != null) 'counterpartyId': counterpartyId,
        if (offerId != null) 'offerId': offerId,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
