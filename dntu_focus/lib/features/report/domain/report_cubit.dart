import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/core/utils/my_date_range.dart';
import 'package:moji_todo/features/report/data/report_repository.dart';
import 'package:moji_todo/features/report/domain/report_state.dart';
import 'package:moji_todo/features/report/data/report_time_range.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';
import 'package:moji_todo/features/tasks/data/models/project_tag_repository.dart';
import 'package:moji_todo/features/tasks/data/task_repository.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _reportRepository;
  final ProjectTagRepository _projectTagRepository;
  final TaskRepository _taskRepository;

  ReportCubit(this._reportRepository, this._projectTagRepository, this._taskRepository)
      : super(const ReportState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      emit(state.copyWith(status: ReportStatus.loading));

      // Sử dụng Future.wait với danh sách Future
      final results = await Future.wait([
        // Pomodoro Stats
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.today), // Future<Duration>
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.thisWeek), // Future<Duration>
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.lastTwoWeeks), // Future<Duration>
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.thisMonth), // Future<Duration>
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.thisYear), // Future<Duration>

        // Task Stats
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.today), // Future<int>
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.thisWeek), // Future<int>
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.lastTwoWeeks), // Future<int>
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.thisMonth), // Future<int>
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.thisYear), // Future<int>

        // Chart and List Data (với filter mặc định)
        _reportRepository.getProjectTimeDistributionForRange(ReportTimeRange.thisWeek), // Future<Map<String?, Duration>>
        _reportRepository.getTaskFocusTime(ReportTimeRange.lastTwoWeeks), // Future<Map<String, Duration>>
        _reportRepository.getFocusTimeChartData(ReportTimeRange.lastTwoWeeks), // Future<Map<DateTime, Map<String?, Duration>>>

        // Dữ liệu tra cứu
        Future.value(_projectTagRepository.getProjects()), // Future<List<Project>>
        _taskRepository.getTasks(), // Future<List<Task>>
      ].map((future) => future as Future));

      // Ép kiểu an toàn từng phần tử
      final focusTimeToday = results[0] as Duration;
      final focusTimeThisWeek = results[1] as Duration;
      final focusTimeThisTwoWeeks = results[2] as Duration;
      final focusTimeThisMonth = results[3] as Duration;
      final focusTimeThisYear = results[4] as Duration;

      final tasksCompletedToday = results[5] as int;
      final tasksCompletedThisWeek = results[6] as int;
      final tasksCompletedThisTwoWeeks = results[7] as int;
      final tasksCompletedThisMonth = results[8] as int;
      final tasksCompletedThisYear = results[9] as int;

      final projectTimeDistribution = results[10] as Map<String?, Duration>;
      final taskFocusTime = results[11] as Map<String, Duration>;
      final focusTimeChartData = results[12] as Map<DateTime, Map<String?, Duration>>;

      // Kiểm tra và ép kiểu an toàn cho projects và tasks
      final projectsRaw = results[13];
      final tasksRaw = results[14];
      final projects = projectsRaw is List ? projectsRaw.cast<Project>() : [];
      final tasks = tasksRaw is List ? tasksRaw.cast<Task>() : [];

      // Gán kết quả vào state
      emit(state.copyWith(
        status: ReportStatus.success,
        // Pomodoro
        focusTimeToday: focusTimeToday,
        focusTimeThisWeek: focusTimeThisWeek,
        focusTimeThisTwoWeeks: focusTimeThisTwoWeeks,
        focusTimeThisMonth: focusTimeThisMonth,
        focusTimeThisYear: focusTimeThisYear,
        // Tasks
        tasksCompletedToday: tasksCompletedToday,
        tasksCompletedThisWeek: tasksCompletedThisWeek,
        tasksCompletedThisTwoWeeks: tasksCompletedThisTwoWeeks,
        tasksCompletedThisMonth: tasksCompletedThisMonth,
        tasksCompletedThisYear: tasksCompletedThisYear,
        // Biểu đồ và danh sách
        projectTimeDistribution: projectTimeDistribution,
        taskFocusTime: taskFocusTime,
        focusTimeChartData: focusTimeChartData,
        // Dữ liệu tra cứu
        allProjects: projects.isEmpty ? [] : projects,
        allTasks: tasks.isEmpty ? [] : tasks,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.failure,
        errorMessage: 'Failed to load data: ${e.toString()}',
      ));
    }
  }

  // Hàm để thay đổi bộ lọc cho biểu đồ phân bổ project
  Future<void> changeProjectDistributionFilter(ReportDataFilter filter) async {
    try {
      emit(state.copyWith(status: ReportStatus.loading, projectDistributionFilter: filter));

      final range = _getRangeFromFilter(filter);
      final newData = await _reportRepository.getProjectTimeDistributionForRange(range);

      emit(state.copyWith(
        status: ReportStatus.success,
        projectTimeDistribution: newData.isEmpty ? {} : newData,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.failure,
        errorMessage: 'Failed to load project distribution: ${e.toString()}',
      ));
    }
  }

  // Hàm để thay đổi bộ lọc cho biểu đồ cột
  Future<void> changeFocusTimeChartFilter(ReportDataFilter filter) async {
    try {
      emit(state.copyWith(status: ReportStatus.loading, focusTimeChartFilter: filter));

      final range = _getRangeFromFilter(filter);
      final newData = await _reportRepository.getFocusTimeChartData(range);

      emit(state.copyWith(
        status: ReportStatus.success,
        focusTimeChartData: newData.isEmpty ? {} : newData,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.failure,
        errorMessage: 'Failed to load chart data: ${e.toString()}',
      ));
    }
  }

  // Helper để lấy khoảng thời gian từ filter
  ReportTimeRange _getRangeFromFilter(ReportDataFilter filter) {
    switch (filter) {
      case ReportDataFilter.daily:
        return ReportTimeRange.today;
      case ReportDataFilter.weekly:
        return ReportTimeRange.thisWeek;
      case ReportDataFilter.biweekly:
        return ReportTimeRange.lastTwoWeeks;
      case ReportDataFilter.monthly:
        return ReportTimeRange.thisMonth;
      case ReportDataFilter.yearly:
        return ReportTimeRange.thisYear;
    }
  }
}