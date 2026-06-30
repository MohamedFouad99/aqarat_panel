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

  /// استلام الطلب (ذرّي): أول وسيط يستلم بس — الباقي ميقدروش.
  /// بترجّع true لو نجح، false لو حد سبقه.
  Future<bool> claim(String id, String uid) async {
    return _db.runTransaction<bool>((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);
      final status = (snap.data()?['status'] as String?) ?? 'open';
      if (status != 'open') return false; // حد سبقه أو مقفول
      tx.update(ref, {
        'status': 'claimed',
        'claimedBy': uid,
        'claimedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  /// الطلبات اللي استلمها وسيط معيّن — "طلباتي".
  Stream<List<PropertyRequest>> watchClaimedBy(String uid) {
    return _col.where('claimedBy', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(PropertyRequest.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }
}

