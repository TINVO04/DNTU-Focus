import 'package:flutter/material.dart';
import 'package:moji_todo/features/report/domain/report_state.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';
import '../widgets/project_distribution_chart.dart';
import '../widgets/summary_card.dart';
import '../widgets/task_focus_list_item.dart';
import '../widgets/focus_time_bar_chart.dart';

class TasksReportTabDemo extends StatelessWidget {
  const TasksReportTabDemo({super.key});

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
      Task(id: 'task4', title: 'Sửa lỗi', projectId: 'proj1'),
    ];

    final projectTimeDistribution = {
      'proj1': Duration(hours: 10),
      'proj2': Duration(hours: 5),
      'proj3': Duration(hours: 3),
    };

    final taskFocusTime = {
      'task1': Duration(hours: 4),
      'task2': Duration(hours: 3),
      'task3': Duration(hours: 2),
      'task4': Duration(hours: 1, minutes: 30),
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
      tasksCompletedToday: 3,
      tasksCompletedThisWeek: 15,
      tasksCompletedThisMonth: 40,
      tasksCompletedThisYear: 200,
      projectTimeDistribution: projectTimeDistribution,
      taskFocusTime: taskFocusTime,
      focusTimeChartData: focusTimeChartData,
      allProjects: projects,
      allTasks: tasks,
      projectDistributionFilter: ReportDataFilter.weekly,
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
          _buildSectionHeader(context, title: 'Thời gian tập trung theo nhiệm vụ'),
          const SizedBox(height: 16),
          _buildTaskFocusList(state),
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            title: 'Phân bổ thời gian dự án',
            filterWidget: _buildFilterDropdown(
              context,
              value: state.projectDistributionFilter,
              onChanged: (filter) {},
            ),
          ),
          const SizedBox(height: 16),
          ProjectDistributionChart(
            distributionData: state.projectTimeDistribution,
            allProjects: state.allProjects,
          ),
          const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ReportState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 32 - 16) / 2;

    final cards = [
      SummaryCard(value: state.tasksCompletedToday.toString(), label: 'Nhiệm vụ hoàn thành hôm nay'),
      SummaryCard(value: state.tasksCompletedThisWeek.toString(), label: 'Nhiệm vụ tuần này'),
      SummaryCard(value: state.tasksCompletedThisMonth.toString(), label: 'Nhiệm vụ tháng này'),
      SummaryCard(value: state.tasksCompletedThisYear.toString(), label: 'Nhiệm vụ năm nay'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards.map((card) => SizedBox(width: cardWidth, child: card)).toList(),
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
              child: Text(filterName),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTaskFocusList(ReportState state) {
    if (state.taskFocusTime.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text("Không có nhiệm vụ tập trung trong khoảng thời gian này.")),
        ),
      );
    }

    final sortedTasks = state.taskFocusTime.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxDuration = sortedTasks.first.value.inSeconds.toDouble();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: sortedTasks.map((entry) {
            final taskId = entry.key;
            final duration = entry.value;
            final task = state.allTasks.firstWhere(
                  (t) => t.id == taskId,
              orElse: () => Task(id: '?', title: 'Nhiệm vụ không xác định'),
            );
            final project = task.projectId != null
                ? state.allProjects.firstWhere(
                  (p) => p.id == task.projectId,
              orElse: () => Project(id: '', name: 'Không xác định', color: Colors.grey),
            )
                : null;

            return TaskFocusListItem(
              title: task.title ?? 'Nhiệm vụ không xác định',
              time: _formatDuration(duration),
              progress: maxDuration > 0 ? duration.inSeconds / maxDuration : 0,
              color: project?.color ?? Colors.grey,
            );
          }).toList(),
        ),
      ),
    );
  }
}