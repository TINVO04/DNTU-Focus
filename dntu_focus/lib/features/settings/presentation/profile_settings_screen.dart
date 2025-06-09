import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart'; // THÊM IMPORT BLOC
import '../../../features/auth/domain/auth_cubit.dart'; // THÊM IMPORT AuthCubit (đảm bảo đường dẫn đúng)
import '../../../routes/app_routes.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Vẫn có thể giữ lại để lấy thông tin user ban đầu
  late TextEditingController _usernameController;
  String? _photoUrl;
  bool _isEditingUsername = false;
  bool _isGoogleAccount = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _usernameController = TextEditingController(text: user?.displayName ?? 'User');
    _photoUrl = user?.photoURL;
    _isGoogleAccount = user?.providerData.any((provider) => provider.providerId == 'google.com') ?? false;
  }

  // Các hàm _updateUsername, _changePassword, _pickAvatar giữ nguyên như của bạn
  // Chúng không liên quan trực tiếp đến AuthCubit ở đây, mà là các thao tác Firebase cụ thể.
  Future<void> _updateUsername() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(_usernameController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditingUsername = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating username: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        await _auth.sendPasswordResetEmail(email: user.email!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending password reset email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); // Giảm chất lượng ảnh một chút

    if (pickedFile != null) {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_avatars')
            .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg'); // Thêm timestamp để tránh cache

        final file = File(pickedFile.path);
        // Hiển thị loading indicator nếu cần
        // setState(() => _isUploadingAvatar = true);

        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();
        await user.updatePhotoURL(downloadUrl);

        // setState(() => _isUploadingAvatar = false);
        if (mounted) {
          setState(() {
            _photoUrl = downloadUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        // setState(() => _isUploadingAvatar = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating avatar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }


  // Bỏ hàm _signOut() cục bộ vì sẽ dùng AuthCubit
  // Future<void> _signOut() async { ... }

  @override
  void dispose() { // Thêm dispose cho controller
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe AuthCubit để điều hướng khi đăng xuất thành công
    // hoặc xử lý dialog nhắc nhở đồng bộ.
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Đảm bảo chỉ điều hướng một lần và khi widget còn mounted
          if (mounted && ModalRoute.of(context)?.settings.name != AppRoutes.login) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
          }
        } else if (state is AuthSyncRequiredBeforeLogout) {
          // Hiển thị dialog nhắc nhở đồng bộ
          showDialog(
            context: context,
            barrierDismissible: false, // Người dùng phải chọn một hành động
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('Dữ liệu chưa đồng bộ'),
                content: const Text('Bạn có một số dữ liệu chưa được đồng bộ lên máy chủ. Bạn muốn làm gì?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      // Nếu người dùng hủy, có thể emit lại AuthAuthenticated để UI không bị kẹt ở trạng thái loading (nếu có)
                      // Hoặc đơn giản là không làm gì, chờ người dùng chọn lại hành động đăng xuất.
                      // Để an toàn, nếu AuthCubit đang ở AuthLoading, ta có thể đưa nó về AuthAuthenticated.
                      final authState = context.read<AuthCubit>().state;
                      if (authState is AuthLoading && authState.message == "Đang kiểm tra dữ liệu...") {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser != null) {
                          context.read<AuthCubit>().emit(AuthAuthenticated(currentUser));
                        } else {
                          // Trường hợp hiếm, user null nhưng lại ở bước kiểm tra sync
                          context.read<AuthCubit>().signOutAnyway(); // Hoặc emit AuthUnauthenticated
                        }
                      }
                    },
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.read<AuthCubit>().signOutAnyway(); // Gọi hàm đăng xuất bỏ qua đồng bộ
                    },
                    child: const Text('Vẫn đăng xuất', style: TextStyle(color: Colors.orange)),
                  ),
                  ElevatedButton( // Làm nổi bật nút này
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.read<AuthCubit>().syncDataAndProceedWithSignOut();
                    },
                    child: const Text('Đồng bộ và Đăng xuất'),
                  ),
                ],
              );
            },
          );
        } else if (state is AuthError) { // Bắt các lỗi khác từ AuthCubit trong quá trình đăng xuất
          if (mounted && state.message.contains("Lỗi khi đăng xuất") || state.message.contains("Lỗi đồng bộ")) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty ? NetworkImage(_photoUrl!) : null,
                      backgroundColor: Colors.grey[200],
                      child: (_photoUrl == null || _photoUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.blue),
                        onPressed: _pickAvatar,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: _isEditingUsername
                    ? TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                )
                    : Text('Username: ${_usernameController.text}', style: const TextStyle(fontSize: 16)),
                trailing: IconButton(
                  icon: Icon(_isEditingUsername ? Icons.save : Icons.edit),
                  onPressed: () {
                    if (_isEditingUsername) {
                      _updateUsername();
                    } else {
                      setState(() => _isEditingUsername = true);
                    }
                  },
                ),
              ),
              ListTile(
                title: Text('Account: ${_isGoogleAccount ? "Google" : "Email"}', style: const TextStyle(fontSize: 16)),
              ),
              if (!_isGoogleAccount)
                ListTile(
                  title: const Text('Change Password', style: TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                  onTap: _changePassword,
                ),
              ListTile(
                title: const Text('Sign Out', style: TextStyle(fontSize: 16, color: Colors.red)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                onTap: () {
                  // Hiển thị dialog xác nhận đăng xuất chung
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirm Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              // GỌI PHƯƠNG THỨC signOut CỦA AuthCubit
                              // Tham số forceSignOut: false để kích hoạt kiểm tra đồng bộ
                              context.read<AuthCubit>().signOut(forceSignOut: false);
                            },
                            child: const Text('Yes', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}