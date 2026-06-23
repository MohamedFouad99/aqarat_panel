import 'package:cloud_firestore/cloud_firestore.dart';

/// ملف تعريفي للمعلن في Firestore (users/{uid}).
class UserProfile {
  final String uid;
  final String name;
  final String phone;
  final String email;

  UserProfile(
      {required this.uid,
      required this.name,
      required this.phone,
      required this.email});

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      name: m['name'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      email: m['email'] as String? ?? '',
    );
  }
}

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<UserProfile?> get(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Future<void> createOrUpdate({
    required String uid,
    required String name,
    required String phone,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
