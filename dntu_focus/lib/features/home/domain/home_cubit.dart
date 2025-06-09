import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tasks/data/models/project_model.dart';
import '../../tasks/data/models/tag_model.dart';
import '../../tasks/data/models/task_model.dart';
import 'home_state.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/unified_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // BỎ COMMENT DÒNG NÀY ĐỂ SỬ DỤNG WidgetsBinding.instance.lifecycle

const String prefTimerSeconds = "timerSeconds";
const String prefIsRunning = "isRunning";
const String prefIsPaused = "isPaused";
const String prefWhiteNoiseEnabled = "whiteNoiseEnabled";
const String prefSelectedWhiteNoise = "selectedWhiteNoise";
const String prefWhiteNoiseVolume = "whiteNoiseVolume";
const String prefIsCountingUp = "isCountingUp";
const String prefIsWorkSession = "isWorkSession";
// NEW: Keys for sound settings (Giữ lại từ lần sửa trước)
const String prefSoundEnabled = "soundEnabled";
const String prefNotificationSound = "notificationSound";
const String prefAutoSwitch = "autoSwitch";

class TimerActions {
  static const String start = 'START';
  static const String pause = 'com.example.moji_todo.PAUSE';
  static const String resume = 'com.example.moji_todo.RESUME';
  static const String stop = 'com.example.moji_todo.STOP';
}

class HomeCubit extends Cubit<HomeState> {
  /// When [skipInit] is true the cubit will not perform heavy initialization
  /// such as opening Hive boxes or setting up audio listeners. This is useful
  /// for unit tests where those dependencies are not available.
  HomeCubit({bool skipInit = false}) : super(const HomeState()) {
    if (!skipInit) {
      _initialize();
      _initAudioPlayerListeners(); // NEW: Gọi hàm khởi tạo listener cho AudioPlayer
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const MethodChannel _notificationChannel = MethodChannel('com.example.moji_todo/notification');
  static const MethodChannel _serviceChannel = MethodChannel('com.example.moji_todo/app_block_service');
  static const EventChannel _eventChannel = EventChannel('com.example.moji_todo/timer_events');
  StreamSubscription? _timerSubscription;
  bool _lastAppBlockingState = false;
  late BackupService _backupService;
  bool _hasPlayedSoundOnEnd = false;
  final UnifiedNotificationService _notificationService = UnifiedNotificationService();
  bool _hasShownEndSessionNotification = false;
  Timer? _endSessionNotificationTimer;

  // NEW: StreamSubscription cho trạng thái của AudioPlayer
  StreamSubscription? _playerStateSubscription;

  // NEW: Hàm khởi tạo listener cho AudioPlayer
  void _initAudioPlayerListeners() {
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((PlayerState s) {
      print('[AudioPlayer] State changed: $s');
      // Logic bổ sung có thể được thêm ở đây nếu cần, ví dụ: tự động phát lại nếu hoàn thành ngoài ý muốn.
      // Tuy nhiên, cần cẩn thận để tránh vòng lặp vô hạn nếu tệp âm thanh bị lỗi.
      if (s == PlayerState.completed) {
        print('[AudioPlayer] Playback completed. Current state: isWhiteNoiseEnabled=${state.isWhiteNoiseEnabled}, selectedWhiteNoise=${state.selectedWhiteNoise}, isTimerRunning=${state.isTimerRunning}, isPaused=${state.isPaused}');
        // Nếu ReleaseMode.loop hoạt động đúng, trạng thái này không nên xảy ra thường xuyên đối với white noise.
        // Nếu nó xảy ra, có thể thử phát lại nếu các điều kiện vẫn còn đúng.
        if (state.isWhiteNoiseEnabled &&
            state.selectedWhiteNoise != null &&
            state.selectedWhiteNoise != 'none' &&
            state.isTimerRunning &&
            !state.isPaused) {
          print('[AudioPlayer] Attempting to replay white noise due to completion.');
          // Cẩn trọng khi gọi _playWhiteNoise trực tiếp ở đây để tránh vòng lặp nếu lỗi từ setSource.
          // Có thể chỉ gọi _audioPlayer.resume() nếu chắc chắn source vẫn còn và hợp lệ.
          // Hoặc, nếu muốn đảm bảo, gọi lại _playWhiteNoise.
          // _playWhiteNoise(state.selectedWhiteNoise!); // Cân nhắc kỹ lưỡng nếu muốn tự động phát lại
        }
      } else if (s == PlayerState.stopped) {
        print('[AudioPlayer] Playback stopped. Current state: isWhiteNoiseEnabled=${state.isWhiteNoiseEnabled}, selectedWhiteNoise=${state.selectedWhiteNoise}, isTimerRunning=${state.isTimerRunning}, isPaused=${state.isPaused}');
      } else if (s == PlayerState.paused) {
        print('[AudioPlayer] Playback paused. Current state: isWhiteNoiseEnabled=${state.isWhiteNoiseEnabled}, selectedWhiteNoise=${state.selectedWhiteNoise}, isTimerRunning=${state.isTimerRunning}, isPaused=${state.isPaused}');
      }
    });

    // Optional: Listen to logs from audioplayers if available (newer versions might have different ways)
    // _audioPlayer.onLog.listen((String msg) { // onLog có thể không còn trong các phiên bản mới
    //   print('[AudioPlayer Internal Log] $msg');
    // });
  }

  Future<void> _initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _notificationService.init();

    final prefs = await SharedPreferences.getInstance();
    final isWhiteNoiseEnabled = prefs.getBool(prefWhiteNoiseEnabled) ?? false; //
    final selectedWhiteNoise = prefs.getString(prefSelectedWhiteNoise) ?? 'none'; //
    final whiteNoiseVolume = prefs.getDouble(prefWhiteNoiseVolume) ?? 1.0; //
    final isCountingUp = prefs.getBool(prefIsCountingUp) ?? false; //
    final isWorkSession = prefs.getBool(prefIsWorkSession) ?? true; //

    // Load sound settings from SharedPreferences (đã có từ lần sửa trước)
    final soundEnabled = prefs.getBool(prefSoundEnabled) ?? true;
    final notificationSound = prefs.getString(prefNotificationSound) ?? 'bell'; //
    final autoSwitch = prefs.getBool(prefAutoSwitch) ?? false;

    emit(state.copyWith(
      isWhiteNoiseEnabled: isWhiteNoiseEnabled,
      selectedWhiteNoise: selectedWhiteNoise,
      whiteNoiseVolume: whiteNoiseVolume,
      isCountingUp: isCountingUp,
      isWorkSession: isWorkSession,
      soundEnabled: soundEnabled,
      notificationSound: notificationSound,
      autoSwitch: autoSwitch,
    ));

    _backupService = BackupService(
      Hive.box<Task>('tasks'),
      Hive.box<DateTime>('sync_info'),
      Hive.box<Project>('projects'),
      Hive.box<Tag>('tags'),
    );

    _timerSubscription = _eventChannel.receiveBroadcastStream().listen((event) async {
      final args = event as Map;
      final timerSeconds = args['timerSeconds'] as int;
      final isRunning = args['isRunning'] as bool;
      final isPaused = args['isPaused'] as bool;
      final isCountingUp = args['isCountingUp'] as bool? ?? state.isCountingUp;
      final isWorkSessionFromService = args['isWorkSession'] as bool? ?? state.isWorkSession;

      print('Timer update received: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp, isWorkSession=$isWorkSessionFromService');

      emit(state.copyWith(
        timerSeconds: timerSeconds,
        isTimerRunning: isRunning && !isPaused,
        isPaused: isPaused,
        isCountingUp: isCountingUp,
        isWorkSession: isWorkSessionFromService,
      ));

      if (!isCountingUp && timerSeconds <= 0 && !isRunning && !isPaused) {
        try {
          await _backupService.savePomodoroSession(
            taskId: state.selectedTask ?? 'none',
            startTime: DateTime.now().subtract(Duration(seconds: isWorkSessionFromService ? state.workDuration * 60 : state.breakDuration * 60)),
            endTime: DateTime.now(),
            isWorkSession: isWorkSessionFromService,
            soundUsed: state.notificationSound,
          );
          print('Saved Pomodoro session');
        } catch (e) {
          print('Error saving Pomodoro session: $e');
        }

        _handleSessionEnded(isWorkSessionFromService);

        if (state.autoSwitch) {
          if (isWorkSessionFromService) {
            if (state.currentSession < state.totalSessions) {
              emit(state.copyWith(
                timerSeconds: state.breakDuration * 60,
                isWorkSession: false,
                isTimerRunning: true,
                isPaused: false,
                currentSession: state.currentSession,
              ));
              await _startTimerServiceCall(state.breakDuration * 60, true, false, false, false);
              print('Auto-switching to break session.');
            } else {
              emit(state.copyWith(
                timerSeconds: state.workDuration * 60,
                isTimerRunning: false,
                isPaused: false,
                currentSession: 0,
                isWorkSession: true,
              ));
              if (state.selectedTask != null) {
                await _updateTaskPomodoroState(state.selectedTask, false, 0);
              }
              await _notificationChannel.invokeMethod(TimerActions.stop);
              print('All sessions completed. Timer Service stopped.');
            }
          } else {
            if (state.currentSession < state.totalSessions) {
              emit(state.copyWith(
                timerSeconds: state.workDuration * 60,
                isWorkSession: true,
                isTimerRunning: true,
                isPaused: false,
                currentSession: state.currentSession + 1,
              ));
              await _startTimerServiceCall(state.workDuration * 60, true, false, false, true);
              print('Auto-switching to next work session.');
            } else {
              emit(state.copyWith(
                timerSeconds: state.workDuration * 60,
                isTimerRunning: false,
                isPaused: false,
                currentSession: 0,
                isWorkSession: true,
              ));
              if (state.selectedTask != null) {
                await _updateTaskPomodoroState(state.selectedTask, false, 0);
              }
              await _notificationChannel.invokeMethod(TimerActions.stop);
              print('Fall-through in auto-switch: all sessions completed or logic error.');
            }
          }
        } else {
          emit(state.copyWith(
            timerSeconds: isWorkSessionFromService ? state.breakDuration * 60 : state.workDuration * 60,
            isTimerRunning: false,
            isPaused: false,
            isWorkSession: !isWorkSessionFromService,
          ));
          if (state.selectedTask != null) {
            await _updateTaskPomodoroState(state.selectedTask, false, state.timerSeconds);
          }
          await _notificationChannel.invokeMethod(TimerActions.stop);
          print('Session completed. Auto-switch is off. Timer service stopped.');
        }
        await _updateSharedPreferences(state.timerSeconds, state.isTimerRunning, state.isPaused, state.isWorkSession);
        _hasPlayedSoundOnEnd = false;
      } else {
        _hasPlayedSoundOnEnd = false;
        _hasShownEndSessionNotification = false;
        _endSessionNotificationTimer?.cancel();
      }
    }, onError: (e) {
      print('Error in timer event stream: $e');
    });

    _notificationChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onSessionEnded':
          final isWorkSession = call.arguments['isWorkSession'] as bool;
          print('Received onSessionEnded from Native (app in background): isWorkSession=$isWorkSession');
          _handleSessionEnded(isWorkSession);
          return null;
        case 'startBreak':
          print('Handling startBreak from notification (via MainActivity).');
          emit(state.copyWith(
            timerSeconds: state.breakDuration * 60,
            isWorkSession: false,
            isTimerRunning: false,
            isPaused: false,
            isCountingUp: false,
          ));
          await _updateSharedPreferences(state.breakDuration * 60, false, false, false);
          await _startTimerServiceCall(state.breakDuration * 60, false, false, false, false);
          return null;
        case 'startWork':
          print('Handling startWork from notification (via MainActivity).');
          emit(state.copyWith(
            timerSeconds: state.workDuration * 60,
            isWorkSession: true,
            isTimerRunning: false,
            isPaused: false,
            currentSession: state.currentSession + 1,
            isCountingUp: false,
          ));
          await _updateSharedPreferences(state.workDuration * 60, false, false, true);
          await _startTimerServiceCall(state.workDuration * 60, false, false, false, true);
          return null;
        case 'completedAllSessions':
          print('Handling completedAllSessions from notification (via MainActivity).');
          emit(state.copyWith(
            timerSeconds: state.workDuration * 60,
            isTimerRunning: false,
            isPaused: false,
            currentSession: 0,
            isWorkSession: true,
          ));
          await _updateSharedPreferences(state.workDuration * 60, false, false, true);
          await _notificationChannel.invokeMethod(TimerActions.stop);
          return null;
        case 'pause':
          print('Handling pause from notification via MethodChannel. Flutter UI should update via EventChannel.');
          return null;
        case 'resume':
          print('Handling resume from notification via MethodChannel. Flutter UI should update via EventChannel.');
          return null;
        case 'stop':
          print('Handling stop from notification via MethodChannel. Flutter UI should update via EventChannel.');
          return null;
        case 'showEndSessionNotification':
          print('showEndSessionNotification received via MethodChannel (might be deprecated)');
          return null;
        case 'setFromNotification':
          return null;
        default:
          return null;
      }
    });
    await _listenToTasks(user.uid);
  }

  Future<void> _handleSessionEnded(bool isWorkSessionThatEnded) async {
    print('_handleSessionEnded called for session type: ${isWorkSessionThatEnded ? "Work" : "Break"}');

    await _notificationService.cancelNotification(id: UnifiedNotificationService.TIMER_NOTIFICATION_ID);

    String title;
    String body;
    String payload;

    if (isWorkSessionThatEnded) {
      if (state.currentSession < state.totalSessions) {
        title = "Đã hoàn thành phiên làm việc";
        body = "Nhấn để bắt đầu phiên nghỉ!";
        payload = 'START_BREAK';
        print('Work session ended, not last session.');
      } else {
        title = "Đã hoàn thành công việc";
        body = "Bạn đã hoàn thành tất cả các phiên Pomodoro!";
        payload = 'COMPLETED_ALL_SESSIONS';
        print('Work session ended, last session.');
      }
    } else {
      title = "Đã hoàn thành phiên nghỉ";
      body = "Nhấn để bắt đầu phiên làm việc tiếp theo!";
      payload = 'START_WORK';
      print('Break session ended.');
    }

    if (!_hasShownEndSessionNotification) {
      try {
        await _notificationService.showEndSessionNotification(
          isWorkSession: isWorkSessionThatEnded,
          title: title,
          body: body,
          payload: payload,
          soundEnabled: state.soundEnabled,
          notificationSound: state.notificationSound,
        );
        _hasShownEndSessionNotification = true;
        print('Showed end session notification from _handleSessionEnded with soundEnabled: ${state.soundEnabled}, sound: ${state.notificationSound}');
      } catch (e) {
        print('Error showing end session notification from _handleSessionEnded: $e');
      }
    }
  }


  Future<void> _listenToTasks(String uid) async {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where('isPomodoroActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        if (state.selectedTask == null) {
          final taskDoc = snapshot.docs.first;
          final task = Task.fromJson(taskDoc.data());
          emit(state.copyWith(
            selectedTask: task.title,
            timerSeconds: task.remainingPomodoroSeconds ?? (state.workDuration * 60),
            isTimerRunning: true,
            isPaused: false,
            currentSession: task.completedPomodoros ?? 0,
            totalSessions: task.estimatedPomodoros ?? state.totalSessions,
            isWorkSession: true,
            isCountingUp: false,
          ));
          await _startTimerServiceCall(task.remainingPomodoroSeconds ?? (state.workDuration * 60), true, false, false, true);
        }
      }
    });
  }

  void selectTask(String? taskTitle, int estimatedPomodoros) {
    emit(state.copyWith(
      selectedTask: taskTitle,
      totalSessions: taskTitle != null ? estimatedPomodoros : state.totalSessions,
      currentSession: 0,
      timerSeconds: state.workDuration * 60,
      isTimerRunning: false,
      isPaused: false,
      isWorkSession: true,
      isCountingUp: state.isCountingUp,
    ));
  }

  void startTimer() {
    if (state.isTimerRunning && !state.isPaused) {
      print('Timer already running, ignoring start');
      return;
    }
    if (state.isPaused) {
      print('Timer paused, calling continueTimer instead of startTimer.');
      continueTimer();
      return;
    }

    int timerSeconds;
    bool isWorkSessionToStart = state.isWorkSession;
    if (state.isCountingUp) {
      timerSeconds = 0;
    } else {
      timerSeconds = isWorkSessionToStart ? state.workDuration * 60 : state.breakDuration * 60;
      if (timerSeconds <= 0) {
        print('Invalid timer duration for counting down mode');
        return;
      }
    }

    _hasPlayedSoundOnEnd = false;
    _hasShownEndSessionNotification = false;
    _endSessionNotificationTimer?.cancel();

    emit(state.copyWith(
      timerSeconds: timerSeconds,
      isTimerRunning: true,
      isPaused: false,
      currentSession: isWorkSessionToStart && !state.isTimerRunning && !state.isPaused ? state.currentSession + 1 : state.currentSession,
    ));

    _resetPreviousPomodoro();
    _updateSharedPreferences(timerSeconds, true, false, isWorkSessionToStart);
    _startTimerServiceCall(timerSeconds, true, false, state.isCountingUp, isWorkSessionToStart);


    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, true, timerSeconds);
    }
    if (state.isWhiteNoiseEnabled && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none') {
      _playWhiteNoise(state.selectedWhiteNoise!);
    }
  }

  void pauseTimer() {
    if (!state.isTimerRunning || state.isPaused) {
      print('Timer not running or already paused, ignoring pause');
      return;
    }

    emit(state.copyWith(
      isTimerRunning: false,
      isPaused: true,
    ));
    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, false, state.timerSeconds);
    }

    try {
      _notificationChannel.invokeMethod(TimerActions.pause);
      print('Sent PAUSE intent to native.');
    } catch (e) {
      print('Error sending PAUSE intent: $e');
    }
    _updateSharedPreferences(state.timerSeconds, false, true, state.isWorkSession);
    // Chỉ gọi _audioPlayer.pause() nếu nó đang thực sự phát
    if (_audioPlayer.state == PlayerState.playing) { // NEW: Check player state before pausing
      _audioPlayer.pause();
      print('[AudioPlayer] Called pause() explicitly.');
    }
  }

  void continueTimer() {
    if (state.isTimerRunning || !state.isPaused) {
      print('Timer not paused or already running, ignoring continue');
      return;
    }

    emit(state.copyWith(
      isTimerRunning: true,
      isPaused: false,
    ));

    if (state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, true, state.timerSeconds);
    }
    _updateSharedPreferences(state.timerSeconds, true, false, state.isWorkSession);

    try {
      _notificationChannel.invokeMethod(TimerActions.resume);
      print('Sent RESUME intent to native.');
    } catch (e) {
      print('Error sending RESUME intent: $e');
    }

    final newAppBlockingState = state.isAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
    }
    if (state.isWhiteNoiseEnabled && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none') {
      _playWhiteNoise(state.selectedWhiteNoise!);
    }
  }

  void stopTimer({bool updateTaskState = true}) {
    emit(state.copyWith(
      timerSeconds: state.isCountingUp ? 0 : state.workDuration * 60,
      isTimerRunning: false,
      isPaused: false,
      currentSession: 0,
      isWorkSession: true,
    ));
    if (updateTaskState && state.selectedTask != null) {
      _updateTaskPomodoroState(state.selectedTask, false, 0);
    }

    try {
      _notificationChannel.invokeMethod(TimerActions.stop);
      print('Sent STOP intent to native.');
    } catch (e) {
      print('Error sending STOP intent: $e');
    }
    _updateSharedPreferences(state.isCountingUp ? 0 : state.workDuration * 60, false, false, true);
    _audioPlayer.stop();
    print('[AudioPlayer] Called stop() explicitly in stopTimer.'); // NEW: Log explicit stop
    _hasPlayedSoundOnEnd = false;
    _hasShownEndSessionNotification = false;
    _endSessionNotificationTimer?.cancel();
  }

  void resetTask() async {
    if (state.selectedTask != null) {
      await _updateTaskPomodoroState(state.selectedTask, false, 0);
    }
    stopTimer(updateTaskState: false);
    selectTask(null, state.totalSessions);
  }

  void updateStrictMode({
    bool? isAppBlockingEnabled,
    bool? isFlipPhoneEnabled,
    bool? isExitBlockingEnabled,
  }) {
    if (state.isTimerRunning && !state.isPaused) {
      print('Cannot update Strict Mode: Timer is running');
      return;
    }

    final newAppBlockingEnabled = isAppBlockingEnabled ?? state.isAppBlockingEnabled;
    final newFlipPhoneEnabled = isFlipPhoneEnabled ?? state.isFlipPhoneEnabled;
    final newExitBlockingEnabled = isExitBlockingEnabled ?? state.isExitBlockingEnabled;

    final isStrictModeEnabled = newAppBlockingEnabled || newFlipPhoneEnabled || newExitBlockingEnabled;

    emit(state.copyWith(
      isStrictModeEnabled: isStrictModeEnabled,
      isAppBlockingEnabled: newAppBlockingEnabled,
      isFlipPhoneEnabled: newFlipPhoneEnabled,
      isExitBlockingEnabled: newExitBlockingEnabled,
    ));

    final newAppBlockingState = newAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
    }

    if (newExitBlockingEnabled && state.isWhiteNoiseEnabled && state.isTimerRunning) {
      if (_audioPlayer.state == PlayerState.playing) { // NEW: Check player state
        _audioPlayer.pause();
        print('[AudioPlayer] Called pause() due to Strict Mode (Exit Blocking).');
      }
    } else if (!newExitBlockingEnabled && state.isWhiteNoiseEnabled && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none' && state.isTimerRunning && !state.isPaused) {
      _playWhiteNoise(state.selectedWhiteNoise!);
    }
  }

  void updateBlockedApps(List<String> blockedApps) {
    if (state.isTimerRunning && !state.isPaused) {
      print('Cannot update blocked apps: Timer is running');
      return;
    }
    if (state.isAppBlockingEnabled && blockedApps.isEmpty) {
      print('Cannot save empty blocked apps when App Blocking is enabled');
      return;
    }
    emit(state.copyWith(blockedApps: blockedApps));
  }

  Future<void> updateTimerMode({
    required String timerMode,
    required int workDuration,
    required int breakDuration,
    required bool soundEnabled,
    required bool autoSwitch,
    required String notificationSound,
    int? totalSessions,
  }) async {
    if (state.isTimerRunning && !state.isPaused) {
      print('Cannot update Timer Mode: Timer is running');
      return;
    }

    bool isCountingUp = false;
    int newWorkDuration = workDuration;
    int newBreakDuration = breakDuration;
    bool newAutoSwitch = autoSwitch;

    if (newWorkDuration < 1 || newWorkDuration > 480) {
      newWorkDuration = 25;
    }
    if (newBreakDuration < 1 || newBreakDuration > 60) {
      newBreakDuration = 5;
    }
    final newTotalSessions = totalSessions ?? state.totalSessions;
    if (newTotalSessions < 1 || newTotalSessions > 10) {
      totalSessions = 4;
    }

    switch (timerMode) {
      case '25:00 - 00:00':
        newWorkDuration = 25;
        newBreakDuration = 5;
        isCountingUp = false;
        break;
      case '00:00 - 0∞':
        newWorkDuration = 0;
        newBreakDuration = 0;
        isCountingUp = true;
        newAutoSwitch = false;
        break;
      case 'Tùy chỉnh':
        isCountingUp = false;
        break;
    }

    emit(state.copyWith(
      timerMode: timerMode,
      workDuration: newWorkDuration,
      breakDuration: newBreakDuration,
      soundEnabled: soundEnabled,
      autoSwitch: newAutoSwitch,
      notificationSound: notificationSound,
      totalSessions: totalSessions ?? newTotalSessions,
      timerSeconds: state.isTimerRunning ? state.timerSeconds : (newWorkDuration * 60),
      isWorkSession: true,
      isCountingUp: isCountingUp,
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefSoundEnabled, soundEnabled);
    await prefs.setString(prefNotificationSound, notificationSound);
    await prefs.setBool(prefAutoSwitch, newAutoSwitch);
    print('Saved sound settings to SharedPreferences: soundEnabled=$soundEnabled, notificationSound=$notificationSound, autoSwitch=$newAutoSwitch');

    await _updateSharedPreferences(state.isTimerRunning ? state.timerSeconds : (newWorkDuration * 60), false, false, true);
  }

  void restoreTimerState({
    required int timerSeconds,
    required bool isRunning,
    required bool isPaused,
    required bool isCountingUp,
    bool? isWorkSession,
  }) {
    print('[HomeCubit] restoreTimerState called: isRunning=$isRunning, isPaused=$isPaused, isWhiteNoiseEnabled=${state.isWhiteNoiseEnabled}, selectedWhiteNoise=${state.selectedWhiteNoise}');
    emit(state.copyWith(
      timerSeconds: timerSeconds,
      isTimerRunning: isRunning && !isPaused,
      isPaused: isPaused,
      isCountingUp: isCountingUp,
      isWorkSession: isWorkSession ?? state.isWorkSession,
    ));

    final newAppBlockingState = state.isAppBlockingEnabled && state.isTimerRunning;
    if (newAppBlockingState != _lastAppBlockingState) {
      print('Setting app blocking enabled: $newAppBlockingState');
      _serviceChannel.invokeMethod('setAppBlockingEnabled', {
        'enabled': newAppBlockingState,
      });
      _lastAppBlockingState = newAppBlockingState;
    }
    if (isRunning && !isPaused && state.isWhiteNoiseEnabled && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none') { // MODIFIED: Use direct isRunning and isPaused
      _playWhiteNoise(state.selectedWhiteNoise!);
    } else {
      _audioPlayer.stop();
      print('[AudioPlayer] Called stop() in restoreTimerState (conditions not met or timer not running/paused).'); // NEW: Log
    }
  }

  void toggleWhiteNoise(bool enable) async {
    print('[HomeCubit] toggleWhiteNoise called with enable: $enable. Current selected: ${state.selectedWhiteNoise}');
    emit(state.copyWith(isWhiteNoiseEnabled: enable));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefWhiteNoiseEnabled, enable);

    if (enable && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none' && state.isTimerRunning && !state.isPaused) {
      _playWhiteNoise(state.selectedWhiteNoise!);
    } else {
      _audioPlayer.stop();
      print('[AudioPlayer] Called stop() in toggleWhiteNoise (enable is false or conditions not met).'); // NEW: Log
    }
  }

  void selectWhiteNoise(String sound) async {
    print('[HomeCubit] selectWhiteNoise called with sound: $sound');
    emit(state.copyWith(
      selectedWhiteNoise: sound,
      isWhiteNoiseEnabled: sound != 'none',
    ));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefSelectedWhiteNoise, sound);

    if (sound != 'none' && state.isWhiteNoiseEnabled && state.isTimerRunning && !state.isPaused) {
      _playWhiteNoise(sound);
    } else {
      _audioPlayer.stop();
      print('[AudioPlayer] Called stop() in selectWhiteNoise (sound is none or conditions not met).'); // NEW: Log
    }
  }

  void setWhiteNoiseVolume(double volume) async {
    emit(state.copyWith(whiteNoiseVolume: volume));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(prefWhiteNoiseVolume, volume);

    if (state.isWhiteNoiseEnabled && state.selectedWhiteNoise != null && state.selectedWhiteNoise != 'none' && state.isTimerRunning && !state.isPaused) {
      // Chỉ gọi setVolume nếu player có khả năng đang phát hoặc sẽ phát
      // Tránh gọi setVolume trên player đã stop hoàn toàn và chưa setSource lại
      if (_audioPlayer.source != null) { // NEW: Check if source is set
        await _audioPlayer.setVolume(volume);
        print('[AudioPlayer] Volume set to $volume');
      }
    }
  }

  Future<void> _playWhiteNoise(String sound) async {
    print('[HomeCubit] _playWhiteNoise called with sound: $sound. Current state: isTimerRunning=${state.isTimerRunning}, isPaused=${state.isPaused}');
    if (sound == 'none' || sound.isEmpty) {
      print('[AudioPlayer] _playWhiteNoise: Sound is none or empty, stopping player.');
      await _audioPlayer.stop(); // Ensure player is stopped if sound is 'none'
      return;
    }
    try {
      // Luôn stop trước khi set source mới để đảm bảo trạng thái sạch
      await _audioPlayer.stop();
      print('[AudioPlayer] Called stop() before setSource in _playWhiteNoise.');

      await _audioPlayer.setSource(AssetSource('sounds/whiteNoise/$sound.mp3'));
      print('[AudioPlayer] Source set to: sounds/whiteNoise/$sound.mp3');

      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      print('[AudioPlayer] ReleaseMode set to loop.');

      await _audioPlayer.setVolume(state.whiteNoiseVolume);
      print('[AudioPlayer] Volume set to ${state.whiteNoiseVolume} in _playWhiteNoise.');

      final playbackRate = ['clock_ticking'].contains(sound) ? 0.8 : 1.0;
      await _audioPlayer.setPlaybackRate(playbackRate);
      print('[AudioPlayer] Playback rate set to $playbackRate.');

      if (state.isTimerRunning && !state.isPaused) {
        await _audioPlayer.resume(); // Sử dụng resume sau khi setSource
        print('[AudioPlayer] Playing white noise: $sound (resumed/started)');
      } else {
        print('[AudioPlayer] Conditions not met to play white noise (timer not running or paused). Player remains stopped/paused.');
      }
    } catch (e) {
      print('[AudioPlayer] Error playing white noise: $e');
      if (kDebugMode) {
        print('[AudioPlayer] White noise sound file not found or error playing: $sound.mp3. Exception: ${e.toString()}');
      }
      // Cân nhắc việc emit một trạng thái lỗi ở đây nếu cần
      emit(state.copyWith(isWhiteNoiseEnabled: false, selectedWhiteNoise: 'none')); // Tự động tắt white noise nếu có lỗi
    }
  }

  Future<void> _startTimerServiceCall(int seconds, bool isRunning, bool isPaused, bool isCountingUp, bool isWorkSession) async {
    final intent = {
      'action': TimerActions.start,
      'timerSeconds': seconds,
      'isRunning': isRunning,
      'isPaused': isPaused,
      'isCountingUp': isCountingUp,
      'isWorkSession': isWorkSession,
    };
    print('Sending START/UPDATE intent to native: $intent');
    try {
      await _notificationChannel.invokeMethod('startTimerService', intent);
    } catch (e) {
      print('Error invoking startTimerService: $e');
    }
  }

  Future<void> _resetPreviousPomodoro() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('isPomodoroActive', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({
        'isPomodoroActive': false,
        'remainingPomodoroSeconds': 0,
      });
    }
  }

  Future<void> _updateTaskPomodoroState(String? taskTitle, bool isActive, int remainingSeconds) async {
    final user = _auth.currentUser;
    if (user == null || taskTitle == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .where('title', isEqualTo: taskTitle)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final taskDoc = snapshot.docs.first;
      await taskDoc.reference.update({
        'isPomodoroActive': isActive,
        'remainingPomodoroSeconds': remainingSeconds,
        'completedPomodoros': state.currentSession,
      });
    }
  }

  Future<void> _playSound() async { // This is for notification sound, not white noise.
    if (!state.soundEnabled) {
      print('Sound is disabled, skipping sound playback');
      return;
    }

    // This method uses _audioPlayer, which might conflict if it was also used for notification sounds.
    // However, notifications are now system handled, so this _playSound is likely unused or for a different purpose.
    // For clarity, it's better if white noise and other in-app sounds use separate players if complex interactions are needed.
    // But for now, it seems _audioPlayer is solely for white noise.
    // The AssetSource path here is different 'sounds/' vs 'sounds/whiteNoise/'
    final soundFile = 'sounds/${state.notificationSound}.mp3';
    print('[AudioPlayer] Attempting to play notification sound (in-app): $soundFile with _audioPlayer instance.');
    // Be cautious if _audioPlayer is already playing white noise.
    // This _playSound method seems to be a legacy from when notification sounds were in-app.
    // It will interrupt white noise if called.
    try {
      // await _audioPlayer.play(AssetSource(soundFile)); // This would conflict. This method is probably not called.
      print('[AudioPlayer] Successfully played sound (in-app): $soundFile --- THIS LOGIC SHOULD BE REVIEWED IF _playSound IS STILL USED.');
    } catch (e) {
      print('[AudioPlayer] Error playing sound (in-app): $e');
      if (kDebugMode) {
        print('[AudioPlayer] Notification sound file not found or error playing (in-app): $soundFile');
      }
    }
  }

  Future<void> _updateSharedPreferences(int timerSeconds, bool isRunning, bool isPaused, bool isWorkSession) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefTimerSeconds, timerSeconds);
    await prefs.setBool(prefIsRunning, isRunning);
    await prefs.setBool(prefIsPaused, isPaused);
    await prefs.setBool(prefIsCountingUp, state.isCountingUp);
    await prefs.setBool(prefIsWorkSession, isWorkSession);
    print('Updated SharedPreferences: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=${state.isCountingUp}, isWorkSession=$isWorkSession');
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    _endSessionNotificationTimer?.cancel();
    _playerStateSubscription?.cancel(); // NEW: Hủy subscription của player state
    _audioPlayer.dispose();
    print('[AudioPlayer] Disposed.'); // NEW: Log dispose
    return super.close();
  }
}