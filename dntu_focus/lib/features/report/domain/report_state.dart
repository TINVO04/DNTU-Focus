import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';
import 'package:moji_todo/features/report/data/models/pomodoro_session_model.dart';

enum ReportStatus { initial, loading, success, failure }
enum ReportDataFilter { daily, weekly, biweekly, monthly, yearly }

class ReportState extends Equatable {
  final ReportStatus status;
  final String? errorMessage;
  final Duration focusTimeToday;
  final Duration focusTimeThisWeek;
  final Duration focusTimeThisTwoWeeks;
  final Duration focusTimeThisMonth;
  final Duration focusTimeThisYear;
  final int tasksCompletedToday;
  final int tasksCompletedThisWeek;
  final int tasksCompletedThisTwoWeeks;
  final int tasksCompletedThisMonth;
  final int tasksCompletedThisYear;
  final Map<String?, Duration> projectTimeDistribution;
  final Map<String, Duration> taskFocusTime;
  final Map<DateTime, Map<String?, Duration>> focusTimeChartData;
  final Map<DateTime, List<PomodoroSessionRecordModel>> pomodoroHeatmapData;
  final Set<DateTime> focusGoalMetDays;
  final List<Project> allProjects;
  final List<Task> allTasks;
  final ReportDataFilter projectDistributionFilter;
  final ReportDataFilter focusTimeChartFilter;

  const ReportState({
    this.status = ReportStatus.initial,
    this.errorMessage,
    this.focusTimeToday = Duration.zero,
    this.focusTimeThisWeek = Duration.zero,
    this.focusTimeThisTwoWeeks = Duration.zero,
    this.focusTimeThisMonth = Duration.zero,
    this.focusTimeThisYear = Duration.zero,
    this.tasksCompletedToday = 0,
    this.tasksCompletedThisWeek = 0,
    this.tasksCompletedThisTwoWeeks = 0,
    this.tasksCompletedThisMonth = 0,
    this.tasksCompletedThisYear = 0,
    this.projectTimeDistribution = const {},
    this.taskFocusTime = const {},
    this.focusTimeChartData = const {},
    this.pomodoroHeatmapData = const {},
    this.focusGoalMetDays = const {},
    this.allProjects = const [],
    this.allTasks = const [],
    this.projectDistributionFilter = ReportDataFilter.weekly,
    this.focusTimeChartFilter = ReportDataFilter.biweekly,
  });

  ReportState copyWith({
    ReportStatus? status,
    String? errorMessage,
    Duration? focusTimeToday,
    Duration? focusTimeThisWeek,
    Duration? focusTimeThisTwoWeeks,
    Duration? focusTimeThisMonth,
    Duration? focusTimeThisYear,
    int? tasksCompletedToday,
    int? tasksCompletedThisWeek,
    int? tasksCompletedThisTwoWeeks,
    int? tasksCompletedThisMonth,
    int? tasksCompletedThisYear,
    Map<String?, Duration>? projectTimeDistribution,
    Map<String, Duration>? taskFocusTime,
    Map<DateTime, Map<String?, Duration>>? focusTimeChartData,
    Map<DateTime, List<PomodoroSessionRecordModel>>? pomodoroHeatmapData,
    Set<DateTime>? focusGoalMetDays,
    List<Project>? allProjects,
    List<Task>? allTasks,
    ReportDataFilter? projectDistributionFilter,
    ReportDataFilter? focusTimeChartFilter,
  }) {
    return ReportState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      focusTimeToday: focusTimeToday ?? this.focusTimeToday,
      focusTimeThisWeek: focusTimeThisWeek ?? this.focusTimeThisWeek,
      focusTimeThisTwoWeeks: focusTimeThisTwoWeeks ?? this.focusTimeThisTwoWeeks,
      focusTimeThisMonth: focusTimeThisMonth ?? this.focusTimeThisMonth,
      focusTimeThisYear: focusTimeThisYear ?? this.focusTimeThisYear,
      tasksCompletedToday: tasksCompletedToday ?? this.tasksCompletedToday,
      tasksCompletedThisWeek: tasksCompletedThisWeek ?? this.tasksCompletedThisWeek,
      tasksCompletedThisTwoWeeks: tasksCompletedThisTwoWeeks ?? this.tasksCompletedThisTwoWeeks,
      tasksCompletedThisMonth: tasksCompletedThisMonth ?? this.tasksCompletedThisMonth,
      tasksCompletedThisYear: tasksCompletedThisYear ?? this.tasksCompletedThisYear,
      projectTimeDistribution: projectTimeDistribution ?? this.projectTimeDistribution,
      taskFocusTime: taskFocusTime ?? this.taskFocusTime,
      focusTimeChartData: focusTimeChartData ?? this.focusTimeChartData,
      pomodoroHeatmapData: pomodoroHeatmapData ?? this.pomodoroHeatmapData,
      focusGoalMetDays: focusGoalMetDays ?? this.focusGoalMetDays,
      allProjects: allProjects ?? this.allProjects,
      allTasks: allTasks ?? this.allTasks,
      projectDistributionFilter: projectDistributionFilter ?? this.projectDistributionFilter,
      focusTimeChartFilter: focusTimeChartFilter ?? this.focusTimeChartFilter,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    focusTimeToday,
    focusTimeThisWeek,
    focusTimeThisTwoWeeks,
    focusTimeThisMonth,
    focusTimeThisYear,
    tasksCompletedToday,
    tasksCompletedThisWeek,
    tasksCompletedThisTwoWeeks,
    tasksCompletedThisMonth,
    tasksCompletedThisYear,
    projectTimeDistribution,
    taskFocusTime,
    focusTimeChartData,
    pomodoroHeatmapData,
    focusGoalMetDays,
    allProjects,
    allTasks,
    projectDistributionFilter,
    focusTimeChartFilter,
  ];
}