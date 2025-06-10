import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/core/utils/my_date_range.dart';
import 'package:moji_todo/features/report/data/report_repository.dart';
import 'package:moji_todo/features/report/domain/report_state.dart';
import 'package:moji_todo/features/report/data/report_time_range.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';
import 'package:moji_todo/features/tasks/data/models/project_tag_repository.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _reportRepository;
  final ProjectTagRepository _projectTagRepository;

  ReportCubit(this._reportRepository, this._projectTagRepository)
      : super(const ReportState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      emit(state.copyWith(status: ReportStatus.loading));

      // Sử dụng Future.wait để tải nhiều dữ liệu cùng lúc cho hiệu quả
      final results = await Future.wait([
        // Pomodoro Stats
        _reportRepository.getProjectTimeDistributionForRange(
            ReportTimeRange.today),
        _reportRepository.getProjectTimeDistributionForRange(
            ReportTimeRange.thisWeek),
        _reportRepository.getProjectTimeDistributionForRange(
            ReportTimeRange.lastTwoWeeks),
        _reportRepository.getProjectTimeDistributionForRange(
            ReportTimeRange.thisMonth),

        // Task Stats
        _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.today),
        _reportRepository.getCompletedTasksCountForRange(
            ReportTimeRange.thisWeek),
        _reportRepository.getCompletedTasksCountForRange(
            ReportTimeRange.lastTwoWeeks),
        _reportRepository.getCompletedTasksCountForRange(
            ReportTimeRange.thisMonth),

        // Chart and List Data (với filter mặc định)
        _reportRepository.getProjectTimeDistributionForRange(
            ReportTimeRange.thisWeek),
        _reportRepository.getTaskFocusTime(ReportTimeRange.lastTwoWeeks), // Giả sử mặc định là 2 tuần
        _reportRepository.getFocusTimeChartData(ReportTimeRange.lastTwoWeeks),

        // Dữ liệu tra cứu
        _projectTagRepository.getProjects(),
        _projectTagRepository.getAllTasks(),
      ]);

      // Gán kết quả vào state
      emit(state.copyWith(
        status: ReportStatus.success,
        // Pomodoro
        focusTimeToday: (results[0] as Map<String?, Duration>).values.fold(Duration.zero, (a, b) => a + b),
        focusTimeThisWeek: (results[1] as Map<String?, Duration>).values.fold(Duration.zero, (a, b) => a + b),
        focusTimeThisTwoWeeks: (results[2] as Map<String?, Duration>).values.fold(Duration.zero, (a, b) => a + b),
        focusTimeThisMonth: (results[3] as Map<String?, Duration>).values.fold(Duration.zero, (a, b) => a + b),
        // Tasks
        tasksCompletedToday: results[4] as int,
        tasksCompletedThisWeek: results[5] as int,
        tasksCompletedThisTwoWeeks: results[6] as int,
        tasksCompletedThisMonth: results[7] as int,
        // Biểu đồ và danh sách
        projectTimeDistribution: results[8] as Map<String?, Duration>,
        taskFocusTime: results[9] as Map<String, Duration>,
        focusTimeChartData: results[10] as Map<DateTime, Map<String?, Duration>>,
        // Dữ liệu tra cứu
        allProjects: results[11] as List<Project>,
        allTasks: results[12] as List<Task>,
      ));

    } catch (e) {
      emit(state.copyWith(status: ReportStatus.failure, errorMessage: e.toString()));
    }
  }

  // Hàm để thay đổi bộ lọc cho biểu đồ phân bổ project
  Future<void> changeProjectDistributionFilter(ReportDataFilter filter) async {
    try {
      emit(state.copyWith(status: ReportStatus.loading, projectDistributionFilter: filter));

      final range = _getRangeFromFilter(filter);
      final newData =
          await _reportRepository.getProjectTimeDistributionForRange(range);

      emit(state.copyWith(status: ReportStatus.success, projectTimeDistribution: newData));
    } catch (e) {
      emit(state.copyWith(status: ReportStatus.failure, errorMessage: e.toString()));
    }
  }

  // Hàm để thay đổi bộ lọc cho biểu đồ cột
  Future<void> changeFocusTimeChartFilter(ReportDataFilter filter) async {
    try {
      emit(state.copyWith(status: ReportStatus.loading, focusTimeChartFilter: filter));

      final range = _getRangeFromFilter(filter);
      final newData = await _reportRepository.getFocusTimeChartData(range);

      emit(state.copyWith(status: ReportStatus.success, focusTimeChartData: newData));
    } catch (e) {
      emit(state.copyWith(status: ReportStatus.failure, errorMessage: e.toString()));
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
        return ReportTimeRange.thisMonth;
    }
  }
}