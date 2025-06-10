import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart'; // CẦN CHO ReportState
import 'package:flutter/material.dart';
import '../data/report_repository.dart';
import '../data/models/pomodoro_session_model.dart'; // CẦN CHO ReportState
import '../../tasks/data/models/project_model.dart';    // CẦN CHO ReportState
import '../../tasks/data/models/project_tag_repository.dart';
import '../data/report_time_range.dart';

part 'report_state.dart'; // Dòng này giữ nguyên

class ReportCubit extends Cubit<ReportState> {
  final ReportRepository _reportRepository;
  final ProjectTagRepository _projectTagRepository; // To get all projects for names/colors

  ReportCubit(this._reportRepository, this._projectTagRepository) : super(const ReportState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchAllProjects(); // Fetch projects first
    await loadPomodoroData();
    await loadTasksData();
  }

  Future<void> _fetchAllProjects() async {
    try {
      final projects = _projectTagRepository.getProjects(); // Assuming this gets all non-archived projects for the user
      emit(state.copyWith(allProjects: projects));
    } catch (e) {
      emit(state.copyWith(status: ReportStatus.failure, errorMessage: 'Failed to load projects: $e'));
    }
  }


  Future<void> loadPomodoroData({
    ReportDataFilter? recordFilter,
    ReportDataFilter? goalFilter,
    ReportDataFilter? chartFilter,
  }) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final focusToday = await _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.today);
      final focusWeek = await _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.thisWeek);
      final focusTwoWeeks = await _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.lastTwoWeeks);
      final focusMonth = await _reportRepository.getTotalFocusTimeForRange(ReportTimeRange.thisMonth);

      // For Pomodoro Records, use the selected filter or default
      final currentRecordFilter = recordFilter ?? state.pomodoroRecordFilter;
      final heatmapData = await _reportRepository.getPomodoroRecordsHeatmapData(
        daysToGoBack: _daysForFilter(currentRecordFilter), // You'll need a helper for this
      );

      // For Focus Time Goal, use the selected filter or default
      final currentGoalFilter = goalFilter ?? state.focusTimeGoalFilter;
      final dailyGoal = const Duration(hours: 1); // Example: Make this configurable later
      final metGoalDays = await _reportRepository.getDaysMeetingFocusGoal(_mapFilterToRange(currentGoalFilter), dailyGoal);

      // For Focus Time Chart, use the selected filter or default
      final currentChartFilter = chartFilter ?? state.focusTimeChartFilter;
      final chartData = await _reportRepository.getFocusTimeChartData(_mapFilterToRange(currentChartFilter));

      emit(state.copyWith(
        status: ReportStatus.success,
        focusTimeToday: focusToday,
        focusTimeThisWeek: focusWeek,
        focusTimeLastTwoWeeks: focusTwoWeeks,
        focusTimeThisMonth: focusMonth,
        pomodoroRecordsHeatmap: heatmapData,
        daysMeetingFocusGoal: metGoalDays,
        focusTimeChartData: chartData,
        pomodoroRecordFilter: currentRecordFilter,
        focusTimeGoalFilter: currentGoalFilter,
        focusTimeChartFilter: currentChartFilter,
      ));
    } catch (e) {
      emit(state.copyWith(status: ReportStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> loadTasksData({
    ReportDataFilter? perTaskFilter,
    ReportDataFilter? distributionFilter,
    ReportDataFilter? taskChartFilterParam, // Renamed to avoid conflict
  }) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final completedToday = await _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.today);
      final completedWeek = await _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.thisWeek);
      final completedTwoWeeks = await _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.lastTwoWeeks);
      final completedMonth = await _reportRepository.getCompletedTasksCountForRange(ReportTimeRange.thisMonth);

      final currentPerTaskFilter = perTaskFilter ?? state.focusTimePerTaskFilter;
      final focusPerTask = await _reportRepository.getFocusTimePerTaskForRange(_mapFilterToRange(currentPerTaskFilter));

      final currentDistributionFilter = distributionFilter ?? state.projectDistributionFilter;
      final projectDist = await _reportRepository.getProjectTimeDistributionForRange(_mapFilterToRange(currentDistributionFilter));

      final currentTaskChartFilter = taskChartFilterParam ?? state.taskChartFilter;
      final taskChart = await _reportRepository.getTaskFocusChartData(_mapFilterToRange(currentTaskChartFilter));


      emit(state.copyWith(
        status: ReportStatus.success,
        tasksCompletedToday: completedToday,
        tasksCompletedThisWeek: completedWeek,
        tasksCompletedLastTwoWeeks: completedTwoWeeks,
        tasksCompletedThisMonth: completedMonth,
        focusTimePerTask: focusPerTask,
        projectTimeDistribution: projectDist,
        taskFocusChartData: taskChart,
        focusTimePerTaskFilter: currentPerTaskFilter,
        projectDistributionFilter: currentDistributionFilter,
        taskChartFilter: currentTaskChartFilter,
      ));
    } catch (e) {
      emit(state.copyWith(status: ReportStatus.failure, errorMessage: e.toString()));
    }
  }

  // Helper to map ReportDataFilter to ReportTimeRange for repository calls
  ReportTimeRange _mapFilterToRange(ReportDataFilter filter) {
    switch (filter) {
      case ReportDataFilter.today:
        return ReportTimeRange.today;
      case ReportDataFilter.weekly:
        return ReportTimeRange.thisWeek;
      case ReportDataFilter.biweekly:
        return ReportTimeRange.lastTwoWeeks;
      case ReportDataFilter.monthly:
        return ReportTimeRange.thisMonth;
    }
  }

  // Helper for heatmap days
  int _daysForFilter(ReportDataFilter filter) {
    switch (filter) {
      case ReportDataFilter.today: return 1;
      case ReportDataFilter.weekly: return 7;
      case ReportDataFilter.biweekly: return 14;
      case ReportDataFilter.monthly: return 30; // Approximate
      default: return 7;
    }
  }

  void changeTab(ReportTab tab) {
    emit(state.copyWith(currentTab: tab));
    // Optionally, reload data for the new tab if it's stale or specific filters are applied
    if (tab == ReportTab.pomodoro) {
      loadPomodoroData();
    } else {
      loadTasksData();
    }
  }

  void setPomodoroRecordFilter(ReportDataFilter filter) {
    emit(state.copyWith(pomodoroRecordFilter: filter));
    loadPomodoroData(recordFilter: filter); // Reload with new filter
  }

  void setFocusTimeGoalFilter(ReportDataFilter filter) {
    emit(state.copyWith(focusTimeGoalFilter: filter));
    loadPomodoroData(goalFilter: filter); // Reload with new filter
  }

  void setFocusTimeChartFilter(ReportDataFilter filter) {
    emit(state.copyWith(focusTimeChartFilter: filter));
    loadPomodoroData(chartFilter: filter); // Reload with new filter
  }

  void setFocusTimePerTaskFilter(ReportDataFilter filter) {
    emit(state.copyWith(focusTimePerTaskFilter: filter));
    loadTasksData(perTaskFilter: filter); // Reload with new filter
  }

  void setProjectDistributionFilter(ReportDataFilter filter) {
    emit(state.copyWith(projectDistributionFilter: filter));
    loadTasksData(distributionFilter: filter); // Reload with new filter
  }

  void setTaskChartFilter(ReportDataFilter filter) {
    emit(state.copyWith(taskChartFilter: filter));
    loadTasksData(taskChartFilterParam: filter); // Reload with new filter
  }

}