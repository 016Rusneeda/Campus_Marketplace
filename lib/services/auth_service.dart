import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapErrorMessage(e.code));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapErrorMessage(e.code));
    }
  }

  Future<void> signOut() async => _auth.signOut();

  // --- ส่วนที่เพิ่มเข้ามาใหม่สำหรับ Google Sign-In ---
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleReady = false;

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await _googleSignIn.initialize();
    _googleReady = true;
  }

  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();
      final googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return; 

      final idToken = googleUser.authentication.idToken;
      final authorization = await googleUser.authorizationClient?.authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );

      await _auth.signInWithCredential(credential);
      
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapErrorMessage(e.code));
    } catch (e) {
      throw Exception('Google Error: $e');
    }
  }
  // ---------------------------------------------

  String _mapErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'อีเมลนี้ถูกใช้สมัครสมาชิกไปแล้ว กรุณาใช้อีเมลอื่น';
      case 'weak-password': return 'รหัสผ่านสั้นเกินไป ต้องมีอย่างน้อย 6 ตัวอักษร';
      case 'invalid-email': return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      default: return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง ($code)';
    }
  }
}