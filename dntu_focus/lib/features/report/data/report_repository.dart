import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/features/report/data/models/pomodoro_session_model.dart';
import 'package:moji_todo/features/report/data/report_time_range.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';

class ReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReportRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

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
      fromFirestore: (snapshot, _) => Task.fromJson(snapshot.data()!, docId: snapshot.id),
      toFirestore: (model, _) => model.toJson(),
    );
  }

  Future<List<PomodoroSessionRecordModel>> getPomodoroSessions(DateTime start, DateTime end) async {
    try {
      final snapshot = await _sessionsCollection()
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting pomodoro sessions: $e');
      // Trả về danh sách rỗng để tránh crash
      return [];
    }
  }

  // ===== SỬA LỖI QUAN TRỌNG Ở ĐÂY =====
  Future<int> getCompletedTasksCountForRange(ReportTimeRange range) async {
    final dateRange = range.range;
    try {
      final snapshot = await _tasksCollection()
          .where('isCompleted', isEqualTo: true)
          .where('completionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(dateRange.start))
          .where('completionDate', isLessThanOrEqualTo: Timestamp.fromDate(dateRange.end))
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      // THAY ĐỔI: Thay vì ném lại lỗi, ta ghi log và trả về 0.
      // Điều này ngăn ứng dụng bị crash nếu việc đếm task thất bại.
      debugPrint('Error getting completed tasks count, returning 0. Error: $e');
      return 0;
    }
  }

  Future<Map<String?, Duration>> getProjectTimeDistributionForRange(ReportTimeRange range) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final workSessions = sessions.where((s) => s.isWorkSession);

    final Map<String?, int> projectDurationsInSeconds = {};
    for (final session in workSessions) {
      final key = session.projectId;
      projectDurationsInSeconds.update(key, (value) => value + session.duration,
          ifAbsent: () => session.duration);
    }
    return projectDurationsInSeconds.map((key, value) => MapEntry(key, Duration(seconds: value)));
  }

  Future<Map<String, Duration>> getTaskFocusTime(ReportTimeRange range) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final workSessions = sessions.where((s) => s.isWorkSession && s.taskId != null);

    final Map<String, int> taskDurationsInSeconds = {};
    for (final session in workSessions) {
      taskDurationsInSeconds.update(session.taskId!, (value) => value + session.duration,
          ifAbsent: () => session.duration);
    }
    return taskDurationsInSeconds.map((key, value) => MapEntry(key, Duration(seconds: value)));
  }

  Future<Map<DateTime, Map<String?, Duration>>> getFocusTimeChartData(ReportTimeRange range) async {
    final dateRange = range.range;
    final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
    final workSessions = sessions.where((s) => s.isWorkSession);

    final Map<DateTime, Map<String?, int>> dailyDataInSeconds = {};

    for (final session in workSessions) {
      final day = DateUtils.dateOnly(session.startTime);
      final dailyMap = dailyDataInSeconds.putIfAbsent(day, () => {});
      final projectId = session.projectId;
      dailyMap.update(projectId, (value) => value + session.duration, ifAbsent: () => session.duration);
    }

    return dailyDataInSeconds.map((date, data) => MapEntry(
        date, data.map((key, value) => MapEntry(key, Duration(seconds: value)))));
  }

  Future<Duration> getTotalFocusTimeForRange(ReportTimeRange range) async {
    try {
      final dateRange = range.range;
      final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
      final totalSeconds = sessions
          .where((s) => s.isWorkSession)
          .fold<int>(0, (sum, s) => sum + s.duration);
      return Duration(seconds: totalSeconds);
    } catch(e) {
      debugPrint('Error getting total focus time, returning Duration.zero. Error: $e');
      return Duration.zero;
    }
  }

  Future<Map<DateTime, List<PomodoroSessionRecordModel>>> getPomodoroRecordsHeatmapData({
    required ReportTimeRange range,
  }) async {
    try {
      final dateRange = range.range;
      final sessions = await getPomodoroSessions(dateRange.start, dateRange.end);
      final Map<DateTime, List<PomodoroSessionRecordModel>> data = {};
      for (final session in sessions) {
        final day = DateUtils.dateOnly(session.startTime);
        data.putIfAbsent(day, () => []).add(session);
      }
      return data;
    } catch(e) {
      debugPrint('Error getting heatmap data, returning empty map. Error: $e');
      return {};
    }
  }

  Future<Set<DateTime>> getDaysMeetingFocusGoal(ReportTimeRange range, Duration dailyGoal) async {
    try {
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
    } catch (e) {
      debugPrint('Error getting goal days, returning empty set. Error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getFocusTimePerTaskForRange(ReportTimeRange range) async {
    try {
      final taskDurations = await getTaskFocusTime(range);
      if (taskDurations.isEmpty) return [];

      final List<Map<String, dynamic>> result = [];
      for (final entry in taskDurations.entries) {
        try {
          final doc = await _tasksCollection().doc(entry.key).get();
          if (doc.exists) {
            final task = doc.data();
            if (task != null) {
              result.add({'task': task, 'focusTime': entry.value});
            }
          }
        } catch (e) {
          debugPrint("Could not find task with id: ${entry.key}. Error: $e");
        }
      }
      return result;
    } catch (e) {
      debugPrint('Error getting focus time per task, returning empty list. Error: $e');
      return [];
    }
  }
}