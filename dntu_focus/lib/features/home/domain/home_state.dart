import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final String? selectedTask;
  final int? selectedTaskId;
  final int timerSeconds;
  final bool isTimerRunning;
  final bool isPaused;
  final int currentSession; // Số session làm việc đã hoàn thành trong cycle hiện tại
  final int totalSessions;  // Tổng số session làm việc trong một cycle
  final bool isStrictModeEnabled;
  final bool isAppBlockingEnabled;
  final bool isFlipPhoneEnabled;
  final bool isExitBlockingEnabled;
  final List<String> blockedApps;
  final String timerMode;
  final int workDuration;   // Phút
  final int breakDuration;  // Phút
  final bool soundEnabled;
  final bool autoSwitch;
  final bool isWorkSession; // True nếu đang là phiên làm việc, false nếu là phiên nghỉ
  final String notificationSound;
  final bool isWhiteNoiseEnabled;
  final String? selectedWhiteNoise;
  final double whiteNoiseVolume;
  final bool isCountingUp;
  final DateTime? currentSessionActualStartTime; // <<< THÊM DÒNG NÀY: Thời điểm bắt đầu thực tế của phiên hiện tại

  const HomeState({
    this.selectedTask,
    this.selectedTaskId,
    this.timerSeconds = 25 * 60,
    this.isTimerRunning = false,
    this.isPaused = false,
    this.currentSession = 0,
    this.totalSessions = 4,
    this.isStrictModeEnabled = false,
    this.isAppBlockingEnabled = false,
    this.isFlipPhoneEnabled = false,
    this.isExitBlockingEnabled = false,
    this.blockedApps = const [],
    this.timerMode = '25:00 - 00:00',
    this.workDuration = 25,
    this.breakDuration = 5,
    this.soundEnabled = true,
    this.autoSwitch = false,
    this.isWorkSession = true,
    this.notificationSound = 'bell',
    this.isWhiteNoiseEnabled = false,
    this.selectedWhiteNoise,
    this.whiteNoiseVolume = 1.0,
    this.isCountingUp = false,
    this.currentSessionActualStartTime, // <<< THÊM DÒNG NÀY
  });

  HomeState copyWith({
    String? selectedTask,
    int? selectedTaskId,
    int? timerSeconds,
    bool? isTimerRunning,
    bool? isPaused,
    int? currentSession,
    int? totalSessions,
    bool? isStrictModeEnabled,
    bool? isAppBlockingEnabled,
    bool? isFlipPhoneEnabled,
    bool? isExitBlockingEnabled,
    List<String>? blockedApps,
    String? timerMode,
    int? workDuration,
    int? breakDuration,
    bool? soundEnabled,
    bool? autoSwitch,
    bool? isWorkSession,
    String? notificationSound,
    bool? isWhiteNoiseEnabled,
    String? selectedWhiteNoise,
    double? whiteNoiseVolume,
    bool? isCountingUp,
    DateTime? currentSessionActualStartTime, // <<< THÊM DÒNG NÀY
    bool clearCurrentSessionActualStartTime = false, // <<< THÊM DÒNG NÀY để cho phép xóa giá trị
  }) {
    return HomeState(
      selectedTask: selectedTask ?? this.selectedTask,
      selectedTaskId: selectedTaskId ?? this.selectedTaskId,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      isPaused: isPaused ?? this.isPaused,
      currentSession: currentSession ?? this.currentSession,
      totalSessions: totalSessions ?? this.totalSessions,
      isStrictModeEnabled: isStrictModeEnabled ?? this.isStrictModeEnabled,
      isAppBlockingEnabled: isAppBlockingEnabled ?? this.isAppBlockingEnabled,
      isFlipPhoneEnabled: isFlipPhoneEnabled ?? this.isFlipPhoneEnabled,
      isExitBlockingEnabled: isExitBlockingEnabled ?? this.isExitBlockingEnabled,
      blockedApps: blockedApps ?? this.blockedApps,
      timerMode: timerMode ?? this.timerMode,
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      autoSwitch: autoSwitch ?? this.autoSwitch,
      isWorkSession: isWorkSession ?? this.isWorkSession,
      notificationSound: notificationSound ?? this.notificationSound,
      isWhiteNoiseEnabled: isWhiteNoiseEnabled ?? this.isWhiteNoiseEnabled,
      selectedWhiteNoise: selectedWhiteNoise ?? this.selectedWhiteNoise,
      whiteNoiseVolume: whiteNoiseVolume ?? this.whiteNoiseVolume,
      isCountingUp: isCountingUp ?? this.isCountingUp,
      // <<< SỬA ĐỔI LOGIC CẬP NHẬT:
      currentSessionActualStartTime: clearCurrentSessionActualStartTime
          ? null
          : currentSessionActualStartTime ?? this.currentSessionActualStartTime,
    );
  }

  @override
  List<Object?> get props => [
    selectedTask,
    selectedTaskId,
    timerSeconds,
    isTimerRunning,
    isPaused,
    currentSession,
    totalSessions,
    isStrictModeEnabled,
    isAppBlockingEnabled,
    isFlipPhoneEnabled,
    isExitBlockingEnabled,
    blockedApps,
    timerMode,
    workDuration,
    breakDuration,
    soundEnabled,
    autoSwitch,
    isWorkSession,
    notificationSound,
    isWhiteNoiseEnabled,
    selectedWhiteNoise,
    whiteNoiseVolume,
    isCountingUp,
    currentSessionActualStartTime, // <<< THÊM DÒNG NÀY
  ];
}