import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moji_todo/features/report/data/models/pomodoro_session_model.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';

class PomodoroRecordsChart extends StatelessWidget {
  final Map<DateTime, List<PomodoroSessionRecordModel>> data;
  final List<Project> allProjects;

  const PomodoroRecordsChart({
    super.key,
    required this.data,
    required this.allProjects,
  });

  Project _findProjectById(String? projectId) {
    if (projectId == null) {
      return Project(id: 'general', name: 'General', color: Colors.grey.shade400);
    }
    return allProjects.firstWhere(
          (p) => p.id == projectId,
      orElse: () => Project(id: projectId, name: 'Unknown', color: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sắp xếp các ngày theo thứ tự giảm dần (mới nhất lên trên)
    final sortedDays = data.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        _buildTimeAxis(),
        const SizedBox(height: 8),
        for (final day in sortedDays) _buildDayRow(context, day, data[day]!),
      ],
    );
  }

  Widget _buildTimeAxis() {
    // Tạo các nhãn thời gian từ 8:00 đến 20:00
    return Row(
      children: [
        const SizedBox(width: 60), // Khoảng trống cho nhãn ngày
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final hour = 8 + (index * 2);
              return Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(
      BuildContext context,
      DateTime day,
      List<PomodoroSessionRecordModel> sessions,
      ) {
    String dayLabel;
    final now = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(day, now)) {
      dayLabel = 'Today';
    } else if (DateUtils.isSameDay(
        day, now.subtract(const Duration(days: 1)))) {
      dayLabel = 'Yester..';
    } else {
      dayLabel = DateFormat('MMM d').format(day); // Ví dụ: Dec 18
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              dayLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Khung thời gian từ 8h sáng đến 8h tối (12 tiếng)
                const totalDurationInMinutes = 12 * 60;
                final totalWidth = constraints.maxWidth;

                return SizedBox(
                  height: 20, // Chiều cao của một hàng
                  child: Stack(
                    children: sessions.where((s)=>s.isWorkSession).map((session) {
                      final project = _findProjectById(session.projectId);
                      final start = session.startTime;
                      // Chỉ vẽ các session trong khoảng 8h-20h
                      if (start.hour < 8 || start.hour >= 20) {
                        return const SizedBox.shrink();
                      }
                      final minutesFrom8AM = (start.hour - 8) * 60 + start.minute;
                      final leftPosition = (minutesFrom8AM / totalDurationInMinutes) * totalWidth;
                      final barWidth = (session.duration / 60 / totalDurationInMinutes) * totalWidth;

                      return Positioned(
                        left: leftPosition,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: barWidth,
                          margin: const EdgeInsets.symmetric(horizontal: 1), // Khoảng cách giữa các bar
                          decoration: BoxDecoration(
                            color: project.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}