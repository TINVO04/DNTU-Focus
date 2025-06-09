// auth_state.dart
part of 'auth_cubit.dart'; // Đảm bảo file auth_cubit.dart tồn tại cùng cấp thư mục

@immutable
abstract class AuthState {}

// Trạng thái khởi tạo, khi ứng dụng mới bắt đầu hoặc chưa xác định được trạng thái auth.
class AuthInitial extends AuthState {}

// Trạng thái đang xử lý (ví dụ: đang đăng nhập, đăng xuất, kiểm tra đồng bộ).
class AuthLoading extends AuthState {
  final String? message; // Có thể dùng để hiển thị thông báo cụ thể, ví dụ "Đang đồng bộ..."
  AuthLoading({this.message});
}

// Trạng thái người dùng đã được xác thực thành công.
class AuthAuthenticated extends AuthState {
  final User user; // Thông tin người dùng từ Firebase
  AuthAuthenticated(this.user);
}

// Trạng thái người dùng chưa được xác thực hoặc đã đăng xuất.
class AuthUnauthenticated extends AuthState {}

// Trạng thái mới: Yêu cầu người dùng đồng bộ dữ liệu trước khi đăng xuất.
// UI sẽ lắng nghe trạng thái này để hiển thị dialog lựa chọn.
class AuthSyncRequiredBeforeLogout extends AuthState {}

// Trạng thái có lỗi xảy ra trong quá trình xác thực hoặc xử lý liên quan.
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}