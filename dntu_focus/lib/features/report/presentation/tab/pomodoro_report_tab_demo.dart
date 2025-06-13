import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// --- PHẦN GIẢ LẬP CÁC MODEL VÀ WIDGET CẦN THIẾT ---
// Để code này có thể chạy độc lập mà không cần các file khác.
class Project {
  final String id;
  final String name;
  final Color color;
  Project({required this.id, required this.name, required this.color});
}

class Task {
  final String id;
  final String title;
  final String? projectId;
  Task({required this.id, required this.title, this.projectId});
}

class PomodoroSessionRecordModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int duration;
  final bool isWorkSession;
  final String? taskId;
  final String? projectId;

  PomodoroSessionRecordModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.isWorkSession,
    this.taskId,
    this.projectId,
  });
}

enum ReportDataFilter { daily, weekly, biweekly, monthly, yearly }
enum ReportStatus { success }

class ReportState {
  final ReportStatus status;
  final Duration focusTimeToday;
  final Duration focusTimeThisWeek;
  final Duration focusTimeThisTwoWeeks;
  final Duration focusTimeThisMonth;
  final List<Project> allProjects;
  final List<Task> allTasks;
  final Map<DateTime, List<PomodoroSessionRecordModel>> pomodoroHeatmapData;
  final Map<DateTime, Map<String?, Duration>> focusTimeChartData;
  final Set<DateTime> focusGoalMetDays;
  final ReportDataFilter focusTimeChartFilter;

  ReportState({
    required this.status,
    required this.focusTimeToday,
    required this.focusTimeThisWeek,
    required this.focusTimeThisTwoWeeks,
    required this.focusTimeThisMonth,
    required this.allProjects,
    required this.allTasks,
    required this.pomodoroHeatmapData,
    required this.focusTimeChartData,
    required this.focusGoalMetDays,
    required this.focusTimeChartFilter,
  });
}

class SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  const SummaryCard({Key? key, required this.value, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class PomodoroRecordsChart extends StatelessWidget {
  final Map<DateTime, List<PomodoroSessionRecordModel>> data;
  final List<Project> allProjects;

  const PomodoroRecordsChart({Key? key, required this.data, required this.allProjects}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 150, child: Center(child: Text('[Biểu đồ lịch sử Pomodoro]')));
  }
}

class FocusTimeBarChart extends StatelessWidget {
  final Map<DateTime, Map<String?, Duration>> chartData;
  final List<Project> allProjects;

  const FocusTimeBarChart({Key? key, required this.chartData, required this.allProjects}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 200, child: Center(child: Text('[Biểu đồ thời gian tập trung]')));
  }
}
// --- KẾT THÚC PHẦN GIẢ LẬP ---


class PomodoroReportTabDemo extends StatelessWidget {
  const PomodoroReportTabDemo({super.key});

  // Hàm tạo dữ liệu mẫu
  ReportState getDemoReportState() {
    final now = DateTime.now();
    final projects = [
      Project(id: 'proj1', name: 'Phát triển ứng dụng', color: Colors.blue),
      Project(id: 'proj2', name: 'Học tập', color: Colors.green),
      Project(id: 'proj3', name: 'Cá nhân', color: Colors.orange),
    ];

    final tasks = [
      Task(id: 'task1', title: 'Thiết kế giao diện', projectId: 'proj1'),
      Task(id: 'task2', title: 'Học Flutter', projectId: 'proj2'),
      Task(id: 'task3', title: 'Lên kế hoạch tập gym', projectId: 'proj3'),
    ];

    final pomodoroHeatmapData = {
      DateTime(now.year, now.month, now.day): [
        PomodoroSessionRecordModel(
          id: '1',
          startTime: DateTime(now.year, now.month, now.day, 9, 0),
          endTime: DateTime(now.year, now.month, now.day, 9, 25),
          duration: 25 * 60,
          isWorkSession: true,
          projectId: 'proj1',
          taskId: 'task1',
        ),
        PomodoroSessionRecordModel(
          id: '2',
          startTime: DateTime(now.year, now.month, now.day, 10, 0),
          endTime: DateTime(now.year, now.month, now.day, 10, 25),
          duration: 25 * 60,
          isWorkSession: true,
          projectId: 'proj2',
          taskId: 'task2',
        ),
      ],
      DateTime(now.year, now.month, now.day - 1): [
        PomodoroSessionRecordModel(
          id: '3',
          startTime: DateTime(now.year, now.month, now.day - 1, 14, 0),
          endTime: DateTime(now.year, now.month, now.day - 1, 14, 25),
          duration: 25 * 60,
          isWorkSession: true,
          projectId: 'proj3',
          taskId: 'task3',
        ),
      ],
    };

    final focusTimeChartData = {
      DateTime(now.year, now.month, now.day): {
        'proj1': const Duration(hours: 2),
        'proj2': const Duration(hours: 1),
        'proj3': const Duration(minutes: 30),
      },
      DateTime(now.year, now.month, now.day - 1): {
        'proj1': const Duration(hours: 1),
        'proj2': const Duration(hours: 2),
      },
      DateTime(now.year, now.month, now.day - 2): {
        'proj3': const Duration(hours: 1, minutes: 15),
      },
    };

    return ReportState(
      status: ReportStatus.success,
      focusTimeToday: const Duration(hours: 3, minutes: 30),
      focusTimeThisWeek: const Duration(hours: 20),
      focusTimeThisTwoWeeks: const Duration(hours: 35),
      focusTimeThisMonth: const Duration(hours: 80),
      allProjects: projects,
      allTasks: tasks,
      pomodoroHeatmapData: pomodoroHeatmapData,
      focusTimeChartData: focusTimeChartData,
      focusGoalMetDays: {
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day - 2),
      },
      focusTimeChartFilter: ReportDataFilter.biweekly,
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) return '0p';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    String result = '';
    if (hours > 0) result += '${hours}g ';
    if (minutes > 0) result += '${minutes}p';
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    final state = getDemoReportState();

    return Scaffold( // Thêm Scaffold để có nền trắng dễ nhìn
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(context, state),
            const SizedBox(height: 24),
            _buildPomodoroRecords(context, state),
            const SizedBox(height: 24),
            _buildFocusGoal(context, state),
            const SizedBox(height: 24),
            _buildFocusTimeChart(context, state),
          ],
        ),
      ),
    );
  }

  // ===== PHẦN ĐƯỢC SỬA LỖI =====
  Widget _buildSummaryCards(BuildContext context, ReportState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 16) / 2;

    // Nhãn dưới mỗi ô thể hiện rõ khoảng thời gian tương ứng
    final cards = [
      SummaryCard(
        value: _formatDuration(state.focusTimeToday),
        label: 'Thời gian tập trung hôm nay',
      ),
      SummaryCard(
        value: _formatDuration(state.focusTimeThisWeek),
        label: 'Thời gian tập trung tuần này',
      ),
      SummaryCard(
        value: _formatDuration(state.focusTimeThisTwoWeeks),
        label: 'Thời gian tập trung 2 tuần',
      ),
      SummaryCard(
        value: _formatDuration(state.focusTimeThisMonth),
        label: 'Thời gian tập trung tháng này',
      ),
    ];

    // Thêm một tiêu đề chung cho khu vực này
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thời gian tập trung',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
        ),
      ],
    );
  }
  // ==============================

  Widget _buildPomodoroRecords(BuildContext context, ReportState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Lịch sử Pomodoro',
          filterWidget: _buildFilterDropdown(
            context,
            value: ReportDataFilter.weekly,
            onChanged: (filter) {},
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PomodoroRecordsChart(
              data: state.pomodoroHeatmapData,
              allProjects: state.allProjects,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusGoal(BuildContext context, ReportState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Mục tiêu tập trung',
          filterWidget: _buildFilterDropdown(
            context,
            value: ReportDataFilter.monthly,
            onChanged: (filter) {},
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: DateTime.now(),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isGoalMet = state.focusGoalMetDays.contains(DateUtils.dateOnly(day));
                  if (isGoalMet) {
                    return Container(
                      margin: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.withOpacity(0.8), width: 1.5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    );
                  }
                  return null;
                },
                todayBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle().copyWith(color: Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusTimeChart(BuildContext context, ReportState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          title: 'Biểu đồ thời gian tập trung',
          filterWidget: _buildFilterDropdown(
            context,
            value: state.focusTimeChartFilter,
            onChanged: (filter) {},
          ),
        ),
        const SizedBox(height: 16),
        FocusTimeBarChart(
          chartData: state.focusTimeChartData,
          allProjects: state.allProjects,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, Widget? filterWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (filterWidget != null) filterWidget,
      ],
    );
  }

  Widget _buildFilterDropdown(BuildContext context,
      {required ReportDataFilter value, required void Function(ReportDataFilter?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportDataFilter>(
          value: value,
          items: ReportDataFilter.values.map((filter) {
            String filterName;
            switch (filter) {
              case ReportDataFilter.daily:
                filterName = 'Hàng ngày';
                break;
              case ReportDataFilter.weekly:
                filterName = 'Hàng tuần';
                break;
              case ReportDataFilter.biweekly:
                filterName = 'Hai tuần';
                break;
              case ReportDataFilter.monthly:
                filterName = 'Hàng tháng';
                break;
              case ReportDataFilter.yearly:
                filterName = 'Hàng năm';
                break;
            }
            return DropdownMenuItem<ReportDataFilter>(
              value: filter,
              child: Text(filterName, style: TextStyle(color: Colors.grey.shade700)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}