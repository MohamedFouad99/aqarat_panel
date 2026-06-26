import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/property_request.dart';

/// إدارة طلبات العقارات (السوق العكسي).
class RequestService {
  RequestService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('requests');

  Future<void> create(PropertyRequest request) => _col.add(request.toMap());

  /// كل الطلبات المفتوحة — للوسطاء.
  Stream<List<PropertyRequest>> watchOpenRequests() {
    return _col.where('status', isEqualTo: 'open').snapshots().map((snap) {
      final list = snap.docs.map(PropertyRequest.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  Future<void> close(String id) =>
      _col.doc(id).update({'status': 'closed'});
}
