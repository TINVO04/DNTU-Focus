import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProjectDistributionChart extends StatelessWidget {
  const ProjectDistributionChart({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả
    final Map<String, dynamic> projectData = {
      'General': {'time': '15h 15m', 'percent': 35.0, 'color': Colors.green},
      'Pomodoro App': {'time': '8h 5m', 'percent': 20.0, 'color': Colors.red},
      'Flight App': {'time': '6h 10m', 'percent': 15.0, 'color': Colors.cyan},
      'Dating App': {'time': '4h 48m', 'percent': 10.0, 'color': Colors.pink},
      'Work Project': {'time': '4h 48m', 'percent': 12.0, 'color': Colors.orange},
      'AI Chatbot App': {'time': '3h 12m', 'percent': 8.0, 'color': Colors.blue},
    };

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
                child: PieChart(
                  PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Có thể thêm logic tương tác ở đây
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2, // Khoảng cách giữa các phần
                      centerSpaceRadius: 50, // Bán kính của lỗ ở giữa (donut)
                      sections: _getChartSections(projectData),
                      // Hiển thị tổng thời gian ở giữa
                      centerSpaceWidgets: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '39h 40m',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ]
                  ),
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
}