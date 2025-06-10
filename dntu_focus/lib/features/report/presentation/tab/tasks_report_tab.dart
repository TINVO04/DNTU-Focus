import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/features/report/presentation/widgets/focus_time_bar_chart.dart';

import '../widgets/summary_card.dart';

class TasksReportTab extends StatelessWidget {
  const TasksReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildSectionHeader(context, title: 'Focus Time', filter: 'Tasks'),
          const SizedBox(height: 16),
          _buildTaskFocusList(),
          const SizedBox(height: 24),
          _buildSectionHeader(context, title: 'Project Time Disctribution', filter: 'Weekly'),
          const SizedBox(height: 16),
          // Placeholder cho biểu đồ Donut
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Biểu đồ Donut sẽ được hiển thị ở đây',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, title: 'Task Chart', filter: 'Biweekly'),
          const SizedBox(height: 16),
          // Placeholder cho biểu đồ cột
          const FocusTimeBarChart(),
        ],
      ),
    );
  }

// bên trong file tasks_report_tab.dart
  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: const [
        SummaryCard(value: '2', label: 'Task Completed Today'),
        SummaryCard(value: '25', label: 'Task Completed This Week'),
        SummaryCard(value: '58', label: 'Task Completed This Two...'),
        SummaryCard(value: '124', label: 'Task Completed This Month'),
      ],
    );
  }

  // Widget cho một thẻ thống kê
  Widget _buildSummaryCard(String value, String label) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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

  // Giao diện cho danh sách focus time theo task
  Widget _buildTaskFocusList() {
    // Dữ liệu giả
    final tasks = [
      {'title': 'UI/UX Design Research', 'time': '7h 25m', 'progress': 0.9, 'color': Colors.green},
      {'title': 'Design User Interface (UI)', 'time': '6h 50m', 'progress': 0.8, 'color': Colors.red},
      {'title': 'Create a Design Wireframe', 'time': '5h 40m', 'progress': 0.7, 'color': Colors.blue},
      {'title': 'Market Research and Analysis', 'time': '4h 45m', 'progress': 0.6, 'color': Colors.brown},
      {'title': 'Write a Report & Proposal', 'time': '4h 30m', 'progress': 0.5, 'color': Colors.purple},
      {'title': 'Write a Research Paper', 'time': '4h 5m', 'progress': 0.4, 'color': Colors.orange},
      {'title': 'Read Articles', 'time': '3h 40m', 'progress': 0.3, 'color': Colors.cyan},
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: tasks.map((task) => _buildFocusTimeTaskItem(
            title: task['title'] as String,
            time: task['time'] as String,
            progress: task['progress'] as double,
            color: task['color'] as Color,
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildFocusTimeTaskItem({
    required String title,
    required String time,
    required double progress,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(time, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}