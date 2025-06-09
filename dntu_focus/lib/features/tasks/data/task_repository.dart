import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // THÊM IMPORT NÀY
import '../data/models/task_model.dart';
import '../data/models/project_model.dart';
import '../data/models/tag_model.dart';

class TaskRepository {
  final Box<Task> taskBox;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid(); // KHỞI TẠO UUID

  TaskRepository({
    required this.taskBox,
    required this.projectBox,
    required this.tagBox,
  });

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> _trackModification(String boxName) async {
    try {
      final appStatusBox = await Hive.openBox('app_status');
      await appStatusBox.put('lastModified_$boxName', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error tracking modification for $boxName: $e');
    }
  }

  Future<void> initializeSampleTasksForCurrentUser() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('Người dùng chưa đăng nhập, không tạo task mẫu.');
      return;
    }

    final userTasks = taskBox.values.where((task) => task.userId == userId).toList();
    if (userTasks.isNotEmpty) {
      print('Người dùng đã có task, không tạo task mẫu.');
      return;
    }

    String? sampleProjectId;
    try {
      final defaultProject = projectBox.values.firstWhere(
            (p) => p.name == 'Pomodoro App' && p.userId == userId,
      );
      sampleProjectId = defaultProject.id;
    } catch (e) {
      print('Không tìm thấy project "Pomodoro App" của người dùng $userId cho sample task. Lỗi: $e');
    }

    List<String> sampleTagIds = [];
    final List<String> sampleTagNames = ['Design', 'Work', 'Productive'];
    for (String tagName in sampleTagNames) {
      try {
        final defaultTag = tagBox.values.firstWhere(
              (t) => t.name == tagName && t.userId == userId,
        );
        sampleTagIds.add(defaultTag.id);
      } catch (e) {
        print('Không tìm thấy tag "$tagName" của người dùng $userId cho sample task. Lỗi: $e');
      }
    }

    // ID sẽ được tự động tạo bởi Task constructor nếu không được cung cấp
    final sampleTask = Task(
      title: 'Design User Interface (UI)',
      dueDate: DateTime.now(),
      priority: 'High',
      projectId: sampleProjectId,
      tagIds: sampleTagIds.isNotEmpty ? sampleTagIds : null, // Đảm bảo tagIds là null nếu rỗng
      estimatedPomodoros: 6,
      completedPomodoros: 2,
      isCompleted: false,
      userId: userId,
      createdAt: DateTime.now(),
    );
    await addTask(sampleTask);
    print('Sample task initialized for user $userId.');
  }


  Future<List<Task>> getTasks() async {
    final userId = _currentUserId;
    if (userId == null) {
      print('Người dùng chưa đăng nhập, trả về danh sách task rỗng.');
      return [];
    }
    return taskBox.values.where((task) => task.userId == userId).toList();
  }

  Future<void> addTask(Task task) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể thêm task.');
    }

    // Task constructor đã tự gán UUID nếu task.id là null
    // Đảm bảo userId và createdAt được gán nếu chưa có
    final taskToAdd = task.copyWith(
      userId: userId,
      createdAt: task.createdAt ?? DateTime.now(),
      id: task.id ?? _uuid.v4(), // Đảm bảo có ID, ưu tiên ID đã có, nếu không thì tạo mới
    );

    // Kiểm tra lại xem task.id có null không sau khi copyWith (không nên xảy ra nếu logic ở trên đúng)
    if (taskToAdd.id == null) {
      print('CẢNH BÁO: Task ID vẫn null sau khi gán UUID trong addTask. Task title: ${taskToAdd.title}');
      // Có thể throw lỗi ở đây hoặc gán lại một UUID mới cho chắc chắn
      // taskToAdd = taskToAdd.copyWith(id: _uuid.v4());
      throw Exception('Task ID không được null khi thêm vào Hive.');
    }

    await taskBox.put(taskToAdd.id!, taskToAdd); // Sử dụng ID (String) làm key
    await _trackModification('tasks');

    print('Task added to Hive with ID: ${taskToAdd.id}, Title: ${taskToAdd.title}');
  }

  Future<void> updateTask(Task task) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể cập nhật task.');
    }
    // ID giờ là String, không cần kiểm tra null theo kiểu cũ nữa,
    // nhưng vẫn cần đảm bảo task có ID hợp lệ.
    if (task.id == null || task.id!.isEmpty) {
      throw Exception('Task ID không thể null hoặc rỗng khi cập nhật.');
    }

    final existingTask = taskBox.get(task.id);
    if (existingTask == null || existingTask.userId != userId) {
      throw Exception('Bạn không có quyền cập nhật task này hoặc task không tồn tại.');
    }

    final taskToUpdate = task.copyWith(
        userId: existingTask.userId, // Giữ userId gốc
        createdAt: existingTask.createdAt // Giữ createdAt gốc
    );
    print('TaskRepository: Chuẩn bị ghi vào Hive - Task ID: ${taskToUpdate.id}, Title: "${taskToUpdate.title}", ProjectID TRƯỚC KHI GHI: ${taskToUpdate.projectId}');
    await taskBox.put(task.id!, taskToUpdate);
    await _trackModification('tasks');

    print('Task updated in Hive with ID: ${task.id}, Title: ${taskToUpdate.title}');
  }

  Future<void> deleteTask(Task task) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể xóa task.');
    }
    if (task.id == null || task.id!.isEmpty) {
      throw Exception('Task ID không thể null hoặc rỗng khi xóa.');
    }

    final existingTask = taskBox.get(task.id);
    if (existingTask != null && existingTask.userId != userId) {
      throw Exception('Bạn không có quyền xóa task này.');
    }

    if (existingTask == null) {
      print('Task ID ${task.id} không tìm thấy trong Hive để xóa.');
    } else {
      await taskBox.delete(task.id!);
      await _trackModification('tasks');
    }
    print('Task deleted from Hive with ID: ${task.id}');
  }
}