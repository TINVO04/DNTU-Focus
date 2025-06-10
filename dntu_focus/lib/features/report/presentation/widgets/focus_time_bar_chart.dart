import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';

class FocusTimeBarChart extends StatelessWidget {
  final Map<DateTime, Map<String?, Duration>> chartData;
  final List<Project> allProjects;

  const FocusTimeBarChart({
    super.key,
    required this.chartData,
    required this.allProjects,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 7,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
                left: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: _bottomTitles,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: _leftTitles,
                ),
              ),
            ),
            barGroups: _getBarGroups(),
          ),
        ),
      ),
    );
  }

  // Helper để tạo tiêu đề cho trục Y (bên trái)
  Widget _leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 12);
    String text;
    if (value == 0 || value == 7) {
      text = '';
    } else if (value % 2 != 0){
      text = '';
    }
    else {
      text = value.toInt().toString();
    }
    // ===== ĐÃ SỬA LỖI Ở ĐÂY =====
    // Không cần truyền `axisSide` nữa
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(text, style: style),
    );
  }

  // Helper để tạo tiêu đề cho trục X (bên dưới)
  Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 12);
    Widget text;
    switch (value.toInt()) {
      case 0: text = const Text('Mo', style: style); break;
      case 1: text = const Text('Tu', style: style); break;
      case 2: text = const Text('We', style: style); break;
      case 3: text = const Text('Th', style: style); break;
      case 4: text = const Text('Fr', style: style); break;
      case 5: text = const Text('Sa', style: style); break;
      case 6: text = const Text('Su', style: style); break;
      default: text = const Text('', style: style); break;
    }
    // ===== ĐÃ SỬA LỖI Ở ĐÂY =====
    // Không cần truyền `axisSide` nữa
    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: text,
    );
  }

  // Dữ liệu giả cho các cột biểu đồ (Không thay đổi)
  List<BarChartGroupData> _getBarGroups() {
    final List<List<double>> weeklyData = [
      [1.0, 1.5, 1.5], [2.0, 1.0, 2.0], [1.0, 0.5, 1.0],
      [1.5, 1.0, 1.8], [1.2, 1.3, 2.5, 1.0], [2.5, 1.5, 1.0],
      [2.0, 2.0, 2.5],
    ];
    final List<Color> projectColors = [
      Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.purple, Colors.brown,
    ];

    return List.generate(weeklyData.length, (index) {
      final dailyStack = weeklyData[index];
      double currentY = 0;
      final rodStackItems = <BarChartRodStackItem>[];
      for (int i = 0; i < dailyStack.length; i++) {
        final value = dailyStack[i];
        rodStackItems.add(
          BarChartRodStackItem(
            currentY,
            currentY + value,
            projectColors[i % projectColors.length],
          ),
        );
        currentY += value;
      }
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: currentY,
            rodStackItems: rodStackItems,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }
}