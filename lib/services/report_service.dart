import 'package:cloud_firestore/cloud_firestore.dart';

/// إرسال بلاغ عن إعلان (نصب/بيانات غير صحيحة... إلخ).
/// البلاغات بتتخزن في collection اسمه reports ويراجعها الأدمن.
class ReportService {
  ReportService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> submit({
    required String propertyId,
    required String propertyTitle,
    required String reason,
    String? note,
  }) async {
    await _db.collection('reports').add({
      'propertyId': propertyId,
      'propertyTitle': propertyTitle,
      'reason': reason,
      'note': note ?? '',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// البلاغات المفتوحة — للوحة الأدمن.
  Stream<List<ReportItem>> watchOpen() {
    return _db
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((s) => s.docs.map(ReportItem.fromDoc).toList());
  }

  Future<void> resolve(String id) =>
      _db.collection('reports').doc(id).update({'status': 'resolved'});
}

/// بلاغ كما يظهر للأدمن.
class ReportItem {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String reason;
  final String note;

  ReportItem({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.reason,
    required this.note,
  });

  factory ReportItem.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return ReportItem(
      id: doc.id,
      propertyId: m['propertyId'] as String? ?? '',
      propertyTitle: m['propertyTitle'] as String? ?? '',
      reason: m['reason'] as String? ?? '',
      note: m['note'] as String? ?? '',
    );
  }
}
