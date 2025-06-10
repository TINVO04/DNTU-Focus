import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';

// Enum để định nghĩa các trạng thái tải dữ liệu
enum ReportStatus { initial, loading, success, failure }

// Enum để định nghĩa các bộ lọc thời gian cho biểu đồ
enum ReportDataFilter { daily, weekly, biweekly, monthly, yearly }

class ReportState extends Equatable {
  // Trạng thái chung của màn hình
  final ReportStatus status;
  final String? errorMessage;

  // Dữ liệu cho các thẻ thống kê Pomodoro
  final Duration focusTimeToday;
  final Duration focusTimeThisWeek;
  final Duration focusTimeThisTwoWeeks;
  final Duration focusTimeThisMonth;

  // Dữ liệu cho các thẻ thống kê Tasks
  final int tasksCompletedToday;
  final int tasksCompletedThisWeek;
  final int tasksCompletedThisTwoWeeks;
  final int tasksCompletedThisMonth;

  // Dữ liệu cho các biểu đồ và danh sách
  final Map<String?, Duration> projectTimeDistribution; // projectId -> duration
  final Map<String, Duration> taskFocusTime; // taskId -> duration
  final Map<DateTime, Map<String?, Duration>> focusTimeChartData; // date -> {projectId -> duration}

  // Dữ liệu thô để tra cứu tên, màu sắc...
  final List<Project> allProjects;
  final List<Task> allTasks;

  // Các bộ lọc hiện tại
  final ReportDataFilter projectDistributionFilter;
  final ReportDataFilter focusTimeChartFilter;

  const ReportState({
    this.status = ReportStatus.initial,
    this.errorMessage,
    this.focusTimeToday = Duration.zero,
    this.focusTimeThisWeek = Duration.zero,
    this.focusTimeThisTwoWeeks = Duration.zero,
    this.focusTimeThisMonth = Duration.zero,
    this.tasksCompletedToday = 0,
    this.tasksCompletedThisWeek = 0,
    this.tasksCompletedThisTwoWeeks = 0,
    this.tasksCompletedThisMonth = 0,
    this.projectTimeDistribution = const {},
    this.taskFocusTime = const {},
    this.focusTimeChartData = const {},
    this.allProjects = const [],
    this.allTasks = const [],
    this.projectDistributionFilter = ReportDataFilter.weekly,
    this.focusTimeChartFilter = ReportDataFilter.biweekly,
  });

  // Hàm copyWith để tạo ra một state mới dựa trên state cũ
  // Đây là một phần quan trọng của BLoC/Cubit
  ReportState copyWith({
    ReportStatus? status,
    String? errorMessage,
    Duration? focusTimeToday,
    Duration? focusTimeThisWeek,
    Duration? focusTimeThisTwoWeeks,
    Duration? focusTimeThisMonth,
    int? tasksCompletedToday,
    int? tasksCompletedThisWeek,
    int? tasksCompletedThisTwoWeeks,
    int? tasksCompletedThisMonth,
    Map<String?, Duration>? projectTimeDistribution,
    Map<String, Duration>? taskFocusTime,
    Map<DateTime, Map<String?, Duration>>? focusTimeChartData,
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
      tasksCompletedToday: tasksCompletedToday ?? this.tasksCompletedToday,
      tasksCompletedThisWeek: tasksCompletedThisWeek ?? this.tasksCompletedThisWeek,
      tasksCompletedThisTwoWeeks:
      tasksCompletedThisTwoWeeks ?? this.tasksCompletedThisTwoWeeks,
      tasksCompletedThisMonth:
      tasksCompletedThisMonth ?? this.tasksCompletedThisMonth,
      projectTimeDistribution:
      projectTimeDistribution ?? this.projectTimeDistribution,
      taskFocusTime: taskFocusTime ?? this.taskFocusTime,
      focusTimeChartData: focusTimeChartData ?? this.focusTimeChartData,
      allProjects: allProjects ?? this.allProjects,
      allTasks: allTasks ?? this.allTasks,
      projectDistributionFilter:
      projectDistributionFilter ?? this.projectDistributionFilter,
      focusTimeChartFilter: focusTimeChartFilter ?? this.focusTimeChartFilter,
    );
  }

  // props của Equatable để Bloc có thể biết khi nào cần rebuild UI
  @override
  List<Object?> get props => [
    status,
    errorMessage,
    focusTimeToday,
    focusTimeThisWeek,
    focusTimeThisTwoWeeks,
    focusTimeThisMonth,
    tasksCompletedToday,
    tasksCompletedThisWeek,
    tasksCompletedThisTwoWeeks,
    tasksCompletedThisMonth,
    projectTimeDistribution,
    taskFocusTime,
    focusTimeChartData,
    allProjects,
    allTasks,
    projectDistributionFilter,
    focusTimeChartFilter,
  ];
}