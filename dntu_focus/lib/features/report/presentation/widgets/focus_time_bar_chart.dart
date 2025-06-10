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

  // Helper để tìm project theo ID
  Project _findProjectById(String? projectId) {
    if (projectId == null) {
      return Project(id: 'general', name: 'General', color: Colors.grey.shade400);
    }
    return allProjects.firstWhere(
          (p) => p.id == projectId,
      orElse: () => Project(id: projectId, name: 'Unknown', color: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tìm giá trị thời gian tập trung lớn nhất trong tuần (tính bằng giờ)
    // để xác định maxY cho biểu đồ một cách linh hoạt.
    final double maxY = _calculateMaxY();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY, // Sử dụng maxY động
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
                    interval: maxY / 4, // Chia khoảng cho trục Y
                    getTitlesWidget: _leftTitles,
                  ),
                ),
              ),
              barGroups: _getBarGroups(),
            ),
          ),
        ),
      ),
    );
  }

  // Tính toán giá trị Y tối đa cho biểu đồ (tính bằng giờ)
  double _calculateMaxY() {
    if (chartData.isEmpty) return 7; // Giá trị mặc định nếu không có dữ liệu

    double maxHours = 0;
    for (var dailyEntry in chartData.values) {
      final totalSeconds = dailyEntry.values.fold<int>(0, (sum, d) => sum + d.inSeconds);
      final hours = totalSeconds / 3600;
      if (hours > maxHours) {
        maxHours = hours;
      }
    }
    // Làm tròn lên đến giờ chẵn gần nhất và thêm một chút đệm
    return (maxHours.ceil() == 0) ? 1 : maxHours.ceil().toDouble();
  }


  // Helper để tạo tiêu đề cho trục Y (bên trái)
  Widget _leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 12);
    // Chỉ hiển thị giá trị nguyên
    if (value % 1 != 0) return const SizedBox.shrink();
    // Không hiển thị giá trị 0
    if (value == 0) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text('${value.toInt()}h', style: style),
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
    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: text,
    );
  }

  // ===== ĐÃ SỬA: Dùng dữ liệu thật để tạo các cột biểu đồ =====
  List<BarChartGroupData> _getBarGroups() {
    // Sắp xếp dữ liệu theo ngày để đảm bảo thứ tự đúng
    final sortedKeys = chartData.keys.toList()..sort();
    final Map<int, Map<String?, Duration>> weeklyData = {};

    for (final date in sortedKeys) {
      // weekday trả về 1 cho Thứ Hai và 7 cho Chủ Nhật
      final dayIndex = date.weekday - 1;
      weeklyData[dayIndex] = chartData[date]!;
    }

    // Tạo danh sách 7 ngày trong tuần
    return List.generate(7, (dayIndex) {
      final dailyData = weeklyData[dayIndex];
      double currentY = 0;
      final rodStackItems = <BarChartRodStackItem>[];

      if (dailyData != null && dailyData.isNotEmpty) {
        // Sắp xếp các project trong ngày theo thời gian để màu sắc ổn định
        final sortedProjects = dailyData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        for (final entry in sortedProjects) {
          final projectId = entry.key;
          final duration = entry.value;
          final project = _findProjectById(projectId);

          final valueInHours = duration.inSeconds / 3600.0;
          rodStackItems.add(
            BarChartRodStackItem(
              currentY,
              currentY + valueInHours,
              project.color,
            ),
          );
          currentY += valueInHours;
        }
      }

      return BarChartGroupData(
        x: dayIndex,
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