import 'package:flutter/material.dart';
import 'package:moji_todo/features/report/domain/report_state.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';
import 'package:moji_todo/features/report/data/models/pomodoro_session_model.dart';
import '../widgets/focus_time_bar_chart.dart';
import '../widgets/pomodoro_records_chart.dart';
import '../widgets/summary_card.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

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
        'proj1': Duration(hours: 2),
        'proj2': Duration(hours: 1),
        'proj3': Duration(minutes: 30),
      },
      DateTime(now.year, now.month, now.day - 1): {
        'proj1': Duration(hours: 1),
        'proj2': Duration(hours: 2),
      },
      DateTime(now.year, now.month, now.day - 2): {
        'proj3': Duration(hours: 1, minutes: 15),
      },
    };

    return ReportState(
      status: ReportStatus.success,
      focusTimeToday: Duration(hours: 3, minutes: 30),
      focusTimeThisWeek: Duration(hours: 20),
      focusTimeThisTwoWeeks: Duration(hours: 35),
      focusTimeThisMonth: Duration(hours: 80),
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

    return SingleChildScrollView(
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
    );
  }

  Widget _buildSummaryCards(BuildContext context, ReportState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 16) / 2;

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

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
    );
  }

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