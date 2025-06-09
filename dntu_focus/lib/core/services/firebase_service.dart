import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream để theo dõi thay đổi trạng thái xác thực
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập bằng Email và Mật khẩu
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) { // Bắt lỗi cụ thể của Firebase Auth
      if (e.code == 'user-not-found') {
        throw Exception('Không tìm thấy người dùng với email này.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Mật khẩu không đúng.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Địa chỉ email không hợp lệ.');
      } else {
        throw Exception('Đăng nhập thất bại: ${e.message}');
      }
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  // Đăng ký bằng Email và Mật khẩu
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) { // Bắt lỗi cụ thể của Firebase Auth
      if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Địa chỉ email đã được sử dụng bởi tài khoản khác.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Địa chỉ email không hợp lệ.');
      } else {
        throw Exception('Đăng ký thất bại: ${e.message}');
      }
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // Hiếm khi signOut gây lỗi, nhưng vẫn nên có try-catch
      print('Lỗi khi đăng xuất: $e');
      throw Exception('Đăng xuất thất bại: $e');
    }
  }

  // Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Không tìm thấy người dùng với email này để gửi yêu cầu đặt lại mật khẩu.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Địa chỉ email không hợp lệ.');
      }
      throw Exception('Gửi email đặt lại mật khẩu thất bại: ${e.message}');
    } catch (e) {
      throw Exception('Gửi email đặt lại mật khẩu thất bại: $e');
    }
  }

  // Lấy collection tasks của một người dùng cụ thể
  // Hàm này có thể dùng để admin truy cập (nếu có quyền) hoặc chính người dùng truy cập dữ liệu của họ.
  // Việc kiểm tra quyền truy cập cụ thể (ví dụ: user hiện tại có phải là userId được truyền vào không)
  // nên được thực hiện ở tầng gọi hàm này nếu logic đó là cần thiết cho trường hợp sử dụng cụ thể.
  // Hoặc, Firestore rules sẽ là nơi chính để bảo vệ dữ liệu.
  CollectionReference getUserSubCollection(String userId, String subCollectionName) {
    // if (userId.isEmpty || subCollectionName.isEmpty) { // Kiểm tra đầu vào nếu cần
    //   throw ArgumentError('userId và subCollectionName không được rỗng.');
    // }
    return _firestore.collection('users').doc(userId).collection(subCollectionName);
  }

  // Hàm cũ getUserTasks, bạn có thể giữ lại nếu chỉ dùng cho tasks
  // hoặc thay thế bằng cách gọi getUserSubCollection(userId, 'tasks')
  CollectionReference getUserTasks(String userId) {
    // Bỏ kiểm tra _auth.currentUser!.uid != userId ở đây
    // vì hàm này chỉ trả về một tham chiếu CollectionReference.
    // Việc kiểm soát quyền truy cập dữ liệu nên được Firebase Rules xử lý
    // hoặc ở tầng logic nghiệp vụ cao hơn nếu cần thiết.
    // if (_auth.currentUser == null) {
    //   throw Exception('Người dùng chưa đăng nhập');
    // }
    return _firestore.collection('users').doc(userId).collection('tasks');
  }
}