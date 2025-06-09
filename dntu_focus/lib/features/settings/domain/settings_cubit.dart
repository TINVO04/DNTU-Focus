import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final syncInterval = prefs.getInt('syncInterval') ?? 6;
    final themeModeString = prefs.getString('themeMode') ?? 'auto';
    final themeMode = ThemeModeOption.values.firstWhere(
          (e) => e.toString().split('.').last == themeModeString,
      orElse: () => ThemeModeOption.auto,
    );
    emit(state.copyWith(syncInterval: syncInterval, themeMode: themeMode));
  }

  Future<void> setSyncInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('syncInterval', hours);
    emit(state.copyWith(syncInterval: hours));
  }

  Future<void> setThemeMode(ThemeModeOption themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode.toString().split('.').last);
    emit(state.copyWith(themeMode: themeMode));
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      emit(state.copyWith(isLoggedOut: true, logoutError: null));
    } catch (e) {
      emit(state.copyWith(isLoggedOut: false, logoutError: e.toString()));
    }
  }
}