import 'package:cloud_firestore/cloud_firestore.dart';

/// إشعار داخل التطبيق لمستخدم معيّن.
class AppNotification {
  final String id;
  final String toUid;
  final String title;
  final String body;
  final String type; // borrow_request | borrow_accepted | borrow_rejected | deal | info
  final bool read;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.toUid,
    required this.title,
    required this.body,
    this.type = 'info',
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: doc.id,
      toUid: m['toUid'] as String? ?? '',
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      type: m['type'] as String? ?? 'info',
      read: m['read'] as bool? ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Future<void> send({
    required String toUid,
    required String title,
    required String body,
    String type = 'info',
  }) async {
    if (toUid.isEmpty) return;
    await _col.add({
      'toUid': toUid,
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<AppNotification>> watchFor(String uid) {
    return _col.where('toUid', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(AppNotification.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0))
            .compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  Future<void> markRead(String id) => _col.doc(id).update({'read': true});
}
