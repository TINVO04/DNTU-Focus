import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../routes/app_routes.dart';
import '../domain/auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Hàm xử lý đăng ký, giờ sẽ gọi Cubit
  void _onRegisterPressed() {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Gọi phương thức từ AuthCubit
    context.read<AuthCubit>().signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthAuthenticated) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    }
                  });
                } else if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final bool isLoading = state is AuthLoading;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(textTheme),
                    const SizedBox(height: 32),
                    _buildEmailField(isLoading),
                    const SizedBox(height: 16),
                    _buildUsernameField(isLoading),
                    const SizedBox(height: 16),
                    _buildPasswordField(isLoading),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(isLoading),
                    const SizedBox(height: 24),
                    _buildTermsCheckbox(),
                    const SizedBox(height: 24),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildSignUpButton(),
                    const SizedBox(height: 32),
                    _buildSignInNavigation(context, isLoading, textTheme),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- CÁC HÀM BUILD UI CHUYÊN NGHIỆP ---

  Widget _buildHeader(TextTheme textTheme) {
    return Column(
      children: [
        // Dùng lại logo và style tương tự trang Login
        Image.asset(
          'assets/images/logo_moji.png',
          height: 80,
          width: 80,
        ),
        const SizedBox(height: 16),
        Text(
          'Create Account',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Start your productive journey today!',
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isLoading) {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: 'Email',
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      enabled: !isLoading,
    );
  }

  Widget _buildUsernameField(bool isLoading) {
    return TextField(
      controller: _usernameController,
      decoration: InputDecoration(
        hintText: 'Username',
        prefixIcon: const Icon(Icons.person_outline),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      enabled: !isLoading,
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    return TextField(
      controller: _passwordController,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: true,
      enabled: !isLoading,
    );
  }

  Widget _buildConfirmPasswordField(bool isLoading) {
    return TextField(
      controller: _confirmPasswordController,
      decoration: InputDecoration(
        hintText: 'Confirm Password',
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: true,
      enabled: !isLoading,
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() {
              _acceptTerms = value ?? false;
            });
          },
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              children: [
                TextSpan(
                  text: 'Terms & Conditions',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    // TODO: Mở link đến trang Terms
                    print('Navigate to Terms & Conditions');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _onRegisterPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      child: const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSignInNavigation(BuildContext context, bool isLoading, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account?", style: textTheme.bodyMedium),
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context), // Quay lại màn hình trước đó
          child: Text(
            'Log In',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade400,
            ),
          ),
        ),
      ],
    );
  }
}