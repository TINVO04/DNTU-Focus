import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../routes/app_routes.dart';
import '../domain/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                    const SizedBox(height: 48),
                    _buildEmailField(isLoading),
                    const SizedBox(height: 16),
                    _buildPasswordField(isLoading),
                    const SizedBox(height: 8),
                    _buildForgotPasswordButton(context, isLoading),
                    const SizedBox(height: 24),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildSignInButton(context),
                    const SizedBox(height: 24),
                    _buildSocialLoginSeparator(textTheme),
                    const SizedBox(height: 24),
                    _buildGoogleSignInButton(context, isLoading),
                    const SizedBox(height: 32),
                    _buildSignUpNavigation(context, isLoading, textTheme, colorScheme),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_moji.png',
          height: 100,
          width: 100,
        ),
        const SizedBox(height: 24),
        Text(
          'DNTU - Focus',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ===== THAY ĐỔI MÀU NỀN Ở ĐÂY =====
  Widget _buildEmailField(bool isLoading) {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: 'Email',
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: Colors.grey.shade300, // <-- MÀU ĐẬM HƠN
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      enabled: !isLoading,
    );
  }

  // ===== VÀ Ở ĐÂY =====
  Widget _buildPasswordField(bool isLoading) {
    return TextField(
      controller: _passwordController,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        filled: true,
        fillColor: Colors.grey.shade300, // <-- MÀU ĐẬM HƠN
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: true,
      enabled: !isLoading,
    );
  }

  Widget _buildForgotPasswordButton(BuildContext context, bool isLoading) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: isLoading ? null : () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
        child: const Text('Forgot Password?'),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.read<AuthCubit>().signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      child: const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSocialLoginSeparator(TextTheme textTheme) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, bool isLoading) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : () => context.read<AuthCubit>().signInWithGoogle(),
      icon: const Icon(Icons.g_mobiledata, size: 28.0),
      label: const Text('Sign In with Google'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildSignUpNavigation(BuildContext context, bool isLoading, TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?", style: textTheme.bodyMedium),
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pushNamed(context, AppRoutes.register),
          child: Text(
            'Sign Up',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}