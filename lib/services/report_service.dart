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
}
