import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/report/domain/report_cubit.dart';
import 'package:moji_todo/features/report/domain/report_state.dart';
import 'package:moji_todo/features/report/presentation/tab/pomodoro_report_tab.dart';
import 'package:moji_todo/features/report/presentation/tab/pomodoro_report_tab_demo.dart';
import 'package:moji_todo/features/report/presentation/tab/tasks_report_tab.dart';
import 'package:moji_todo/features/report/presentation/tab/tasks_report_tab_demo.dart';
import 'package:moji_todo/features/tasks/data/models/project_tag_repository.dart';
import 'package:moji_todo/features/tasks/data/task_repository.dart';
import '../data/report_repository.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp ReportCubit cho các widget con của nó
    return BlocProvider(
      create: (context) => ReportCubit(
        context.read<ReportRepository>(),
        context.read<ProjectTagRepository>(),
        context.read<TaskRepository>(),
      ),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
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
                onPressed: () {},
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
          // Dùng BlocBuilder để lắng nghe và xây dựng lại UI theo state
          body: BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              // Nếu đang tải dữ liệu lần đầu, hiển thị vòng xoay
              if (state.status == ReportStatus.loading && state.focusTimeThisWeek == Duration.zero) {
                return const Center(child: CircularProgressIndicator());
              }
              // Nếu có lỗi, hiển thị thông báo
              if (state.status == ReportStatus.failure) {
                return Center(
                    child: Text(state.errorMessage ?? 'Failed to load report data.'));
              }
              // Nếu thành công, hiển thị TabBarView
              return const TabBarView(
                children: [
                  PomodoroReportTabDemo(),
                  TasksReportTabDemo(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}