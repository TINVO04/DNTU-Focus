import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/report/domain/report_cubit.dart';
import 'package:moji_todo/features/tasks/data/models/project_tag_repository.dart';
import '../data/report_repository.dart';

// Import các màn hình tab sẽ tạo ở bước tiếp theo
// import 'pomodoro_report_tab.dart';
// import 'tasks_report_tab.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportCubit(
        ReportRepository(),
        // Cung cấp ProjectTagRepository từ context nếu có, hoặc tạo mới
        context.read<ProjectTagRepository>(),
      ),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false, // Tắt nút back tự động
            title: Text(
              'Report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            centerTitle: true,
            bottom: TabBar(
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).textTheme.titleLarge?.color,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Pomodoro'),
                Tab(text: 'Tasks'),
              ],
            ),
          ),
          body: BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              if (state.status == ReportStatus.loading && state.allProjects.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == ReportStatus.failure) {
                return Center(child: Text(state.errorMessage ?? 'Failed to load data'));
              }

              // Chúng ta sẽ tạo 2 file này ở bước tiếp theo
              return const TabBarView(
                children: [
                  // Center(child: Text("Pomodoro Tab - Sắp ra mắt")), // Tạm thời
                  // Center(child: Text("Tasks Tab - Sắp ra mắt")), // Tạm thời
                  // PomodoroReportTab(), // Sẽ thay thế sau
                  // TasksReportTab(), // Sẽ thay thế sau
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}