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

import '../data/models/pomodoro_session_model.dart';

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
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.today), // 0
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.thisWeek), // 1
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.lastTwoWeeks), // 2
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.thisMonth), // 3
        _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.thisYear), // 4

        // Task Stats
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.today), // 5
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.thisWeek), // 6
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.lastTwoWeeks), // 7
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.thisMonth), // 8
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.thisYear), // 9

        // Chart and List Data (với filter mặc định)
        _reportRepository.getProjectTimeDistributionForRange(ReportTimeRange.thisWeek), // 10
        _reportRepository.getTaskFocusTime(ReportTimeRange.lastTwoWeeks), // 11
        _reportRepository.getFocusTimeChartData(ReportTimeRange.lastTwoWeeks), // 12

        // Heatmap and goal data
        _reportRepository.getPomodoroRecordsHeatmapData(range: ReportTimeRange.lastTwoWeeks), // 13
        _reportRepository.getDaysMeetingFocusGoal(ReportTimeRange.lastTwoWeeks, const Duration(hours: 2)), // 14

        // Dữ liệu tra cứu
        Future.value(_projectTagRepository.getProjects()), // 15
        _taskRepository.getTasks(), // 16
      ].map((future) => future.catchError((_) => null))); // Thêm catchError để ngăn một lỗi làm hỏng tất cả

      // ===== SỬA LỖI: Ép kiểu an toàn với giá trị mặc định =====
      final focusTimeToday = (results[0] as Duration?) ?? Duration.zero;
      final focusTimeThisWeek = (results[1] as Duration?) ?? Duration.zero;
      final focusTimeThisTwoWeeks = (results[2] as Duration?) ?? Duration.zero;
      final focusTimeThisMonth = (results[3] as Duration?) ?? Duration.zero;
      final focusTimeThisYear = (results[4] as Duration?) ?? Duration.zero;

      final tasksCompletedToday = (results[5] as int?) ?? 0;
      final tasksCompletedThisWeek = (results[6] as int?) ?? 0;
      final tasksCompletedThisTwoWeeks = (results[7] as int?) ?? 0;
      final tasksCompletedThisMonth = (results[8] as int?) ?? 0;
      final tasksCompletedThisYear = (results[9] as int?) ?? 0;

      final projectTimeDistribution = (results[10] as Map<String?, Duration>?) ?? {};
      final taskFocusTime = (results[11] as Map<String, Duration>?) ?? {};
      final focusTimeChartData = (results[12] as Map<DateTime, Map<String?, Duration>>?) ?? {};
      final heatmapData = (results[13] as Map<DateTime, List<PomodoroSessionRecordModel>>?) ?? {};
      final goalDays = (results[14] as Set<DateTime>?) ?? {};

      final projects = (results[15] as List<Project>?) ?? [];
      final tasks = (results[16] as List<Task>?) ?? [];

      // Gán kết quả vào state
      emit(state.copyWith(
        status: ReportStatus.success,
        focusTimeToday: focusTimeToday,
        focusTimeThisWeek: focusTimeThisWeek,
        focusTimeThisTwoWeeks: focusTimeThisTwoWeeks,
        focusTimeThisMonth: focusTimeThisMonth,
        focusTimeThisYear: focusTimeThisYear,
        tasksCompletedToday: tasksCompletedToday,
        tasksCompletedThisWeek: tasksCompletedThisWeek,
        tasksCompletedThisTwoWeeks: tasksCompletedThisTwoWeeks,
        tasksCompletedThisMonth: tasksCompletedThisMonth,
        tasksCompletedThisYear: tasksCompletedThisYear,
        projectTimeDistribution: projectTimeDistribution,
        taskFocusTime: taskFocusTime,
        focusTimeChartData: focusTimeChartData,
        pomodoroHeatmapData: heatmapData,
        focusGoalMetDays: goalDays,
        allProjects: projects,
        allTasks: tasks,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.failure,
        errorMessage: 'Failed to load data: ${e.toString()}',
      ));
    }
  }

  // Các hàm thay đổi filter không thay đổi
  Future<void> changeProjectDistributionFilter(ReportDataFilter filter) async {
    try {
      emit(state.copyWith(status: ReportStatus.loading, projectDistributionFilter: filter));
      final range = _getRangeFromFilter(filter);
      final newData = await _reportRepository.getProjectTimeDistributionForRange(range);
      emit(state.copyWith(
        status: ReportStatus.success,
        projectTimeDistribution: newData,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.failure,
        errorMessage: 'Failed to load project distribution: ${e.toString()}',
      ));
    }
  }

  Future<void> changeFocusTimeChartFilter(ReportDataFilter filter) async {
    try {
      emit(state.copyWith(status: ReportStatus.loading, focusTimeChartFilter: filter));
      final range = _getRangeFromFilter(filter);
      final newData = await _reportRepository.getFocusTimeChartData(range);
      emit(state.copyWith(
        status: ReportStatus.success,
        focusTimeChartData: newData,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportStatus.failure,
        errorMessage: 'Failed to load chart data: ${e.toString()}',
      ));
    }
  }

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