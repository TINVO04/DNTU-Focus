part of 'report_cubit.dart';

enum ReportStatus { initial, loading, success, failure }

// Defines the active tab
enum ReportTab { pomodoro, tasks }

// Defines the filter for charts/summaries
enum ReportDataFilter {
  today,
  weekly,
  biweekly, // or lastTwoWeeks
  monthly
}

class ReportState extends Equatable {
  final ReportStatus status;
  final ReportTab currentTab;

  // Pomodoro Tab Data
  final Duration focusTimeToday;
  final Duration focusTimeThisWeek;
  final Duration focusTimeLastTwoWeeks;
  final Duration focusTimeThisMonth;
  final Map<DateTime, List<PomodoroSessionRecordModel>> pomodoroRecordsHeatmap; // Date -> Sessions
  final Set<DateTime> daysMeetingFocusGoal;
  final Map<DateTime, Map<String?, Duration>> focusTimeChartData; // Date -> {ProjectId? -> Duration}
  final ReportDataFilter pomodoroRecordFilter;
  final ReportDataFilter focusTimeGoalFilter;
  final ReportDataFilter focusTimeChartFilter;

  // Tasks Tab Data
  final int tasksCompletedToday;
  final int tasksCompletedThisWeek;
  final int tasksCompletedLastTwoWeeks;
  final int tasksCompletedThisMonth;
  final List<Map<String, dynamic>> focusTimePerTask; // {'task': Task, 'focusTime': Duration}
  final Map<String?, Duration> projectTimeDistribution; // ProjectId? -> Duration
  final Map<DateTime, Map<String?, Duration>> taskFocusChartData; // Similar to focusTimeChartData
  final ReportDataFilter focusTimePerTaskFilter;
  final ReportDataFilter projectDistributionFilter;
  final ReportDataFilter taskChartFilter;

  // To display project names and colors in charts
  final List<Project> allProjects;

  final String? errorMessage;

  const ReportState({
    this.status = ReportStatus.initial,
    this.currentTab = ReportTab.pomodoro,
    this.focusTimeToday = Duration.zero,
    this.focusTimeThisWeek = Duration.zero,
    this.focusTimeLastTwoWeeks = Duration.zero,
    this.focusTimeThisMonth = Duration.zero,
    this.pomodoroRecordsHeatmap = const {},
    this.daysMeetingFocusGoal = const {},
    this.focusTimeChartData = const {},
    this.pomodoroRecordFilter = ReportDataFilter.weekly,
    this.focusTimeGoalFilter = ReportDataFilter.monthly,
    this.focusTimeChartFilter = ReportDataFilter.biweekly,
    this.tasksCompletedToday = 0,
    this.tasksCompletedThisWeek = 0,
    this.tasksCompletedLastTwoWeeks = 0,
    this.tasksCompletedThisMonth = 0,
    this.focusTimePerTask = const [],
    this.projectTimeDistribution = const {},
    this.taskFocusChartData = const {},
    this.focusTimePerTaskFilter = ReportDataFilter.today, // Default or common filter
    this.projectDistributionFilter = ReportDataFilter.weekly,
    this.taskChartFilter = ReportDataFilter.biweekly,
    this.allProjects = const [],
    this.errorMessage,
  });

  ReportState copyWith({
    ReportStatus? status,
    ReportTab? currentTab,
    Duration? focusTimeToday,
    Duration? focusTimeThisWeek,
    Duration? focusTimeLastTwoWeeks,
    Duration? focusTimeThisMonth,
    Map<DateTime, List<PomodoroSessionRecordModel>>? pomodoroRecordsHeatmap,
    Set<DateTime>? daysMeetingFocusGoal,
    Map<DateTime, Map<String?, Duration>>? focusTimeChartData,
    ReportDataFilter? pomodoroRecordFilter,
    ReportDataFilter? focusTimeGoalFilter,
    ReportDataFilter? focusTimeChartFilter,
    int? tasksCompletedToday,
    int? tasksCompletedThisWeek,
    int? tasksCompletedLastTwoWeeks,
    int? tasksCompletedThisMonth,
    List<Map<String, dynamic>>? focusTimePerTask,
    Map<String?, Duration>? projectTimeDistribution,
    Map<DateTime, Map<String?, Duration>>? taskFocusChartData,
    ReportDataFilter? focusTimePerTaskFilter,
    ReportDataFilter? projectDistributionFilter,
    ReportDataFilter? taskChartFilter,
    List<Project>? allProjects,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ReportState(
      status: status ?? this.status,
      currentTab: currentTab ?? this.currentTab,
      focusTimeToday: focusTimeToday ?? this.focusTimeToday,
      focusTimeThisWeek: focusTimeThisWeek ?? this.focusTimeThisWeek,
      focusTimeLastTwoWeeks: focusTimeLastTwoWeeks ?? this.focusTimeLastTwoWeeks,
      focusTimeThisMonth: focusTimeThisMonth ?? this.focusTimeThisMonth,
      pomodoroRecordsHeatmap: pomodoroRecordsHeatmap ?? this.pomodoroRecordsHeatmap,
      daysMeetingFocusGoal: daysMeetingFocusGoal ?? this.daysMeetingFocusGoal,
      focusTimeChartData: focusTimeChartData ?? this.focusTimeChartData,
      pomodoroRecordFilter: pomodoroRecordFilter ?? this.pomodoroRecordFilter,
      focusTimeGoalFilter: focusTimeGoalFilter ?? this.focusTimeGoalFilter,
      focusTimeChartFilter: focusTimeChartFilter ?? this.focusTimeChartFilter,
      tasksCompletedToday: tasksCompletedToday ?? this.tasksCompletedToday,
      tasksCompletedThisWeek: tasksCompletedThisWeek ?? this.tasksCompletedThisWeek,
      tasksCompletedLastTwoWeeks: tasksCompletedLastTwoWeeks ?? this.tasksCompletedLastTwoWeeks,
      tasksCompletedThisMonth: tasksCompletedThisMonth ?? this.tasksCompletedThisMonth,
      focusTimePerTask: focusTimePerTask ?? this.focusTimePerTask,
      projectTimeDistribution: projectTimeDistribution ?? this.projectTimeDistribution,
      taskFocusChartData: taskFocusChartData ?? this.taskFocusChartData,
      focusTimePerTaskFilter: focusTimePerTaskFilter ?? this.focusTimePerTaskFilter,
      projectDistributionFilter: projectDistributionFilter ?? this.projectDistributionFilter,
      taskChartFilter: taskChartFilter ?? this.taskChartFilter,
      allProjects: allProjects ?? this.allProjects,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentTab,
    focusTimeToday,
    focusTimeThisWeek,
    focusTimeLastTwoWeeks,
    focusTimeThisMonth,
    pomodoroRecordsHeatmap,
    daysMeetingFocusGoal,
    focusTimeChartData,
    pomodoroRecordFilter,
    focusTimeGoalFilter,
    focusTimeChartFilter,
    tasksCompletedToday,
    tasksCompletedThisWeek,
    tasksCompletedLastTwoWeeks,
    tasksCompletedThisMonth,
    focusTimePerTask,
    projectTimeDistribution,
    taskFocusChartData,
    focusTimePerTaskFilter,
    projectDistributionFilter,
    taskChartFilter,
    allProjects,
    errorMessage,
  ];
}