import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/home_cubit.dart';
import '../../domain/home_state.dart';
import '../home_screen_state_manager.dart';
import '../../../../core/widgets/custom_button.dart'; // Đảm bảo đường dẫn đúng
import 'dart:async';

class PomodoroTimer extends StatefulWidget {
  final HomeScreenStateManager? stateManager;

  const PomodoroTimer({super.key, this.stateManager});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0.0;
  Timer? _debounceTimer;
  bool _isActionLocked = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateProgressAnimation(context.read<HomeCubit>().state, isInitialSetup: true);
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _updateProgressAnimation(HomeState state, {bool isInitialSetup = false}) {
    final totalDuration = (state.isWorkSession ? state.workDuration : state.breakDuration) * 60;
    double targetProgress = 0.0;

    if (!state.isCountingUp && totalDuration > 0) {
      targetProgress = state.timerSeconds / totalDuration;
    } else if (state.isCountingUp) {
      targetProgress = 0.0;
    }
    targetProgress = targetProgress.clamp(0.0, 1.0);

    if (isInitialSetup || (targetProgress - _currentProgress).abs() > 0.001 || state.isTimerRunning != _progressController.isAnimating) {
      if (!state.isCountingUp && state.isTimerRunning && !state.isPaused) {
        _progressAnimation = Tween<double>(
          begin: _currentProgress,
          end: targetProgress,
        ).animate(CurvedAnimation(parent: _progressController, curve: Curves.linear));
        _progressController.duration = Duration(seconds: state.timerSeconds);
        if (_progressController.isAnimating) _progressController.stop();
        _progressController.value = 1.0 - targetProgress;
        _progressController.reverse(from: 1.0 - targetProgress);
      } else if (state.isPaused || !state.isTimerRunning) {
        _progressController.stop();
      }
      _currentProgress = targetProgress;
    }
    if (!_progressController.isAnimating) {
      _progressController.value = state.isCountingUp ? 0.0 : (1.0 - targetProgress);
    }
  }

  void _debouncedAction(String action, {int? estimatedPomodoros}) {
    if (_isActionLocked) return;
    _isActionLocked = true;
    widget.stateManager?.handleTimerAction(action, estimatedPomodoros: estimatedPomodoros);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () => _isActionLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // 1. Đường kính vòng tròn Pomodoro
    double calculatedTimerDiameter;
    if (screenWidth <= 360) { // Màn hình B (348) hoặc nhỏ hơn
      calculatedTimerDiameter = screenWidth * 0.7; // bạn đã chọn 0.7
    } else if (screenWidth <= 480) { // Màn hình A (412) hoặc trong khoảng này
      calculatedTimerDiameter = screenWidth * 0.8; // bạn đã chọn 0.8
    } else { // Màn hình lớn hơn
      calculatedTimerDiameter = screenWidth * 0.9; // bạn đã chọn 0.9
    }
    final double timerDiameter = calculatedTimerDiameter.clamp(190.0, 350.0); // bạn đã chọn min 190, max 350

    // 2. Độ dày của vòng tròn
    final double strokeWidth = timerDiameter * 0.065; // bạn đã chọn 0.065

    // 3. Kích thước chữ hiển thị thời gian
    final double timeFontSize = timerDiameter * 0.17; // bạn đã chọn 0.17

    // 4. Kích thước chữ hiển thị trạng thái
    final double statusHeaderFontSize = timerDiameter * 0.06; // bạn đã chọn 0.06 cho "Phiên làm việc/nghỉ"
    final double sessionStatusFontSize = timerDiameter * 0.05; // bạn đã chọn 0.065 cho "x/y phiên"

    // 5. Khoảng cách (SizedBox)
    final double spacingAfterStatusHeader = timerDiameter * 0.06; // bạn đã chọn 0.06
    final double spacingAfterTimer = timerDiameter * 0.15; // bạn đã chọn 0.15


    return BlocConsumer<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
      previous.timerSeconds != current.timerSeconds ||
          previous.isTimerRunning != current.isTimerRunning ||
          previous.isPaused != current.isPaused ||
          previous.isWorkSession != current.isWorkSession ||
          previous.workDuration != current.workDuration ||
          previous.breakDuration != current.breakDuration ||
          previous.isCountingUp != current.isCountingUp,
      listener: (context, state) {
        _updateProgressAnimation(state);
      },
      buildWhen: (previous, current) =>
      previous.timerSeconds != current.timerSeconds ||
          previous.isTimerRunning != current.isTimerRunning ||
          previous.isPaused != current.isPaused ||
          previous.isWorkSession != current.isWorkSession ||
          previous.workDuration != current.workDuration ||
          previous.breakDuration != current.breakDuration ||
          previous.currentSession != current.currentSession ||
          previous.totalSessions != current.totalSessions ||
          previous.isCountingUp != current.isCountingUp,
      builder: (context, state) {
        final minutes = (state.timerSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (state.timerSeconds % 60).toString().padLeft(2, '0');
        String sessionStatusText;
        if (state.isCountingUp) {
          sessionStatusText = 'Đang đếm lên';
        } else if (state.isTimerRunning || state.isPaused) {
          sessionStatusText = '${state.currentSession} / ${state.totalSessions} phiên';
        } else {
          if (state.selectedTask != null) {
            if (state.isWorkSession) {
              sessionStatusText = 'Sẵn sàng làm việc (Phiên ${state.currentSession + 1})';
            } else {
              sessionStatusText = 'Sẵn sàng nghỉ ngơi';
            }
          } else {
            sessionStatusText = 'Chưa chọn task';
          }
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.isCountingUp
                  ? 'Đếm lên'
                  : (state.isWorkSession ? 'Phiên làm việc' : 'Phiên nghỉ'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                // SỬA Ở ĐÂY: fontSize nên dùng statusHeaderFontSize hay sessionStatusFontSize?
                // Hiện tại bạn đang dùng sessionStatusFontSize * 1.15, có thể nên thống nhất
                fontSize: statusHeaderFontSize, // Hoặc sessionStatusFontSize * 1.1 (tùy ý bạn)
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacingAfterStatusHeader),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: timerDiameter,
                  height: timerDiameter,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: state.isCountingUp ? null : _currentProgress,
                        strokeWidth: strokeWidth,
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          state.isPaused
                              ? Theme.of(context).colorScheme.secondary.withOpacity(0.7)
                              : state.isTimerRunning
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes:$seconds',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: timeFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      sessionStatusText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: sessionStatusFontSize, // SỬA Ở ĐÂY: Dùng sessionStatusFontSize
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: spacingAfterTimer),
            // ... (Các nút giữ nguyên) ...
            if (!state.isTimerRunning && !state.isPaused)
              CustomButton(
                label: state.isCountingUp
                    ? 'Bắt đầu đếm'
                    : (state.isWorkSession ? 'Bắt đầu tập trung' : 'Bắt đầu nghỉ'),
                onPressed: () => _debouncedAction('start'),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                textColor: Theme.of(context).colorScheme.onSecondary,
                borderRadius: 20,
              ),
            if (state.isTimerRunning && !state.isPaused)
              CustomButton(
                label: 'Tạm dừng',
                onPressed: () => _debouncedAction('pause'),
                backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                textColor: Theme.of(context).colorScheme.onSurface,
                borderRadius: 20,
              ),
            if (state.isPaused)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomButton(
                    label: 'Dừng hẳn',
                    onPressed: () => _debouncedAction('stop'),
                    backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.8),
                    textColor: Theme.of(context).colorScheme.onError,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    label: 'Tiếp tục',
                    onPressed: () => _debouncedAction('continue'),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    textColor: Theme.of(context).colorScheme.onSecondary,
                    borderRadius: 20,
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}