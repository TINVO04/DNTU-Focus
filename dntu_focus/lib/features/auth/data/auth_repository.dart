// auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Đảm bảo đường dẫn import FirebaseService là chính xác
import '../../../core/services/firebase_service.dart'; // Hoặc đường dẫn đúng tới file firebase_service.dart

class AuthRepository {
  final FirebaseService _firebaseService; // Không khởi tạo ở đây nữa

  // SỬA: Thêm constructor nhận FirebaseService
  AuthRepository(this._firebaseService);

  Future<void> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Đăng nhập bằng Google bị hủy');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    // Sử dụng _firebaseService đã được truyền vào (nếu FirebaseService có hàm signInWithCredential)
    // Hiện tại, FirebaseAuth.instance được dùng trực tiếp ở đây, điều này vẫn ổn.
    // Nếu muốn tập trung mọi thứ qua _firebaseService, bạn cần thêm các hàm wrapper trong FirebaseService.
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _firebaseService.signInWithEmail(email, password);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Không tìm thấy người dùng với email này');
        case 'wrong-password':
          throw Exception('Mật khẩu không đúng');
        case 'invalid-email':
          throw Exception('Email không hợp lệ');
        default:
          throw Exception('Lỗi đăng nhập: ${e.message}');
      }
    } catch (e) {
      throw Exception('Lỗi đăng nhập bằng email: $e');
    }
  }

  // THÊM: Hàm signOut (sẽ gọi hàm signOut của FirebaseService)
  Future<void> signOut() async {
    await _firebaseService.signOut();
  }

  // THÊM: Hàm signUpWithEmail (nếu bạn cần)
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _firebaseService.signUpWithEmail(email, password);
    } on FirebaseAuthException catch (e) {
      // Xử lý các lỗi cụ thể của Firebase Auth khi đăng ký (ví dụ: email-already-in-use)
      if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Địa chỉ email đã được sử dụng bởi tài khoản khác.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Địa chỉ email không hợp lệ.');
      }
      throw Exception('Lỗi đăng ký: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi đăng ký bằng email: $e');
    }
  }

  // THÊM: Hàm lấy người dùng hiện tại (nếu cần)
  User? get currentUser => _firebaseService.currentUser;

  // THÊM: Stream theo dõi trạng thái xác thực (nếu cần)
  Stream<User?> get authStateChanges => _firebaseService.authStateChanges;

}