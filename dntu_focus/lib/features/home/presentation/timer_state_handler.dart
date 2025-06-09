import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/home_cubit.dart';

class TimerStateHandler {
  final HomeCubit homeCubit;
  final MethodChannel notificationChannel;
  final Future<SharedPreferences> sharedPreferences;

  TimerStateHandler({
    required this.homeCubit,
    required this.notificationChannel,
    required this.sharedPreferences,
  });

  Future<void> restoreTimerState() async {
    try {
      // Ưu tiên trạng thái từ TimerService
      final timerState = await notificationChannel.invokeMethod('getTimerState');
      print('Raw timerState from TimerService: $timerState');
      int timerSeconds = timerState?['timerSeconds'] ?? 25 * 60;
      bool isRunning = timerState?['isRunning'] ?? false;
      bool isPaused = timerState?['isPaused'] ?? false;
      bool isCountingUp = timerState?['isCountingUp'] ?? false;

      // Validate trạng thái
      if (isRunning && isPaused) {
        print('Warning: Invalid state - timer isRunning=true and isPaused=true');
      }
      if (!isRunning && isPaused) {
        print('Warning: Invalid state - timer isRunning=false but isPaused=true');
      }

      homeCubit.restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
        isCountingUp: isCountingUp,
      );
      print('Restored timer state from service: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp');
    } catch (e) {
      print('Error restoring timer state from service: $e');
      // Fallback về SharedPreferences nếu service không khả dụng
      final prefs = await sharedPreferences;
      int timerSeconds = prefs.getInt('timerSeconds') ?? 25 * 60;
      bool isRunning = prefs.getBool('isRunning') ?? false;
      bool isPaused = prefs.getBool('isPaused') ?? false;
      bool isCountingUp = prefs.getBool('isCountingUp') ?? false;

      homeCubit.restoreTimerState(
        timerSeconds: timerSeconds,
        isRunning: isRunning,
        isPaused: isPaused,
        isCountingUp: isCountingUp,
      );
      print('Restored from SharedPreferences: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp');
    }
  }
}