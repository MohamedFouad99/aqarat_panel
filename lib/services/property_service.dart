import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/property.dart';

/// كل التعامل مع العقارات في Firestore + رفع الصور على Storage.
/// الـ Web Panel بيستخدم الكلاس ده، والـ WhatsApp Bot بعدين هيقرأ من نفس
/// الـ collection (properties).
class PropertyService {
  PropertyService({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('properties');

  /// كل العقارات (الأحدث أولاً) — للعرض اللحظي في القائمة.
  Stream<List<Property>> watchProperties() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Property.fromDoc).toList());
  }

  Future<Property?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Property.fromDoc(doc);
  }

  /// إضافة عقار جديد، بترجع الـ id المتولّد.
  Future<String> create(Property property) async {
    final ref = await _col.add(property.toMap(isNew: true));
    return ref.id;
  }

  Future<void> update(Property property) async {
    await _col.doc(property.id).update(property.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  /// رفع صورة على Storage وإرجاع رابطها (يشتغل على الويب بالـ bytes).
  Future<String> uploadImage(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final ref = _storage.ref('properties/$fileName');
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }
}
