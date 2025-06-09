import 'package:flutter_test/flutter_test.dart';
import 'package:moji_todo/features/home/domain/home_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeCubit timer logic', () {
    test('startTimer sets correct initial state when counting down', () {
      final cubit = HomeCubit(skipInit: true);
      expect(cubit.state.isTimerRunning, false);
      cubit.startTimer();
      expect(cubit.state.isTimerRunning, true);
      expect(cubit.state.isPaused, false);
      expect(cubit.state.timerSeconds, cubit.state.workDuration * 60);
      expect(cubit.state.currentSession, 1);
    });
  });
}
