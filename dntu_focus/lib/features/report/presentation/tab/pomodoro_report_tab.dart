import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/report/domain/report_cubit.dart';
import 'package:moji_todo/features/report/domain/report_state.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/focus_time_bar_chart.dart';
import '../widgets/summary_card.dart';

class PomodoroReportTab extends StatelessWidget {
  const PomodoroReportTab({super.key});

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(state),
          const SizedBox(height: 24),
          _buildSectionHeader(context, title: 'Pomodoro Records', filterText: 'Weekly'),
          const SizedBox(height: 16),
          _buildPomodoroHeatmap(),
          const SizedBox(height: 24),
          _buildSectionHeader(context, title: 'Focus Time Goal', filterText: 'Monthly'),
          const SizedBox(height: 16),
          _buildFocusGoalCalendar(context),
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            title: 'Focus Time Chart',
            filterWidget: _buildFilterDropdown(
              context,
              value: state.focusTimeChartFilter,
              onChanged: (filter) {
                if (filter != null) {
                  context.read<ReportCubit>().changeFocusTimeChartFilter(filter);
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

  Widget _buildPomodoroHeatmap() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: const Center(
        child: Text(
          'Heatmap sẽ được hiển thị ở đây',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFocusGoalCalendar(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: DateTime.now(),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor, width: 2),
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(color: Theme.of(context).primaryColor),
          ),
          selectedDayPredicate: (day) => day.day % 3 == 0,
        ),
      ),
    );
  }
}