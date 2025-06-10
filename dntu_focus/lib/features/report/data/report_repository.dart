import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/core/utils/my_date_range.dart';
import 'package:moji_todo/features/report/data/models/pomodoro_session_model.dart';
import 'package:moji_todo/features/report/data/report_time_range.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReportRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Helper để lấy collection `pomodoro_sessions` của user hiện tại
  CollectionReference<PomodoroSessionRecordModel> _sessionsCollection() {
    final userId = _userId;
    if (userId == null) {
      throw Exception('User is not logged in.');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pomodoro_sessions')
        .withConverter<PomodoroSessionRecordModel>(
      fromFirestore: (snapshot, _) => PomodoroSessionRecordModel.fromFirestore(snapshot),
      toFirestore: (model, _) => model.toJson(),
    );
  }

  // Helper để lấy collection `tasks` của user hiện tại
  CollectionReference<Task> _tasksCollection() {
    final userId = _userId;
    if (userId == null) {
      throw Exception('User is not logged in.');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .withConverter<Task>(
      fromFirestore: (snapshot, _) => Task.fromFirestore(snapshot),
      toFirestore: (model, _) => model.toJson(),
    );
  }

  /// Lấy tất cả các session trong một khoảng thời gian
  Future<List<PomodoroSessionRecordModel>> getPomodoroSessions(
      DateTime start, DateTime end) async {
    try {
      final snapshot = await _sessionsCollection()
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting pomodoro sessions: $e');
      rethrow;
    }
  }

  /// Lấy tổng số task đã hoàn thành trong khoảng thời gian
  Future<int> getCompletedTasksCountForRange(ReportTimeRange range) async {
    final dateRange = range.range;
    try {
      final snapshot = await _tasksCollection()
          .where('isCompleted', isEqualTo: true)
          .where('completionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('completionDate', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
          .count()
          .get();
      return snapshot.count;
    } catch (e) {
      debugPrint('Error getting completed tasks count: $e');
      rethrow;
    }
  }

  /// Lấy dữ liệu cho biểu đồ phân bổ thời gian theo Project
  Future<Map<String?, Duration>> getProjectTimeDistributionForRange(
      ReportTimeRange range) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final workSessions = sessions.where((s) => s.isWorkSession);

    final Map<String?, int> projectDurations = {};
    for (final session in workSessions) {
      // projectId có thể null, ta sẽ nhóm chúng vào một mục 'General' hoặc 'None'
      final key = session.projectId;
      projectDurations.update(key, (value) => value + session.duration,
          ifAbsent: () => session.duration);
    }
    return projectDurations.map((key, value) => MapEntry(key, Duration(seconds: value)));
  }

  /// Lấy dữ liệu thời gian tập trung cho từng task
  Future<Map<String, Duration>> getTaskFocusTime(ReportTimeRange range) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final workSessions = sessions.where((s) => s.isWorkSession && s.taskId != null);

    final Map<String, int> taskDurations = {};
    for (final session in workSessions) {
      taskDurations.update(session.taskId!, (value) => value + session.duration,
          ifAbsent: () => session.duration);
    }
    return taskDurations.map((key, value) => MapEntry(key, Duration(seconds: value)));
  }


  /// Lấy dữ liệu cho biểu đồ cột Focus Time Chart
  Future<Map<DateTime, Map<String?, Duration>>> getFocusTimeChartData(
      ReportTimeRange range) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final workSessions = sessions.where((s) => s.isWorkSession);

    final Map<DateTime, Map<String?, int>> dailyData = {};

    for (final session in workSessions) {
      final day = DateUtils.dateOnly(session.startTime);

      final dailyMap = dailyData.putIfAbsent(day, () => {});

      final projectId = session.projectId;
      dailyMap.update(projectId, (value) => value + session.duration, ifAbsent: () => session.duration);
    }

    return dailyData.map((date, data) => MapEntry(
        date, data.map((key, value) => MapEntry(key, Duration(seconds: value)))));
  }

  /// Tổng thời gian tập trung trong khoảng thời gian
  Future<Duration> getTotalFocusTimeForRange(ReportTimeRange range) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final total = sessions
        .where((s) => s.isWorkSession)
        .fold<int>(0, (sum, s) => sum + s.duration);
    return Duration(seconds: total);
  }

  Future<Map<DateTime, List<PomodoroSessionRecordModel>>> getPomodoroRecordsHeatmapData({
    required int daysToGoBack,
  }) async {
    final end = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
    final start = DateUtils.dateOnly(end.subtract(Duration(days: daysToGoBack - 1)));
    final sessions = await getPomodoroSessions(start, end);
    final Map<DateTime, List<PomodoroSessionRecordModel>> data = {};
    for (final session in sessions) {
      final day = DateUtils.dateOnly(session.startTime);
      data.putIfAbsent(day, () => []).add(session);
    }
    return data;
  }

  /// Các ngày đạt mục tiêu tập trung
  Future<Set<DateTime>> getDaysMeetingFocusGoal(
      ReportTimeRange range, Duration dailyGoal) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final Map<DateTime, int> dailyTotals = {};
    for (final s in sessions.where((e) => e.isWorkSession)) {
      final day = DateUtils.dateOnly(s.startTime);
      dailyTotals.update(day, (v) => v + s.duration, ifAbsent: () => s.duration);
    }
    final Set<DateTime> metDays = {};
    for (final entry in dailyTotals.entries) {
      if (entry.value >= dailyGoal.inSeconds) metDays.add(entry.key);
    }
    return metDays;
  }

  /// Thời gian tập trung trên từng task trong khoảng thời gian
  Future<List<Map<String, dynamic>>> getFocusTimePerTaskForRange(
      ReportTimeRange range) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final workSessions = sessions.where((s) => s.isWorkSession && s.taskId != null);
    final Map<String, int> durations = {};
    for (final s in workSessions) {
      durations.update(s.taskId!, (v) => v + s.duration, ifAbsent: () => s.duration);
    }
    final List<Map<String, dynamic>> result = [];
    for (final entry in durations.entries) {
      final doc = await _tasksCollection().doc(entry.key).get();
      if (doc.exists) {
        final task = doc.data();
        if (task != null) {
          result.add({'task': task, 'focusTime': Duration(seconds: entry.value)});
        }
      }
    }
    return result;
  }

  /// Dữ liệu biểu đồ tập trung theo task
  Future<Map<DateTime, Map<String?, Duration>>> getTaskFocusChartData(
      ReportTimeRange range) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final workSessions =
        sessions.where((s) => s.isWorkSession && s.taskId != null);
    final Map<DateTime, Map<String?, int>> data = {};
    for (final session in workSessions) {
      final day = DateUtils.dateOnly(session.startTime);
      final dailyMap = data.putIfAbsent(day, () => {});
      dailyMap.update(session.projectId, (v) => v + session.duration,
          ifAbsent: () => session.duration);
    }
    return data.map((date, d) => MapEntry(
        date, d.map((k, v) => MapEntry(k, Duration(seconds: v)))));
  }
}