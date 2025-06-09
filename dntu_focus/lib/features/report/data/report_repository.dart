import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moji_todo/core/utils/my_date_range.dart';
import 'package:moji_todo/features/report/data/models/pomodoro_session_model.dart';
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
  CollectionReference<TaskModel> _tasksCollection() {
    final userId = _userId;
    if (userId == null) {
      throw Exception('User is not logged in.');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .withConverter<TaskModel>(
      fromFirestore: (snapshot, _) => TaskModel.fromFirestore(snapshot),
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
  Future<int> getCompletedTasksCountForRange(DateTimeRange range) async {
    try {
      final snapshot = await _tasksCollection()
          .where('isCompleted', isEqualTo: true)
          .where('completionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('completionDate', isLessThanOrEqualTo: Timestamp.fromDate(range.end))
          .count()
          .get();
      return snapshot.count;
    } catch (e) {
      debugPrint('Error getting completed tasks count: $e');
      rethrow;
    }
  }

  /// Lấy dữ liệu cho biểu đồ phân bổ thời gian theo Project
  Future<Map<String?, int>> getProjectTimeDistributionForRange(
      DateTimeRange range) async {
    final sessions = await getPomodoroSessions(range.start, range.end);
    final workSessions = sessions.where((s) => s.isWorkSession);

    final Map<String?, int> projectDurations = {};
    for (final session in workSessions) {
      // projectId có thể null, ta sẽ nhóm chúng vào một mục 'General' hoặc 'None'
      final key = session.projectId;
      projectDurations.update(key, (value) => value + session.duration,
          ifAbsent: () => session.duration);
    }
    return projectDurations;
  }

  /// Lấy dữ liệu thời gian tập trung cho từng task
  Future<Map<String, int>> getTaskFocusTime(DateTimeRange range) async {
    final sessions = await getPomodoroSessions(range.start, range.end);
    final workSessions = sessions.where((s) => s.isWorkSession && s.taskId != null);

    final Map<String, int> taskDurations = {};
    for (final session in workSessions) {
      taskDurations.update(session.taskId!, (value) => value + session.duration,
          ifAbsent: () => session.duration);
    }
    return taskDurations;
  }


  /// Lấy dữ liệu cho biểu đồ cột Focus Time Chart
  Future<Map<DateTime, Map<String?, int>>> getFocusTimeChartData(
      MyDateRange range) async {
    final sessions = await getPomodoroSessions(range.start, range.end);
    final workSessions = sessions.where((s) => s.isWorkSession);

    final Map<DateTime, Map<String?, int>> dailyData = {};

    for (final session in workSessions) {
      final day = DateUtils.dateOnly(session.startTime);

      final dailyMap = dailyData.putIfAbsent(day, () => {});

      final projectId = session.projectId;
      dailyMap.update(projectId, (value) => value + session.duration, ifAbsent: () => session.duration);
    }

    return dailyData;
  }
}