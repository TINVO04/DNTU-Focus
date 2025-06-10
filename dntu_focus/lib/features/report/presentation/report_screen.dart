import 'package:flutter/material.dart';
import 'package:moji_todo/features/report/presentation/tab/pomodoro_report_tab.dart';
import 'package:moji_todo/features/report/presentation/tab/tasks_report_tab.dart';


class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          // Tắt nút back vì đây là màn hình chính trong BottomNavBar
          automaticallyImplyLeading: false,
          title: Text(
            'Report',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                // Logic cho nút 3 chấm (ví dụ: mở menu, filter...)
              },
              icon: const Icon(Icons.more_vert),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: 'Pomodoro'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        // TabBarView để hiển thị nội dung tương ứng cho mỗi tab
        body: const TabBarView(
          children: [
            // Đây là 2 widget chứa nội dung cho mỗi tab.
            // Chúng ta sẽ tạo chúng ở các bước tiếp theo.
            PomodoroReportTab(),
            TasksReportTab(),
          ],
        ),
      ),
    );
  }
}