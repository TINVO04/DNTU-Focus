import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../widgets/focus_time_bar_chart.dart';
import '../widgets/summary_card.dart';

class PomodoroReportTab extends StatelessWidget {
  const PomodoroReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildSectionHeader(context, title: 'Pomodoro Records', filter: 'Weekly'),
          const SizedBox(height: 16),
          _buildPomodoroHeatmap(),
          const SizedBox(height: 24),
          _buildSectionHeader(context, title: 'Focus Time Goal', filter: 'Monthly'),
          const SizedBox(height: 16),
          _buildFocusGoalCalendar(context),
          const SizedBox(height: 24),
          _buildSectionHeader(context, title: 'Focus Time Chart', filter: 'Biweekly'),
          const SizedBox(height: 16),
          // ===== ĐÃ SỬA LỖI Ở ĐÂY =====
          // Toàn bộ Container cũ được thay bằng dòng này
          const FocusTimeBarChart(),
        ],
      ),
    );
  }

  // Widget cho các thẻ thống kê
  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: const [
        SummaryCard(value: '2h 5m', label: 'Focus Time Today'),
        SummaryCard(value: '39h 35m', label: 'Focus Time This Week'),
        SummaryCard(value: '79h 10m', label: 'Focus Time This Two Weeks'),
        SummaryCard(value: '160h 25m', label: 'Focus Time This Month'),
      ],
    );
  }

  // Widget cho tiêu đề của mỗi phần
  Widget _buildSectionHeader(BuildContext context, {required String title, required String filter}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        // Dropdown giả
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Text(filter, style: TextStyle(color: Colors.grey.shade700)),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        )
      ],
    );
  }

  // Giao diện giả cho Pomodoro Heatmap
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

  // Giao diện cho Lịch
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
            defaultTextStyle: const TextStyle(color: Colors.black),
            weekendTextStyle: const TextStyle(color: Colors.black),
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
          selectedDayPredicate: (day) {
            return day.day % 3 == 0;
          },
        ),
      ),
    );
  }
}