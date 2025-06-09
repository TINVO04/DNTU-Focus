import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Bỏ import FirebaseService nếu không dùng trực tiếp nữa
// import '../../../core/services/firebase_service.dart';
import '../../../routes/app_routes.dart';
// Bỏ import AuthRepository nếu không dùng trực tiếp nữa
// import '../data/auth_repository.dart';
import '../domain/auth_cubit.dart'; // Vẫn cần AuthCubit và AuthState

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Bỏ _firebaseService nếu không dùng trực tiếp
  // final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // _isLoading và _errorMessage sẽ được quản lý bởi AuthCubit state

  // Bỏ hàm _signInWithEmail cục bộ, logic này sẽ do AuthCubit đảm nhiệm
  /*
  Future<void> _signInWithEmail() async {
    // ...
  }
  */

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // KHÔNG tạo BlocProvider<AuthCubit> ở đây nữa
    // AuthCubit sẽ được cung cấp từ MyApp trong main.dart
    return Scaffold(
      backgroundColor: const Color(0xFFE6F7FA), // Cân nhắc dùng màu từ Theme
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: BlocConsumer<AuthCubit, AuthState>( // Lắng nghe AuthCubit từ context
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  // Đảm bảo Navigator.pushReplacementNamed được gọi sau khi build xong frame hiện tại
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) { // Kiểm tra mounted
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    }
                  });
                } else if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                // Xác định isLoading từ AuthState
                bool isLoading = state is AuthLoading;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00C4FF), Color(0xFFFF69B4)], // Cân nhắc dùng màu từ Theme
                      ).createShader(bounds),
                      child: const Text(
                        'Moji-ToDo',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Màu này sẽ bị ghi đè bởi ShaderMask
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFFE6E6), // Cân nhắc dùng màu từ Theme
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading, // Vô hiệu hóa khi đang loading
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFFE6E6), // Cân nhắc dùng màu từ Theme
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                      enabled: !isLoading, // Vô hiệu hóa khi đang loading
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : () { // Vô hiệu hóa khi đang loading
                          Navigator.pushNamed(context, AppRoutes.forgotPassword);
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Color(0xFF00C4FF)), // Cân nhắc dùng màu từ Theme
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Không cần hiển thị _errorMessage ở đây nữa vì BlocConsumer đã xử lý AuthError
                    // if (state is AuthError && !isLoading) // Chỉ hiển thị lỗi nếu không phải đang loading
                    //   Padding(
                    //     padding: const EdgeInsets.only(bottom: 10.0),
                    //     child: Text(
                    //       state.message,
                    //       style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                    //       textAlign: TextAlign.center,
                    //     ),
                    //   ),
                    // const SizedBox(height: 16), // Bỏ bớt SizedBox nếu không hiển thị lỗi ở đây nữa

                    // Hiển thị CircularProgressIndicator ngay trên các nút khi isLoading
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Gọi phương thức của AuthCubit từ context
                              context.read<AuthCubit>().signInWithEmail(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Cân nhắc dùng màu từ Theme
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Sign In'),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Gọi phương thức của AuthCubit từ context
                              context.read<AuthCubit>().signInWithGoogle();
                            },
                            icon: const Icon(Icons.g_mobiledata, size: 32), // Cân nhắc dùng icon Google chuẩn
                            label: const Text('Login with Google'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading ? null : () { // Vô hiệu hóa khi đang loading
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: const Text(
                        'Create Account',
                        style: TextStyle(color: Color(0xFF00C4FF)), // Cân nhắc dùng màu từ Theme
                      ),
                    ),
                    const SizedBox(height: 20), // Thêm khoảng trống ở dưới
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}