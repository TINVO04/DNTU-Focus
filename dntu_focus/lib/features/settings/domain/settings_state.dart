import 'package:equatable/equatable.dart';

enum ThemeModeOption { light, dark, auto }

class SettingsState extends Equatable {
  final bool isLoggedOut;
  final String? logoutError;
  final int syncInterval; // Khoảng thời gian đồng bộ (giờ)
  final ThemeModeOption themeMode;

  const SettingsState({
    this.isLoggedOut = false,
    this.logoutError,
    this.syncInterval = 6, // Mặc định 6h
    this.themeMode = ThemeModeOption.auto,
  });

  SettingsState copyWith({
    bool? isLoggedOut,
    String? logoutError,
    int? syncInterval,
    ThemeModeOption? themeMode,
  }) {
    return SettingsState(
      isLoggedOut: isLoggedOut ?? this.isLoggedOut,
      logoutError: logoutError ?? this.logoutError,
      syncInterval: syncInterval ?? this.syncInterval,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [isLoggedOut, logoutError, syncInterval, themeMode];
}