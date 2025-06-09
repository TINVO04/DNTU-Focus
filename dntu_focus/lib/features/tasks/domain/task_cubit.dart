import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // Assuming this is used for classifyTask
import '../../../core/services/gemini_service.dart'; // Assuming this is your Gemini service
import '../data/models/project_model.dart';
import '../data/models/tag_model.dart';
import '../data/models/task_model.dart';
import '../data/models/project_tag_repository.dart';
import '../data/task_repository.dart';

part 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final TaskRepository taskRepository;
  final ProjectTagRepository projectTagRepository;
  final GeminiService _geminiService = GeminiService(); // If you use it
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TaskCubit({
    required this.taskRepository,
    required this.projectTagRepository,
  }) : super(const TaskState()) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    emit(state.copyWith(isLoading: true));
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: [], allProjects: [], allTags: [], isLoading: false));
      return;
    }
    try {
      final tasks = await taskRepository.getTasks();
      final projects = await projectTagRepository.getProjects();
      final tags = await projectTagRepository.getTags();

      emit(state.copyWith(
        tasks: tasks,
        allProjects: projects,
        allTags: tags,
        isLoading: false,
      ));
    } catch (e) {
      print("Error loading initial data for TaskCubit: $e");
      emit(state.copyWith(isLoading: false, tasks: [], allProjects: [], allTags: []));
    }
  }

  Future<void> loadTasks() async {
    await loadInitialData();
  }

  Future<void> addTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final category = await _geminiService.classifyTask(task.title ?? '');
    // Đảm bảo ID được tạo nếu chưa có (Task model đã xử lý việc này)
    final taskToAdd = task.copyWith(
      category: category,
      userId: user.uid,
      createdAt: task.createdAt ?? DateTime.now(),
      isCompleted: false,
      completionDate: null,
      isPomodoroActive: false,
      remainingPomodoroSeconds: 0,
    );
    await taskRepository.addTask(taskToAdd);
    await loadInitialData();
  }

  // Sửa: Bỏ loadInitialData() ở cuối, sẽ được gọi bởi hàm điều phối
  Future<void> updateTasksOnProjectDeletion(String projectIdToDelete) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final tasksToUpdate = List<Task>.from(state.tasks)
        .where((task) => task.projectId == projectIdToDelete && task.userId == user.uid)
        .toList();

    for (var task in tasksToUpdate) {
      await taskRepository.updateTask(task.copyWith(projectId: null));
    }
    // await loadInitialData(); // Bỏ dòng này
    print("Tasks updated for project deletion: $projectIdToDelete");
  }

  // Sửa: Bỏ loadInitialData() ở cuối, sẽ được gọi bởi hàm điều phối
  Future<void> updateTasksOnTagDeletion(String tagIdToDelete) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    final tasksToUpdate = List<Task>.from(state.tasks)
        .where((task) => task.tagIds?.contains(tagIdToDelete) == true && task.userId == user.uid)
        .toList();

    for (var task in tasksToUpdate) {
      final updatedTagIds = List<String>.from(task.tagIds!)..remove(tagIdToDelete);
      await taskRepository.updateTask(task.copyWith(tagIds: updatedTagIds.isNotEmpty ? updatedTagIds : null));
    }
    // await loadInitialData(); // Bỏ dòng này
    print("Tasks updated for tag deletion: $tagIdToDelete");
  }

  // THÊM HÀM ĐIỀU PHỐI XÓA PROJECT
  Future<void> deleteProjectAndUpdateTasks(String projectId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    emit(state.copyWith(isLoading: true));
    try {
      print('TaskCubit: Starting deletion process for project ID: $projectId');
      // Bước 1: Cập nhật các task liên quan
      await updateTasksOnProjectDeletion(projectId);

      // Bước 2: Xóa project khỏi Hive
      await projectTagRepository.deleteProjectByKey(projectId);
      print('TaskCubit: Project $projectId deleted from repository.');

      // Bước 3: Load lại toàn bộ dữ liệu để cập nhật UI
      await loadInitialData();
      print('TaskCubit: Initial data reloaded after project deletion.');
    } catch (e) {
      print("Error deleting project and updating tasks: $e");
      emit(state.copyWith(isLoading: false));
      throw Exception("Lỗi khi xóa project: ${e.toString().replaceFirst("Exception: ", "")}");
    }
  }

  // THÊM HÀM ĐIỀU PHỐI XÓA TAG
  Future<void> deleteTagAndUpdateTasks(String tagId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    emit(state.copyWith(isLoading: true));
    try {
      print('TaskCubit: Starting deletion process for tag ID: $tagId');
      // Bước 1: Cập nhật các task liên quan
      await updateTasksOnTagDeletion(tagId);

      // Bước 2: Xóa tag khỏi Hive
      await projectTagRepository.deleteTagByKey(tagId);
      print('TaskCubit: Tag $tagId deleted from repository.');

      // Bước 3: Load lại toàn bộ dữ liệu
      await loadInitialData();
      print('TaskCubit: Initial data reloaded after tag deletion.');
    } catch (e) {
      print("Error deleting tag and updating tasks: $e");
      emit(state.copyWith(isLoading: false));
      throw Exception("Lỗi khi xóa tag: ${e.toString().replaceFirst("Exception: ", "")}");
    }
  }

  Future<void> updateTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');

    if (task.userId != null && task.userId != user.uid) {
      print('Cảnh báo: Cố gắng cập nhật task không thuộc sở hữu của người dùng hiện tại. Task UserID: ${task.userId}, Current UserID: ${user.uid}');
      throw Exception('Bạn không có quyền cập nhật task này.');
    }

    Task taskToUpdate = task.copyWith(userId: user.uid);

    if (taskToUpdate.isCompleted == true) {
      taskToUpdate = taskToUpdate.copyWith(
        completionDate: taskToUpdate.completionDate ?? DateTime.now(),
        isPomodoroActive: false,
        remainingPomodoroSeconds: 0,
      );
    } else if (taskToUpdate.isCompleted == false && taskToUpdate.completionDate != null) {
      taskToUpdate = Task(
        id: taskToUpdate.id,
        title: taskToUpdate.title,
        note: taskToUpdate.note,
        dueDate: taskToUpdate.dueDate,
        priority: taskToUpdate.priority,
        projectId: taskToUpdate.projectId,
        tagIds: taskToUpdate.tagIds,
        estimatedPomodoros: taskToUpdate.estimatedPomodoros,
        completedPomodoros: taskToUpdate.completedPomodoros,
        category: taskToUpdate.category,
        isPomodoroActive: taskToUpdate.isPomodoroActive,
        remainingPomodoroSeconds: taskToUpdate.remainingPomodoroSeconds,
        isCompleted: false,
        subtasks: taskToUpdate.subtasks,
        userId: taskToUpdate.userId,
        createdAt: taskToUpdate.createdAt,
        originalCategory: taskToUpdate.originalCategory,
        completionDate: null,
      );
    }

    await taskRepository.updateTask(taskToUpdate);
    await loadInitialData();
  }

  Future<void> deleteTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (task.userId != user.uid && task.userId != null) throw Exception('Bạn không có quyền xóa task này.');

    await taskRepository.deleteTask(task);
    await loadInitialData();
  }

  Future<void> restoreTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (task.userId != user.uid && task.userId != null) throw Exception('Bạn không có quyền khôi phục task này.');

    final restoredCategory = task.originalCategory ?? 'Planned';
    await taskRepository.updateTask(
        task.copyWith(
            category: restoredCategory,
            isCompleted: false,
            completionDate: null
        )
    );
    await loadInitialData();
  }

  Future<void> searchTasks(String query) async {
    final user = _auth.currentUser;
    if (user == null) {
      emit(state.copyWith(tasks: [], isLoading: false, allProjects: state.allProjects, allTags: state.allTags));
      return;
    }

    emit(state.copyWith(isLoading: true));
    final allTasks = await taskRepository.getTasks();

    if (query.isEmpty) {
      emit(state.copyWith(tasks: allTasks, isLoading: false, allProjects: state.allProjects, allTags: state.allTags));
      return;
    }

    final filteredTasks = <Task>[];

    for (var task in allTasks) {
      final prompt = '''
      Kiểm tra xem task sau có phù hợp với query không:
      - Task title: "${task.title}"
      - Query: "$query"
      Trả về true/false.
      ''';
      try {
        final response = await _geminiService.generateContent([Content.text(prompt)]);
        if (response.text?.trim().toLowerCase() == 'true') {
          filteredTasks.add(task);
        }
      } catch (e) {
        print('Lỗi khi dùng Gemini để search task ${task.title}: $e');
      }
    }
    emit(state.copyWith(tasks: filteredTasks, isLoading: false, allProjects: state.allProjects, allTags: state.allTags));
  }

  void toggleSelectionMode() {
    emit(state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedTasks: !state.isSelectionMode ? state.selectedTasks : [],
    ));
  }

  void toggleTaskSelection(Task task) {

    final currentSelectedTasks = List<Task>.from(state.selectedTasks);
    final existingTaskIndex = currentSelectedTasks.indexWhere((t) => t.id == task.id); // Task.id giờ là String và non-null

    if (existingTaskIndex != -1) {
      // Task đã được chọn -> bỏ chọn
      currentSelectedTasks.removeAt(existingTaskIndex);
    } else {
      // Task chưa được chọn -> chọn task này
      currentSelectedTasks.add(task);
    }

    // Mặc định giữ nguyên trạng thái isSelectionMode hiện tại
    bool newIsSelectionMode = state.isSelectionMode;


    if (state.isSelectionMode && currentSelectedTasks.isEmpty) {
      newIsSelectionMode = false; // Thì TẮT chế độ chọn nhiều
    }

    emit(state.copyWith(
      selectedTasks: currentSelectedTasks,
      isSelectionMode: newIsSelectionMode, // Cập nhật lại isSelectionMode
    ));
  }

  Future<void> restoreSelectedTasks() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (state.selectedTasks.isEmpty) return;

    for (var task in state.selectedTasks) {
      if (task.userId == user.uid) {
        final restoredCategory = task.originalCategory ?? 'Planned';
        await taskRepository.updateTask(task.copyWith(
            category: restoredCategory,
            isCompleted: false,
            completionDate: null
        ));
      }
    }
    emit(state.copyWith(isSelectionMode: false, selectedTasks: []));
    await loadInitialData();
  }

  Future<void> deleteSelectedTasks() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Người dùng chưa đăng nhập');
    if (state.selectedTasks.isEmpty) return;

    for (var task in state.selectedTasks) {
      if (task.userId == user.uid) {
        await taskRepository.deleteTask(task);
      }
    }
    emit(state.copyWith(isSelectionMode: false, selectedTasks: []));
    await loadInitialData();
  }

  void sortTasks(String criteria) {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final sortedTasks = List<Task>.from(state.tasks);
    final userTasks = sortedTasks.where((task) => task.userId == user.uid).toList();
    final otherUserTasks = sortedTasks.where((task) => task.userId != user.uid).toList();


    if (criteria == 'dueDate') {
      userTasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else if (criteria == 'priority') {
      userTasks.sort((a, b) => _priorityValue(a.priority).compareTo(_priorityValue(b.priority)));
    }
    emit(state.copyWith(tasks: [...userTasks, ...otherUserTasks], allProjects: state.allProjects, allTags: state.allTags));
  }


  void sortTasksInTrash(String criteria) {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final currentTasks = List<Task>.from(state.tasks);
    final trashTasks = currentTasks.where((task) => task.category == 'Trash' && task.userId == user.uid).toList();
    final nonTrashTasks = currentTasks.where((task) => task.category != 'Trash' || task.userId != user.uid).toList();

    if (criteria == 'title') {
      trashTasks.sort((a, b) => (a.title ?? '').toLowerCase().compareTo((b.title ?? '').toLowerCase()));
    } else if (criteria == 'deletedDate') {
      // Giả sử bạn thêm trường `deletedAt` vào TaskModel khi task vào thùng rác
      // Nếu không, có thể dùng `completionDate` (nếu nó được cập nhật khi vào thùng rác)
      // hoặc `createdAt` (ít chính xác hơn)
      trashTasks.sort((a, b) {
        // final dateA = a.deletedAt ?? a.completionDate ?? DateTime(1900);
        final dateA = a.completionDate ?? DateTime(1900); // Dùng tạm completionDate
        final dateB = b.completionDate ?? DateTime(1900);
        return dateB.compareTo(dateA);
      });
    }

    final newTaskList = [...nonTrashTasks, ...trashTasks];
    emit(state.copyWith(tasks: newTaskList, allProjects: state.allProjects, allTags: state.allTags));
  }

  int _priorityValue(String? priority) {
    switch (priority) {
      case 'High': return 1;
      case 'Medium': return 2;
      case 'Low': return 3;
      default: return 4;
    }
  }

  Map<String, List<Task>> getCategorizedTasks() {
    final user = _auth.currentUser;
    final Map<String, List<Task>> categorizedTasks = {
      'Today': [], 'Tomorrow': [], 'This Week': [],
      'Planned': [], 'Completed': [], 'Trash': [],
    };
    if (user == null) return categorizedTasks;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - DateTime.monday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    for (var task in state.tasks) {
      if (task.userId != user.uid) continue;

      if (task.category == 'Trash') {
        categorizedTasks['Trash']!.add(task);
      } else if (task.isCompleted == true) {
        categorizedTasks['Completed']!.add(task);
      } else if (task.dueDate != null) {
        final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        if (dueDate.isAtSameMomentAs(today)) {
          categorizedTasks['Today']!.add(task);
        } else if (dueDate.isAtSameMomentAs(tomorrow)) {
          categorizedTasks['Tomorrow']!.add(task);
        } else if (!dueDate.isBefore(startOfWeek) && !dueDate.isAfter(endOfWeek)) {
          categorizedTasks['This Week']!.add(task);
        } else {
          categorizedTasks['Planned']!.add(task);
        }
      } else {
        categorizedTasks['Planned']!.add(task);
      }
    }
    return categorizedTasks;
  }

  Map<String, List<Task>> getTasksByProject() {
    final user = _auth.currentUser;
    final Map<String, List<Task>> tasksByProjectId = {};
    if (user == null) return tasksByProjectId;

    for (var task in state.tasks) {
      if (task.userId != user.uid) continue;
      if (task.category == 'Trash' || task.isCompleted == true) continue;

      final currentProjectId = task.projectId ?? 'no_project_id';

      if (!tasksByProjectId.containsKey(currentProjectId)) {
        tasksByProjectId[currentProjectId] = [];
      }
      tasksByProjectId[currentProjectId]!.add(task);
    }
    return tasksByProjectId;
  }

  String calculateTotalTime(List<Task> tasks) {
    final user = _auth.currentUser;
    if (user == null) return '00:00';

    int totalPomodoros = 0;
    for (var task in tasks) {
      if (task.userId != user.uid) continue;
      totalPomodoros += task.estimatedPomodoros ?? 0;
    }
    int totalMinutes = totalPomodoros * 25;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String calculateElapsedTime(List<Task> tasks) {
    final user = _auth.currentUser;
    if (user == null) return '00:00';

    int elapsedPomodoros = 0;
    for (var task in tasks) {
      if (task.userId != user.uid) continue;
      elapsedPomodoros += task.completedPomodoros ?? 0;
    }
    int totalMinutes = elapsedPomodoros * 25;
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}