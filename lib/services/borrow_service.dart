import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/borrow_request.dart';

/// إدارة طلبات استعارة العروض بين الوسطاء.
class BorrowService {
  BorrowService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('borrow_requests');

  Future<void> create(BorrowRequest b) => _col.add(b.toMap());

  /// الطلبات الواردة لصاحب العرض.
  Stream<List<BorrowRequest>> watchIncoming(String uid) {
    return _col.where('toBrokerId', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(BorrowRequest.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  /// الطلبات الصادرة من الوسيط الطالب.
  Stream<List<BorrowRequest>> watchOutgoing(String uid) {
    return _col.where('fromBrokerId', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(BorrowRequest.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  Future<void> accept(String id) =>
      _col.doc(id).update({'status': 'accepted'});
  Future<void> reject(String id) =>
      _col.doc(id).update({'status': 'rejected'});
}
