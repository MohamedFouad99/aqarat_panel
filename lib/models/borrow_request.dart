import 'package:cloud_firestore/cloud_firestore.dart';

/// طلب استعارة عرض: وسيط استلم طلب عميل يطلب من وسيط آخر استعارة عرضه المطابق.
class BorrowRequest {
  final String id;
  final String offerId;
  final String offerTitle;
  final num offerPrice;
  final String requestId;
  final String requestName; // اسم العميل صاحب الطلب
  final String fromBrokerId; // الوسيط الطالب (المستلم للطلب)
  final String toBrokerId; // صاحب العرض
  final double score; // نسبة المطابقة
  final String status; // pending | accepted | rejected
  // borrow = الوسيط المستلم يطلب عرض غيره | cooperation = صاحب العرض يعرض عرضه
  final String kind;
  final DateTime? createdAt;

  BorrowRequest({
    required this.id,
    required this.offerId,
    required this.offerTitle,
    required this.offerPrice,
    required this.requestId,
    required this.requestName,
    required this.fromBrokerId,
    required this.toBrokerId,
    required this.score,
    this.status = 'pending',
    this.kind = 'borrow',
    this.createdAt,
  });

  factory BorrowRequest.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return BorrowRequest(
      id: doc.id,
      offerId: m['offerId'] as String? ?? '',
      offerTitle: m['offerTitle'] as String? ?? '',
      offerPrice: m['offerPrice'] as num? ?? 0,
      requestId: m['requestId'] as String? ?? '',
      requestName: m['requestName'] as String? ?? '',
      fromBrokerId: m['fromBrokerId'] as String? ?? '',
      toBrokerId: m['toBrokerId'] as String? ?? '',
      score: (m['score'] as num?)?.toDouble() ?? 0,
      status: m['status'] as String? ?? 'pending',
      kind: m['kind'] as String? ?? 'borrow',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'offerId': offerId,
        'offerTitle': offerTitle,
        'offerPrice': offerPrice,
        'requestId': requestId,
        'requestName': requestName,
        'fromBrokerId': fromBrokerId,
        'toBrokerId': toBrokerId,
        'score': score,
        'status': status,
        'kind': kind,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
