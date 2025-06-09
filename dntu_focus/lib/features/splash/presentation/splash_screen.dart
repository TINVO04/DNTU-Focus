import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    print('Khởi tạo SplashScreen');
    _controller = VideoPlayerController.asset('assets/images/splash_moji.mp4')
      ..initialize().then((_) {
        print('Video initialized successfully');
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _controller.play();
          _controller.setLooping(false);
          _waitAndNavigate();
        }
      }).catchError((error) {
        print('Lỗi khi load video: $error');
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
          _waitAndNavigate();
        }
      });
  }

  Future<void> _waitAndNavigate() async {
    // Chờ tối thiểu 3 giây và đảm bảo video chạy xong (nếu video dài hơn 3 giây)
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)), // Tối thiểu 3 giây
      _isVideoInitialized
          ? Future.delayed(_controller.value.duration)
          : Future.value(), // Nếu video lỗi, bỏ qua
    ]);

    // Kiểm tra trạng thái đăng nhập
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacementNamed(
        context,
        user != null ? AppRoutes.home : AppRoutes.login,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Center(
        child: _isVideoInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : Image.asset(
          'assets/images/fallback_logo.png', // Fallback image nếu video lỗi
          width: 300,
          height: 300,
        ),
      ),
    );
  }
}