import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/report/domain/report_cubit.dart';
import 'package:moji_todo/features/report/domain/report_state.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';
import '../widgets/project_distribution_chart.dart';
import '../widgets/summary_card.dart';
import '../widgets/task_focus_list_item.dart';
import '../widgets/focus_time_bar_chart.dart';

class TasksReportTab extends StatelessWidget {
  const TasksReportTab({super.key});

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) return '0m';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    String result = '';
    if (hours > 0) {
      result += '${hours}h ';
    }
    if (minutes > 0) {
      result += '${minutes}m';
    }
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportCubit, ReportState>(
      builder: (context, state) {
        final cubit = context.read<ReportCubit>();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(context, state), // Đã được sửa để dùng Wrap
              const SizedBox(height: 24),
              _buildSectionHeader(context, title: 'Focus Time by Task'),
              const SizedBox(height: 16),
              _buildTaskFocusList(state),
              const SizedBox(height: 24),
              _buildSectionHeader(
                context,
                title: 'Project Time Distribution',
                filterWidget: _buildFilterDropdown(
                  context,
                  value: state.projectDistributionFilter,
                  onChanged: (filter) {
                    if (filter != null) {
                      cubit.changeProjectDistributionFilter(filter);
                    }
                  },
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
                title: 'Focus Time Chart',
                filterWidget: _buildFilterDropdown(
                  context,
                  value: state.focusTimeChartFilter,
                  onChanged: (filter) {
                    if (filter != null) {
                      cubit.changeFocusTimeChartFilter(filter);
                    }
                  },
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
      },
    );
  }

  // ===== SỬA LỖI: THAY THẾ GRIDVIEW BẰNG WRAP =====
  Widget _buildSummaryCards(BuildContext context, ReportState state) {
    // Lấy chiều rộng màn hình để tính toán chiều rộng cho mỗi card
    final screenWidth = MediaQuery.of(context).size.width;
    // Tổng padding ngang của màn hình là 16*2=32. Khoảng cách giữa 2 card là 16.
    // Vậy chiều rộng mỗi card = (rộng màn hình - padding - khoảng cách) / 2
    final cardWidth = (screenWidth - 32 - 16) / 2;

    final List<Widget> cards = [
      SummaryCard(
          value: state.tasksCompletedToday.toString(),
          label: 'Tasks Completed Today'),
      SummaryCard(
          value: state.tasksCompletedThisWeek.toString(),
          label: 'Tasks This Week'),
      SummaryCard(
          value: state.tasksCompletedThisMonth.toString(),
          label: 'Tasks This Month'),
      SummaryCard(
          value: state.tasksCompletedThisYear.toString(),
          label: 'Tasks This Year'),
    ];

    return Wrap(
      spacing: 16, // Khoảng cách theo chiều ngang
      runSpacing: 16, // Khoảng cách theo chiều dọc khi xuống dòng
      children: cards.map((card) {
        return SizedBox(
          width: cardWidth,
          child: card,
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(BuildContext context,
      {required String title, Widget? filterWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (filterWidget != null) filterWidget,
      ],
    );
  }

  Widget _buildFilterDropdown(BuildContext context,
      {required ReportDataFilter value,
        required void Function(ReportDataFilter?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReportDataFilter>(
          value: value,
          items: ReportDataFilter.values.map((ReportDataFilter filter) {
            final filterName =
                filter.name[0].toUpperCase() + filter.name.substring(1);
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
            borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text("No focused tasks in this period.")),
        ),
      );
    }

    final sortedTasks = state.taskFocusTime.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final double maxDuration = sortedTasks.first.value.inSeconds.toDouble();

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
              orElse: () => Task(id: '?', title: 'Unknown Task'),
            );
            final project = task.projectId != null
                ? state.allProjects.firstWhere(
                  (p) => p.id == task.projectId,
              orElse: () =>
                  Project(id: '', name: 'Unknown', color: Colors.grey),
            )
                : null;

            return TaskFocusListItem(
              title: task.title ?? 'Unknown Task',
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