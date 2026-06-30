import 'package:cloud_firestore/cloud_firestore.dart';

/// أدوار المستخدم في المنصة.
enum UserRole {
  client, // عميل
  broker, // وسيط
  owner, // مالك عقار
  admin; // مدير النظام

  String get arabicLabel {
    switch (this) {
      case UserRole.client:
        return 'عميل';
      case UserRole.broker:
        return 'وسيط';
      case UserRole.owner:
        return 'مالك عقار';
      case UserRole.admin:
        return 'مدير النظام';
    }
  }

  static UserRole fromString(String? v) => UserRole.values.firstWhere(
        (e) => e.name == v,
        orElse: () => UserRole.broker,
      );
}

/// ملف تعريفي للمستخدم في Firestore (users/{uid}).
class UserProfile {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final bool verified; // معلن موثّق (يضبطه الأدمن)
  final UserRole role;
  // الاختصاص الجغرافي للوسيط
  final String city;
  final List<String> districts; // حتى 5 أحياء

  UserProfile({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    this.verified = false,
    this.role = UserRole.broker,
    this.city = '',
    this.districts = const [],
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      name: m['name'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      email: m['email'] as String? ?? '',
      verified: m['verified'] as bool? ?? false,
      role: UserRole.fromString(m['role'] as String?),
      city: m['city'] as String? ?? '',
      districts: (m['districts'] as List<dynamic>?)?.cast<String>() ?? const [],
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

  Stream<UserProfile?> watch(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserProfile.fromDoc(doc) : null);

  /// كل الوسطاء — لنظام التوزيع.
  Future<List<UserProfile>> allBrokers() async {
    final snap = await _db
        .collection('users')
        .where('role', whereIn: ['broker', 'owner']).get();
    return snap.docs.map(UserProfile.fromDoc).toList();
  }

  Future<void> createOrUpdate({
    required String uid,
    required String name,
    required String phone,
    required String email,
    UserRole? role,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      if (role != null) 'role': role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// تحديث بيانات الوسيط واختصاصه الجغرافي.
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String city,
    required List<String> districts,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      'city': city,
      'districts': districts,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
