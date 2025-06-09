part of 'task_cubit.dart'; // Giữ nguyên


class TaskState extends Equatable {
  final List<Task> tasks;
  final bool isLoading;
  final bool isSelectionMode;
  final List<Task> selectedTasks;
  // NEW: Thêm trường để lưu danh sách tất cả projects và tags
  final List<Project> allProjects;
  final List<Tag> allTags;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.isSelectionMode = false,
    this.selectedTasks = const [],
    this.allProjects = const [], // NEW: Giá trị mặc định
    this.allTags = const [],     // NEW: Giá trị mặc định
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? isSelectionMode,
    List<Task>? selectedTasks,
    List<Project>? allProjects, // NEW: Thêm vào copyWith
    List<Tag>? allTags,         // NEW: Thêm vào copyWith
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedTasks: selectedTasks ?? this.selectedTasks,
      allProjects: allProjects ?? this.allProjects, // NEW
      allTags: allTags ?? this.allTags,             // NEW
    );
  }

  @override
  // MODIFIED: Thêm allProjects và allTags vào props để Equatable so sánh
  List<Object?> get props => [tasks, isLoading, isSelectionMode, selectedTasks, allProjects, allTags];
}