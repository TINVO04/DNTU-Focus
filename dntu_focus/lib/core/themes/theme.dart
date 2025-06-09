import 'package:flutter/material.dart';

// ThemeExtension để định nghĩa màu success
@immutable
class SuccessColor extends ThemeExtension<SuccessColor> {
  final Color success;

  const SuccessColor({required this.success});

  @override
  SuccessColor copyWith({Color? success}) {
    return SuccessColor(
      success: success ?? this.success,
    );
  }

  @override
  SuccessColor lerp(ThemeExtension<SuccessColor>? other, double t) {
    if (other is! SuccessColor) {
      return this;
    }
    return SuccessColor(
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF00C4FF),
    scaffoldBackgroundColor: const Color(0xFFE6F7FA),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFFF69B4)),
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 18, // Điều chỉnh fontsize tiêu đề
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.grey),
    ),
    // SỬA Ở ĐÂY: CardTheme -> CardThemeData
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFFFF5733),
      textTheme: ButtonTextTheme.primary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF5733),
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: Colors.blue,
      secondary: const Color(0xFFFF5733),
      primaryContainer: const Color(0xFFE3F2FD),
      errorContainer: const Color(0xFFFFEBEE),
      error: const Color(0xFFD32F2F),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      SuccessColor(success: Color(0xFF4CAF50)),
    ],
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: const Color(0xFF00C4FF),
    scaffoldBackgroundColor: const Color(0xFF2A2A2A),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFFF69B4)),
      bodyMedium: TextStyle(color: Color(0xFFB0BEC5)),
      titleLarge: TextStyle(
        color: Color(0xFFE0E0E0),
        fontWeight: FontWeight.bold,
        fontSize: 18, // Điều chỉnh fontsize tiêu đề
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Color(0xFFB0BEC5)),
    ),
    // SỬA Ở ĐÂY: CardTheme -> CardThemeData
    cardTheme: CardThemeData(
      color: const Color(0xFF3A3A3A),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFFFF5733),
      textTheme: ButtonTextTheme.primary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFF5733),
      foregroundColor: Color(0xFFE0E0E0),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: const Color(0xFFFF5733),
      surface: const Color(0xFF3A3A3A),
      onSurface: const Color(0xFFB0BEC5),
      primaryContainer: const Color(0xFF424242),
      errorContainer: const Color(0xFF4A2A2A),
      error: const Color(0xFFF44336),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      SuccessColor(success: Color(0xFF66BB6A)),
    ],
  );
}