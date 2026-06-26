import 'package:cloud_firestore/cloud_firestore.dart';

/// عدّاد مشاهدات العقار — مخزَّن في collection منفصل (views/{propertyId}).
class ViewsService {
  ViewsService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> increment(String propertyId) async {
    await _db.collection('views').doc(propertyId).set(
      {'count': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  Stream<int> watch(String propertyId) {
    return _db.collection('views').doc(propertyId).snapshots().map(
        (d) => (d.data()?['count'] as num?)?.toInt() ?? 0);
  }

  /// كل عدّادات المشاهدات (id -> count) — للترتيب والإحصائيات.
  Future<Map<String, int>> fetchAll() async {
    final snap = await _db.collection('views').get();
    return {
      for (final d in snap.docs) d.id: (d.data()['count'] as num?)?.toInt() ?? 0
    };
  }
}
