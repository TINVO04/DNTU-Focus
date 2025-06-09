import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/data/models/project_model.dart';
import '../../features/tasks/data/models/tag_model.dart';

class BackupService {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BackupService(this.taskBox, this.syncInfoBox, this.projectBox, this.tagBox);

  Future<DateTime?> getLastBackupTime() async {
    return syncInfoBox.get('lastSync');
  }

  Future<void> backupToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Người dùng chưa đăng nhập, không thể đồng bộ.');
      return;
    }
    final String currentUserId = user.uid;

    final WriteBatch batch = firestore.batch();

    final tasks = taskBox.values.where((task) => task.userId == currentUserId).toList();
    for (var task in tasks) {
      // ID của Task giờ là String, không cần .toString() nữa
      if (task.id != null && task.id!.isNotEmpty) {
        final docRef = firestore
            .collection('users')
            .doc(currentUserId)
            .collection('tasks')
            .doc(task.id!); // SỬ DỤNG trực tiếp task.id (String)
        batch.set(docRef, task.toJson(), SetOptions(merge: true));
      } else {
        print('Task có ID null hoặc rỗng, bỏ qua đồng bộ: ${task.title}');
      }
    }
    print('Đã chuẩn bị ${tasks.length} tasks (của user $currentUserId) cho batch.');

    final projects = projectBox.values.where((project) => project.userId == currentUserId).toList();
    for (var project in projects) {
      // Project ID đã là String
      final docRef = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('projects')
          .doc(project.id);
      batch.set(docRef, {
        'id': project.id,
        'name': project.name,
        'colorValue': project.colorValue,
        'isArchived': project.isArchived,
        'iconCodePoint': project.iconCodePoint,
        'iconFontFamily': project.iconFontFamily,
        'iconFontPackage': project.iconFontPackage,
        'userId': project.userId,
      }, SetOptions(merge: true));
    }
    print('Đã chuẩn bị ${projects.length} projects (của user $currentUserId) cho batch.');

    final tags = tagBox.values.where((tag) => tag.userId == currentUserId).toList();
    for (var tag in tags) {
      // Tag ID đã là String
      final docRef = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tags')
          .doc(tag.id);
      batch.set(docRef, {
        'id': tag.id,
        'name': tag.name,
        'textColorValue': tag.textColorValue,
        'isArchived': tag.isArchived,
        'userId': tag.userId,
      }, SetOptions(merge: true));
    }
    print('Đã chuẩn bị ${tags.length} tags (của user $currentUserId) cho batch.');

    try {
      await batch.commit();
      print('Firestore batch commit thành công.');

      // ID của Task giờ là String, không cần .toString() nữa
      await _cleanUpFirestore(currentUserId, 'tasks', tasks.map((t) => t.id).where((id) => id != null && id.isNotEmpty).cast<String>().toList());
      await _cleanUpFirestore(currentUserId, 'projects', projects.map((p) => p.id).toList());
      await _cleanUpFirestore(currentUserId, 'tags', tags.map((t) => t.id).toList());

      await syncInfoBox.put('lastSync', DateTime.now());
      print('Backup to Firestore completed at ${DateTime.now()} for user $currentUserId');
    } catch (e) {
      print('Lỗi khi thực hiện batch commit hoặc clean up: $e');
      // Cân nhắc throw lỗi ở đây để AuthCubit có thể bắt và xử lý (ví dụ: hiển thị thông báo cho người dùng)
      // throw Exception('Lỗi đồng bộ lên Firestore: $e');
    }
  }

  Future<void> savePomodoroSession({
    required String? taskId, // taskId giờ là String?
    required DateTime startTime,
    required DateTime endTime,
    required bool isWorkSession,
    required String soundUsed,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Người dùng chưa đăng nhập, không thể lưu phiên Pomodoro.');
      return;
    }
    final durationInSeconds = endTime.difference(startTime).inSeconds;
    final sessionDate = DateTime.utc(endTime.year, endTime.month, endTime.day);
    String? projectId;
    if (taskId != null && taskId != "none" && taskId.isNotEmpty) {
      try {
        // task.id giờ là String, so sánh trực tiếp
        final task = taskBox.values.firstWhere((t) => t.id == taskId && t.userId == user.uid);
        projectId = task.projectId;
      } catch (e) {
        print('Task với id "$taskId" của user ${user.uid} không tìm thấy trong Hive để lấy projectId. Lỗi: $e');
      }
    }
    try {
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('pomodoro_sessions')
          .add({
        'taskId': taskId, // taskId giờ là String
        'startTime': Timestamp.fromDate(startTime.toUtc()),
        'endTime': Timestamp.fromDate(endTime.toUtc()),
        'isWorkSession': isWorkSession,
        'soundUsed': soundUsed,
        'durationInSeconds': durationInSeconds,
        'sessionDate': Timestamp.fromDate(sessionDate),
        'projectId': projectId,
      });
      print('Lưu phiên Pomodoro thành công: taskId=$taskId, startTime=$startTime, duration=$durationInSeconds giây, sessionDate=$sessionDate, projectId=$projectId');
    } catch (e) {
      print('Lỗi khi lưu phiên Pomodoro: $e');
      // throw Exception('Lỗi lưu phiên Pomodoro: $e');
    }
  }


  Future<void> restoreFromFirestore() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    final String currentUserId = user.uid;

    // Nên clear theo user ID để tránh xóa nhầm dữ liệu của user khác nếu có nhiều user trên cùng thiết bị (hiếm nhưng có thể)
    // Tuy nhiên, việc clear toàn bộ box trước khi restore cho user hiện tại là cách tiếp cận phổ biến.
    final taskKeysToDelete = taskBox.keys.where((key) => taskBox.get(key)?.userId == currentUserId).toList();
    for (var key in taskKeysToDelete) {
      await taskBox.delete(key);
    }
    final projectKeysToDelete = projectBox.keys.where((key) => projectBox.get(key)?.userId == currentUserId).toList();
    for (var key in projectKeysToDelete) {
      await projectBox.delete(key);
    }
    final tagKeysToDelete = tagBox.keys.where((key) => tagBox.get(key)?.userId == currentUserId).toList();
    for (var key in tagKeysToDelete) {
      await tagBox.delete(key);
    }
    print('Local Hive boxes (tasks, projects, tags) for user $currentUserId cleared before restoring.');


    final taskSnapshot = await firestore.collection('users').doc(currentUserId).collection('tasks').get();
    if (taskSnapshot.docs.isNotEmpty) {
      final tasks = taskSnapshot.docs.map((doc) {
        // Truyền doc.id vào fromJson để Task.id được gán bằng ID của document Firestore
        return Task.fromJson(doc.data(), docId: doc.id);
      }).toList();
      for (var task in tasks) {
        // ID của Task giờ là String, không cần kiểm tra null vì fromJson đã xử lý
        if (task.id != null && task.id!.isNotEmpty) {
          await taskBox.put(task.id!, task.copyWith(userId: currentUserId));
        } else {
          print("CẢNH BÁO: Task từ Firestore có ID null hoặc rỗng sau khi parse. Title: ${task.title}");
        }
      }
      print('Đã khôi phục ${tasks.length} tasks từ Firestore vào Hive cho user $currentUserId.');
    } else {
      print('Không có task nào trên Firestore để khôi phục cho user $currentUserId.');
    }

    final projectSnapshot = await firestore.collection('users').doc(currentUserId).collection('projects').get();
    if (projectSnapshot.docs.isNotEmpty) {
      final projects = projectSnapshot.docs.map((doc) {
        final data = doc.data();
        return Project(
          id: doc.id, // Sử dụng ID của document Firestore
          name: data['name'] as String,
          color: Color(data['colorValue'] as int),
          isArchived: data['isArchived'] as bool? ?? false,
          iconCodePoint: data['iconCodePoint'] as int?,
          iconFontFamily: data['iconFontFamily'] as String?,
          iconFontPackage: data['iconFontPackage'] as String?,
          userId: data['userId'] as String? ?? currentUserId,
        );
      }).toList();
      for (var project in projects) {
        await projectBox.put(project.id, project.copyWith(userId: currentUserId));
      }
      print('Đã khôi phục ${projects.length} projects từ Firestore vào Hive cho user $currentUserId.');
    } else {
      print('Không có project nào trên Firestore để khôi phục cho user $currentUserId.');
    }

    final tagSnapshot = await firestore.collection('users').doc(currentUserId).collection('tags').get();
    if (tagSnapshot.docs.isNotEmpty) {
      final tags = tagSnapshot.docs.map((doc) {
        final data = doc.data();
        return Tag(
          id: doc.id, // Sử dụng ID của document Firestore
          name: data['name'] as String,
          textColor: Color(data['textColorValue'] as int),
          isArchived: data['isArchived'] as bool? ?? false,
          userId: data['userId'] as String? ?? currentUserId,
        );
      }).toList();
      for (var tag in tags) {
        await tagBox.put(tag.id, tag.copyWith(userId: currentUserId));
      }
      print('Đã khôi phục ${tags.length} tags từ Firestore vào Hive cho user $currentUserId.');
    } else {
      print('Không có tags nào trên Firestore để khôi phục cho user $currentUserId.');
    }

    if (taskSnapshot.docs.isEmpty && projectSnapshot.docs.isEmpty && tagSnapshot.docs.isEmpty) {
      print('Không tìm thấy dữ liệu sao lưu trên Firestore để khôi phục cho user $currentUserId.');
    }
    await syncInfoBox.put('lastSync', DateTime.now());
    print('Restore from Firestore completed at ${DateTime.now()} for user $currentUserId');
  }

  Future<void> deleteFirestoreBackup() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    final String currentUserId = user.uid;

    final WriteBatch batch = firestore.batch();
    final collections = ['tasks', 'projects', 'tags', 'pomodoro_sessions'];
    for (var collectionName in collections) {
      final snapshot = await firestore.collection('users').doc(currentUserId).collection(collectionName).get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      print('Đã chuẩn bị xóa ${snapshot.docs.length} documents từ collection $collectionName cho user $currentUserId.');
    }
    try {
      await batch.commit();
      print('Cloud backup deleted successfully via batch for user $currentUserId.');
      await syncInfoBox.delete('lastSync');
    } catch (e) {
      print('Error deleting cloud backup via batch for user $currentUserId: $e');
      throw Exception('Failed to delete cloud backup: $e');
    }
  }

  Future<void> _cleanUpFirestore(String userId, String collectionName, List<String> currentHiveIds) async {
    // currentHiveIds giờ là List<String>
    final firestoreCollection = await firestore.collection('users').doc(userId).collection(collectionName).get();
    final WriteBatch batch = firestore.batch();
    int deletedCount = 0;
    for (var doc in firestoreCollection.docs) {
      // doc.id đã là String
      if (!currentHiveIds.contains(doc.id)) {
        batch.delete(doc.reference);
        deletedCount++;
      }
    }
    if (deletedCount > 0) {
      // Thêm kiểm tra an toàn như đã đề xuất trước
      if (firestoreCollection.docs.isNotEmpty && (deletedCount / firestoreCollection.docs.length) > 0.8 && currentHiveIds.isEmpty) {
        print('CẢNH BÁO: _cleanUpFirestore sắp xóa toàn bộ collection $collectionName cho user $userId vì currentHiveIds rỗng. Hủy bỏ.');
        return; // Hoặc throw Exception
      }
      try {
        await batch.commit();
        print('Đã xóa $deletedCount mục không còn trong Hive khỏi collection $collectionName trên Firestore bằng batch cho user $userId.');
      } catch(e) {
        print('Lỗi khi clean up collection $collectionName cho user $userId: $e');
      }
    }
  }

  Future<String> exportToLocalJson() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    final String currentUserId = user.uid;

    final tasks = taskBox.values.where((task) => task.userId == currentUserId).toList();
    final projects = projectBox.values.where((project) => project.userId == currentUserId).toList();
    final tags = tagBox.values.where((tag) => tag.userId == currentUserId).toList();

    final jsonData = {
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'projects': projects.map((project) => {
        'id': project.id,
        'name': project.name,
        'colorValue': project.colorValue,
        'isArchived': project.isArchived,
        'iconCodePoint': project.iconCodePoint,
        'iconFontFamily': project.iconFontFamily,
        'iconFontPackage': project.iconFontPackage,
        'userId': project.userId,
      }).toList(),
      'tags': tags.map((tag) => {
        'id': tag.id,
        'name': tag.name,
        'textColorValue': tag.textColorValue,
        'isArchived': tag.isArchived,
        'userId': tag.userId,
      }).toList(),
    };

    final jsonString = jsonEncode(jsonData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/moji_todo_backup_${currentUserId.substring(0, 6)}.json');
    await file.writeAsString(jsonString);
    print('Exported data to ${file.path} for user $currentUserId');
    return file.path;
  }
}