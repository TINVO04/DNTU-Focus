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
    if (duration.inMinutes == 0) return '0m';
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
    final state = context.watch<ReportCubit>().state;
    final cubit = context.read<ReportCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(state),
          const SizedBox(height: 24),
          _buildSectionHeader(context, title: 'Focus Time', filterText: 'Tasks'),
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
          _buildSectionHeader(context, title: 'Task Chart', filterText: 'Biweekly'),
          const SizedBox(height: 16),
          FocusTimeBarChart(
            chartData: state.focusTimeChartData,
            allProjects: state.allProjects,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReportState state) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        // ===== SỬA LỖI: Chỉ giữ lại 4 thẻ để phù hợp với layout 2 cột =====
        SummaryCard(value: state.tasksCompletedToday.toString(), label: 'Task Completed Today'),
        SummaryCard(value: state.tasksCompletedThisWeek.toString(), label: 'Task Completed This Week'),
        SummaryCard(value: state.tasksCompletedThisTwoWeeks.toString(), label: 'Task Completed This Two...'),
        SummaryCard(value: state.tasksCompletedThisMonth.toString(), label: 'Task Completed This Month'),
        // Bỏ thẻ "This Year" đi để tránh làm vỡ layout
        // SummaryCard(value: state.tasksCompletedThisYear.toString(), label: 'Task Completed This Year'),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, String? filterText, Widget? filterWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        filterWidget ??
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text(filterText ?? '', style: TextStyle(color: Colors.grey.shade700)),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            )
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
      child: DropdownButton<ReportDataFilter>(
        value: value,
        underline: const SizedBox.shrink(),
        items: ReportDataFilter.values.map((ReportDataFilter filter) {
          return DropdownMenuItem<ReportDataFilter>(
            value: filter,
            child: Text(filter.name[0].toUpperCase() + filter.name.substring(1)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTaskFocusList(ReportState state) {
    if (state.taskFocusTime.isEmpty) {
      return const Card(
        elevation: 0,
        child: Padding(
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              orElse: () => Project(id: '', name: 'Unknown Project', color: Colors.grey),
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