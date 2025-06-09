import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/home/domain/home_cubit.dart';
import 'package:moji_todo/features/home/presentation/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/unified_notification_service.dart';
import '../../tasks/data/models/task_model.dart';
import 'timer_state_handler.dart';

class HomeScreenStateManager {
  final BuildContext context;
  final Future<SharedPreferences> sharedPreferences;
  final Function(BuildContext) onShowTaskBottomSheet;
  final MethodChannel _channel = const MethodChannel('com.example.moji_todo/notification');
  final MethodChannel _serviceChannel = const MethodChannel('com.example.moji_todo/app_block_service');
  late final TimerStateHandler _timerStateHandler;
  late final PermissionHandler permissionHandler;
  bool _isActionPending = false; // Giữ lại để tránh spam action

  HomeScreenStateManager({
    required this.context,
    required this.sharedPreferences,
    required this.onShowTaskBottomSheet,
  }) {
    _timerStateHandler = TimerStateHandler(
      homeCubit: context.read<HomeCubit>(),
      notificationChannel: _channel,
      sharedPreferences: sharedPreferences,
    );
    permissionHandler = PermissionHandler(
      context: context,
      notificationChannel: _channel,
      notificationService: UnifiedNotificationService(), // UnifiedNotificationService() cần được khởi tạo hoặc truyền vào
      onPermissionStateChanged: _updatePermissionState,
    );
  }

  Future<void> init() async {
    // Luôn khôi phục trạng thái timer từ service khi khởi động app
    // TimerStateHandler sẽ gọi native service để lấy trạng thái và cập nhật HomeCubit
    await _restoreTimerState();
    await _checkStrictMode();
  }

  Future<void> checkAndRequestPermissionsForTimer() async {
    await permissionHandler.checkNotificationPermission();
    await permissionHandler.checkBackgroundPermission();
  }

  Future<void> _restoreTimerState() async {
    try {
      // _timerStateHandler sẽ gọi service để lấy trạng thái mới nhất và cập nhật Cubit
      await _timerStateHandler.restoreTimerState();
      print('Restored timer state via TimerStateHandler');
    } catch (e) {
      print('Error restoring timer state: $e');
    }
  }

  Future<void> _checkStrictMode() async {
    try {
      final prefs = await sharedPreferences;
      final isStrictModeEnabled = prefs.getBool('isStrictModeEnabled') ?? false;
      if (isStrictModeEnabled) {
        context.read<HomeCubit>().updateStrictMode(isAppBlockingEnabled: true);
        final isBlockAppsEnabled = prefs.getBool('isBlockAppsEnabled') ?? false;
        final blockedApps = prefs.getStringList('blockedApps') ?? [];
        if (isBlockAppsEnabled) {
          await _serviceChannel.invokeMethod('setBlockedApps', {'apps': blockedApps});
          await _serviceChannel.invokeMethod('setAppBlockingEnabled', {'enabled': true});
          print('Strict mode enabled: blockedApps=$blockedApps, appBlockingEnabled=true');
        }
      }
    } catch (e) {
      print('Error checking strict mode: $e');
    }
  }

  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      print('App lifecycle: paused (TimerService manages state persistence).');
    } else if (state == AppLifecycleState.resumed) {
      print('App lifecycle: resumed. Requesting fresh timer state from TimerService.');
      // Khi app resume, luôn yêu cầu trạng thái mới nhất từ TimerService.
      // TimerService sẽ emit qua EventChannel, và HomeCubit sẽ lắng nghe và cập nhật UI.
      await _restoreTimerState();
    }
  }

  Future<void> handleTimerAction(String action, {Task? task, int? estimatedPomodoros}) async {
    if (_isActionPending) {
      print('Action pending, ignoring: $action');
      return;
    }

    _isActionPending = true;
    final homeCubit = context.read<HomeCubit>();
    print('Handling timer action from UI: $action');

    // Logic kiểm tra canProceed (có thể được đơn giản hóa hoặc chuyển hoàn toàn vào Cubit nếu Cubit đã xử lý tốt)
    bool canProceed = true;
    switch (action) {
      case 'start':
        if (homeCubit.state.isTimerRunning) {
          canProceed = false;
        }
        break;
      case 'pause':
        if (!homeCubit.state.isTimerRunning || homeCubit.state.isPaused) {
          canProceed = false;
        }
        break;
      case 'continue':
        if (homeCubit.state.isTimerRunning || !homeCubit.state.isPaused) {
          canProceed = false;
        }
        break;
      case 'stop':
        if (!homeCubit.state.isTimerRunning && !homeCubit.state.isPaused) {
          canProceed = false;
        }
        break;
    }

    if (!canProceed) {
      print('Action $action cannot proceed based on current state.');
      _isActionPending = false;
      return;
    }

    // Gửi lệnh trực tiếp đến HomeCubit.
    // HomeCubit sẽ gửi lệnh đến Native Service (qua _notificationChannel),
    // và Native Service sẽ phát trạng thái về qua EventChannel.
    switch (action) {
      case 'start':
        try {
          await checkAndRequestPermissionsForTimer(); // Vẫn cần kiểm tra quyền trước khi start
          if (task != null && estimatedPomodoros != null) {
            homeCubit.selectTask(task.title, estimatedPomodoros);
          }
          homeCubit.startTimer(); // HomeCubit sẽ tự gọi native service
          print('Initiated start timer action in HomeCubit.');
        } catch (e) {
          print('Error initiating start timer: $e');
        }
        break;
      case 'pause':
        try {
          homeCubit.pauseTimer(); // HomeCubit sẽ tự gọi native service
          print('Initiated pause timer action in HomeCubit.');
        } catch (e) {
          print('Error initiating pause timer: $e');
        }
        break;
      case 'continue':
        try {
          await checkAndRequestPermissionsForTimer(); // Vẫn cần kiểm tra quyền trước khi continue
          homeCubit.continueTimer(); // HomeCubit sẽ tự gọi native service
          print('Initiated continue timer action in HomeCubit.');
        } catch (e) {
          print('Error initiating continue timer: $e');
        }
        break;
      case 'stop':
        try {
          homeCubit.stopTimer(); // HomeCubit sẽ tự gọi native service
          print('Initiated stop timer action in HomeCubit.');
        } catch (e) {
          print('Error initiating stop timer: $e');
        }
        break;
    }

    // Mở khóa hành động sau một khoảng trễ nhỏ để tránh spam
    await Future.delayed(const Duration(milliseconds: 500));
    _isActionPending = false;
    print('Action lock released for $action');
  }

  void dispose() {
    _isActionPending = false;
  }

  void _updatePermissionState({
    bool? hasNotificationPermission,
    bool? hasRequestedBackgroundPermission,
    bool? isIgnoringBatteryOptimizations,
  }) {
    // Cập nhật trạng thái quyền ở đây nếu cần phản ứng trong UI
    // Ví dụ: hiển thị cảnh báo cho người dùng
  }

  // Getter này có thể được loại bỏ hoặc thay đổi tùy thuộc vào cách bạn quản lý quyền
  // Hiện tại giữ lại để tránh lỗi nếu có nơi nào đó vẫn sử dụng nó.
  bool get hasNotificationPermission => true;
}