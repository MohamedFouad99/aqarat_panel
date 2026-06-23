import 'package:firebase_auth/firebase_auth.dart';

/// تسجيل الدخول/الخروج لحماية لوحة التحكم.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// بيتغيّر كل ما المستخدم يسجّل دخول أو خروج — بنبني عليه شاشة الدخول.
  Stream<User?> get authState => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// تسجيل معلن جديد — يرجّع الـ uid.
  Future<String> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user!.uid;
  }

  Future<void> signOut() => _auth.signOut();

  /// رسالة خطأ بالعربي حسب نوع المشكلة.
  static String arabicError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'صيغة الإيميل غير صحيحة';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'الإيميل أو كلمة المرور غير صحيحة';
        case 'user-disabled':
          return 'الحساب موقوف';
        case 'too-many-requests':
          return 'محاولات كثيرة، حاول لاحقاً';
        case 'email-already-in-use':
          return 'الإيميل ده مسجَّل بالفعل';
        case 'weak-password':
          return 'كلمة المرور ضعيفة (6 حروف على الأقل)';
        default:
          return 'تعذّر تسجيل الدخول (${error.code})';
      }
    }
    return 'حدث خطأ غير متوقع';
  }
}
