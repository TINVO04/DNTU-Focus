import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/core/utils/my_date_range.dart';
import 'package:moji_todo/features/report/data/report_repository.dart';
import 'package:moji_todo/features/report/domain/report_state.dart';
import 'package.dart';
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
        _reportRepository.getProjectTimeDistributionForRange(MyDateRange.getTodayRange()),
        _reportRepository.getProjectTimeDistributionForRange(MyDateRange.getCurrentWeekRange()),
        _reportRepository.getProjectTimeDistributionForRange(MyDateRange.getPreviousTwoWeeksRange()),
        _reportRepository.getProjectTimeDistributionForRange(MyDateRange.getCurrentMonthRange()),

        // Task Stats
        _reportRepository.getCompletedTasksCountForRange(MyDateRange.getTodayRange()),
        _report.getCompletedTasksCountForRange(MyDateRange.getCurrentWeekRange()),
        _reportRepository.getCompletedTasksCountForRange(MyDateRange.getPreviousTwoWeeksRange()),
        _reportRepository.getCompletedTasksCountForRange(MyDateRange.getCurrentMonthRange()),

        // Chart and List Data (với filter mặc định)
        _reportRepository.getProjectTimeDistributionForRange(MyDateRange.getCurrentWeekRange()),
        _reportRepository.getTaskFocusTime(MyDateRange.getPreviousTwoWeeksRange()), // Giả sử mặc định là 2 tuần
        _reportRepository.getFocusTimeChartData(MyDateRange.getPreviousTwoWeeksRange()),

        // Dữ liệu tra cứu
        _projectTagRepository.getProjects(),
        _projectTagRepository.getAllTasks(),
      ]);

      // Gán kết quả vào state
      emit(state.copyWith(
        status: ReportStatus.success,
        // Pomodoro
        focusTimeToday: Duration(seconds: (results[0] as Map<String?, int>).values.fold(0, (a, b) => a + b)),
        focusTimeThisWeek: Duration(seconds: (results[1] as Map<String?, int>).values.fold(0, (a, b) => a + b)),
        focusTimeThisTwoWeeks: Duration(seconds: (results[2] as Map<String?, int>).values.fold(0, (a, b) => a + b)),
        focusTimeThisMonth: Duration(seconds: (results[3] as Map<String?, int>).values.fold(0, (a, b) => a + b)),
        // Tasks
        tasksCompletedToday: results[4] as int,
        tasksCompletedThisWeek: results[5] as int,
        tasksCompletedThisTwoWeeks: results[6] as int,
        tasksCompletedThisMonth: results[7] as int,
        // Biểu đồ và danh sách
        projectTimeDistribution: results[8] as Map<String?, int>,
        taskFocusTime: results[9] as Map<String, int>,
        focusTimeChartData: results[10] as Map<DateTime, Map<String?, int>>,
        // Dữ liệu tra cứu
        allProjects: results[11] as List<ProjectModel>,
        allTasks: results[12] as List<TaskModel>,
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
      final newData = await _reportRepository.getProjectTimeDistributionForRange(range);

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
      final newData = await _reportRepository.getFocusTimeChartData(range as MyDateRange);

      emit(state.copyWith(status: ReportStatus.success, focusTimeChartData: newData));
    } catch (e) {
      emit(state.copyWith(status: ReportStatus.failure, errorMessage: e.toString()));
    }
  }

  // Helper để lấy khoảng thời gian từ filter
  DateTimeRange _getRangeFromFilter(ReportDataFilter filter) {
    switch (filter) {
      case ReportDataFilter.daily:
        return MyDateRange.getTodayRange();
      case ReportDataFilter.weekly:
        return MyDateRange.getCurrentWeekRange();
      case ReportDataFilter.biweekly:
        return MyDateRange.getPreviousTwoWeeksRange();
      case ReportDataFilter.monthly:
        return MyDateRange.getCurrentMonthRange();
      case ReportDataFilter.yearly:
        return MyDateRange.getCurrentYearRange();
    }
  }
}