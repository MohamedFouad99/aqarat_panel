import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/deal.dart';

/// إدارة سجل الصفقات العقارية.
class DealService {
  DealService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('deals');

  Future<void> create(Deal d) => _col.add(d.toMap());

  Stream<List<Deal>> watchByBroker(String uid) {
    return _col.where('brokerId', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(Deal.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  /// صفقات بانتظار تأكيد الطرف الآخر (الوسيط صاحب العرض المُستعار).
  Stream<List<Deal>> watchPendingForCounterparty(String uid) {
    return _col
        .where('counterpartyId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs.map(Deal.fromDoc).toList());
  }

  Future<void> confirm(String id) =>
      _col.doc(id).update({'status': 'verified'});

  Future<void> reject(String id) =>
      _col.doc(id).update({'status': 'rejected'});

  /// عدد الصفقات الموثّقة لوسيط (للشارة في الملف العام).
  Future<int> countByBroker(String uid) async {
    final snap = await _col
        .where('brokerId', isEqualTo: uid)
        .where('status', isEqualTo: 'verified')
        .count()
        .get();
    return snap.count ?? 0;
  }
}
