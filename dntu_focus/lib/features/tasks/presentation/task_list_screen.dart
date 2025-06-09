import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/presentation/widgets/task_item_card.dart';
import '../domain/task_cubit.dart';
import '../data/models/project_tag_repository.dart';
import '../data/models/tag_model.dart';
import '../data/models/task_model.dart';
import 'task_detail_screen.dart';
import 'add_task/add_task_bottom_sheet.dart';
// import 'package:collection/collection.dart'; // Bỏ comment nếu dùng firstWhereOrNull

class TaskListScreen extends StatelessWidget {
  final String category;
  final String? filterId; // Sẽ là projectId nếu category == 'project'

  const TaskListScreen({
    super.key,
    required this.category,
    this.filterId,
  });

  @override
  Widget build(BuildContext context) {
    final projectTagRepository = ProjectTagRepository(
      projectBox: Hive.box<Project>('projects'),
      tagBox: Hive.box<Tag>('tags'),
    );

    // Lắng nghe TaskState để lấy dữ liệu và rebuild khi cần
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        // Lấy allProjects từ state để tra cứu tên project
        final List<Project> allProjects = state.allProjects;
        String screenTitle = category; // Tiêu đề mặc định

        List<Task> tasksToDisplay;

        if (category == 'project') {
          if (filterId != null && filterId != 'no_project_id') {
            tasksToDisplay = state.tasks
                .where((task) =>
            task.projectId == filterId &&
                task.userId == FirebaseAuth.instance.currentUser?.uid &&
                task.category != 'Trash')
                .toList();
            try {
              // final project = allProjects.firstWhereOrNull((p) => p.id == filterId); // Dùng firstWhereOrNull từ package:collection
              final project = allProjects.firstWhere((p) => p.id == filterId);
              screenTitle = project.name;
            } catch (e) {
              print('TaskListScreen: Không tìm thấy project với ID: $filterId');
              screenTitle = 'Dự án không tồn tại';
            }
          } else if (filterId == null || filterId == 'no_project_id') { // Xử lý trường hợp task không có project
            tasksToDisplay = state.tasks
                .where((task) =>
            (task.projectId == null || task.projectId == 'no_project_id') &&
                task.userId == FirebaseAuth.instance.currentUser?.uid &&
                task.category != 'Trash')
                .toList();
            screenTitle = 'Không có dự án';
          }
          else {
            // Trường hợp category là 'project' nhưng filterId là null (không nên xảy ra nếu điều hướng đúng)
            tasksToDisplay = [];
            screenTitle = 'Dự án không xác định';
          }
        } else {
          // Lọc theo category như cũ (Today, Tomorrow, This Week, Planned)
          final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
          tasksToDisplay = categorizedTasks[category] ?? [];
          // Cập nhật screenTitle cho các category thông thường
          if (category == 'Today') screenTitle = 'Hôm nay';
          else if (category == 'Tomorrow') screenTitle = 'Ngày mai';
          else if (category == 'This Week') screenTitle = 'Tuần này';
          else if (category == 'Planned') screenTitle = 'Đã lên kế hoạch';
          // Giữ nguyên `category` làm tiêu đề nếu không khớp các trường hợp trên
        }

        if (state.isLoading && tasksToDisplay.isEmpty) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 40), // Ép thêm padding phía trên
            ),
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(screenTitle, style: Theme.of(context).textTheme.titleLarge),
                centerTitle: true,
              ),
              body: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final completedTasks = tasksToDisplay.where((task) => task.isCompleted == true).toList();
        final waitingTasks = tasksToDisplay.where((task) => task.isCompleted != true).toList();

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 40), // Ép thêm padding phía trên
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(
                screenTitle, // Sử dụng screenTitle đã được xác định
                style: Theme.of(context).textTheme.titleLarge,
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        final TextEditingController controller = TextEditingController();
                        return AlertDialog(
                          title: Text(
                            'Tìm kiếm trong "$screenTitle"',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          content: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên task...',
                              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('Hủy', style: Theme.of(context).textTheme.bodyMedium),
                            ),
                            TextButton(
                              onPressed: () async {
                                // searchTasks sẽ tìm trên toàn bộ state.tasks
                                // Sau đó TaskListScreen sẽ tự động rebuild và lọc lại tasksToDisplay
                                await context.read<TaskCubit>().searchTasks(controller.text);
                                Navigator.pop(dialogContext);
                              },
                              child: Text('Tìm kiếm', style: Theme.of(context).textTheme.bodyMedium),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // sortTasks sẽ sắp xếp state.tasks, sau đó TaskListScreen tự rebuild và lọc lại
                    if (value == 'Sort by Due Date') {
                      context.read<TaskCubit>().sortTasks('dueDate');
                    } else if (value == 'Sort by Priority') {
                      context.read<TaskCubit>().sortTasks('priority');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Sort by Due Date', child: Text('Sắp xếp theo ngày đến hạn')),
                    const PopupMenuItem(value: 'Sort by Priority', child: Text('Sắp xếp theo độ ưu tiên')),
                  ],
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phần hiển thị thông tin tổng hợp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.read<TaskCubit>().calculateTotalTime(tasksToDisplay).toString(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tổng thời gian dự kiến',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.read<TaskCubit>().calculateElapsedTime(tasksToDisplay).toString(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thời gian đã hoàn thành',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                waitingTasks.length.toString(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Task đang chờ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                completedTasks.length.toString(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Task đã hoàn thành',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Nút "Thêm một task"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.8,
                          ),
                          builder: (_) => BlocProvider.value(
                            value: context.read<TaskCubit>(), // Cung cấp TaskCubit hiện tại
                            child: AddTaskBottomSheet(
                              repository: projectTagRepository,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Thêm một task.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: tasksToDisplay.isEmpty
                        ? Center(
                      child: Text(
                        'Không có task nào trong mục "$screenTitle".', // Cập nhật thông báo
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                        : ListView.builder(
                      itemCount: waitingTasks.length + (completedTasks.isNotEmpty ? 1 : 0) + completedTasks.length,
                      itemBuilder: (context, index) {
                        // TaskItemCard sẽ cần truy cập allProjects và allTags từ TaskState
                        // để hiển thị tên project/tag từ ID.
                        // Cách tốt nhất là TaskItemCard tự làm điều đó bằng context.read<TaskCubit>().state
                        if (index < waitingTasks.length) {
                          final task = waitingTasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TaskItemCard(
                              task: task,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<TaskCubit>(),
                                      child: TaskDetailScreen(task: task),
                                    ),
                                  ),
                                ).then((value) {if (value == true) context.read<TaskCubit>().loadInitialData();});
                              },
                              onCheckboxChanged: (value) {
                                if (value != null) {
                                  context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: value));
                                }
                              },
                              onPlayPressed: () { /* Logic Pomodoro */ },
                              showDetails: true,
                            ),
                          );
                        } else if (index == waitingTasks.length && completedTasks.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'Đã hoàn thành (${completedTasks.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          );
                        } else if (completedTasks.isNotEmpty) {
                          final completedIndex = index - waitingTasks.length - (completedTasks.isNotEmpty ? 1 : 0);
                          if (completedIndex < 0 || completedIndex >= completedTasks.length) {
                            return const SizedBox.shrink();
                          }
                          final task = completedTasks[completedIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TaskItemCard(
                              task: task,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<TaskCubit>(),
                                      child: TaskDetailScreen(task: task),
                                    ),
                                  ),
                                ).then((value) {if (value == true) context.read<TaskCubit>().loadInitialData();});
                              },
                              onCheckboxChanged: (value) {
                                if (value != null) {
                                  context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: value));
                                }
                              },
                              onPlayPressed: () { /* Logic Pomodoro */ },
                              showDetails: true,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'task_list_screen_fab', // Đảm bảo heroTag là duy nhất
              backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  builder: (_) => BlocProvider.value(
                    value: context.read<TaskCubit>(),
                    child: AddTaskBottomSheet(
                      repository: projectTagRepository,
                    ),
                  ),
                );
              },
              child: Icon(Icons.add, color: Theme.of(context).floatingActionButtonTheme.foregroundColor),
            ),
          ),
        );
      },
    );
  }
}