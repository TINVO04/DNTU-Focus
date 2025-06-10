import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';

class ProjectDistributionChart extends StatelessWidget {
  final Map<String?, Duration> distributionData;
  final List<Project> allProjects;

  const ProjectDistributionChart({
    super.key,
    required this.distributionData,
    required this.allProjects,
  });

  @override
  Widget build(BuildContext context) {
    if (distributionData.isEmpty) {
      return const SizedBox();
    }

    final totalSeconds =
        distributionData.values.fold<int>(0, (a, b) => a + b.inSeconds);

    final Map<String, Map<String, dynamic>> projectData = {};
    distributionData.forEach((projectId, duration) {
      final project = projectId != null
          ? allProjects.firstWhere(
              (p) => p.id == projectId,
              orElse: () => Project(id: projectId, name: 'Unknown', color: Colors.grey),
            )
          : Project(id: 'general', name: 'General', color: Colors.grey);

      final percent = totalSeconds > 0
          ? duration.inSeconds / totalSeconds * 100
          : 0.0;

      projectData[project.name] = {
        'time': _formatDuration(duration),
        'percent': percent,
        'color': project.color,
      };
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: <Widget>[
            // Phần biểu đồ tròn
            Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Có thể thêm logic tương tác ở đây
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: _getChartSections(projectData),
                      ),
                    ),
                    Text(
                      _formatDuration(Duration(seconds: totalSeconds)),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            // Phần chú thích (Legend)
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: projectData.entries.map((entry) {
                  return _buildIndicator(
                    color: entry.value['color'],
                    text: entry.key,
                    subtext: entry.value['time'],
                    percentage: entry.value['percent'],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper để tạo các phần cho biểu đồ
  List<PieChartSectionData> _getChartSections(Map<String, dynamic> data) {
    return data.entries.map((entry) {
      return PieChartSectionData(
        color: entry.value['color'],
        value: entry.value['percent'],
        // title: '${entry.value['percent'].toStringAsFixed(0)}%',
        showTitle: false, // Ẩn chữ trên các phần
        radius: 30,
      );
    }).toList();
  }

  // Helper để tạo một dòng chú thích
  Widget _buildIndicator({
    required Color color,
    required String text,
    required String subtext,
    required double percentage,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(2),
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

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
}