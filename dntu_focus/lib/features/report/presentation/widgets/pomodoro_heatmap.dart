import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import '../../data/models/pomodoro_session_model.dart';

class PomodoroHeatmap extends StatelessWidget {
  final Map<DateTime, List<PomodoroSessionRecordModel>> data;
  const PomodoroHeatmap({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No pomodoro data'));
    }

    // Convert to dataset with count of work sessions per day
    final Map<DateTime, int> datasets = {};
    data.forEach((day, sessions) {
      datasets[day] = sessions.where((s) => s.isWorkSession).length;
    });

    final startDate = datasets.keys.reduce((a, b) => a.isBefore(b) ? a : b);

    return HeatMap(
      startDate: startDate,
      endDate: DateTime.now(),
      datasets: datasets,
      colorMode: ColorMode.color,
      showColorTip: false,
      colorsets: const {
        1: Color(0xFF9be9a8),
        3: Color(0xFF40c463),
        5: Color(0xFF30a14e),
        7: Color(0xFF216e39),
      },
    );
  }
}
